#!/usr/bin/env python3
"""Verify a real image's web/API, MCP config and fresh-container recovery."""

import base64
import http.client
import json
import os
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

image = sys.argv[1] if len(sys.argv) > 1 else "opencode-studio"
identity = "opencode-smoke-" + uuid.uuid4().hex[:12]
volume = identity + "-data"
password = secrets.token_urlsafe(32)
environment = {**os.environ, "OPENCODE_SERVER_PASSWORD": password}
authorization = "Basic " + base64.b64encode(f"opencode:{password}".encode()).decode()
work = "/local-data/opencode/work"
containers = []


def docker(*args):
    return subprocess.check_output(
        ["docker", *args], text=True, env=environment
    ).strip()


def start(suffix):
    name = identity + suffix
    docker(
        "run",
        "-d",
        "--platform=linux/amd64",
        "--name",
        name,
        "-p",
        "127.0.0.1::3000",
        "--stop-timeout",
        "60",
        "--mount",
        f"source={volume},target=/local-data",
        "-e",
        "OPENCODE_SERVER_PASSWORD",
        "-e",
        "OPENCODE_LOCAL_STORAGE=1",
        "-e",
        "OPENCODE_DATA_LINK=/local-data",
        "-e",
        "OPENCODE_BACKUP_INTERVAL=5",
        "--entrypoint",
        "python3",
        image,
        "/app/studio.py",
    )
    containers.append(name)
    address = docker("port", name, "3000/tcp")
    base = "http://" + address
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        try:
            request(base, "/api/info")
            return name, base
        except (urllib.error.URLError, http.client.HTTPException, OSError):
            time.sleep(0.5)
    raise RuntimeError("OpenCode API did not start within 90 seconds")


def request(base, path, body=None, auth=True, decode=True):
    headers = {"Authorization": authorization} if auth else {}
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(base + path, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=45) as response:
        raw = response.read()
        return json.loads(raw) if decode else raw


try:
    docker("volume", "create", volume)
    first, base = start("-first")
    try:
        request(base, "/api/info", auth=False)
        raise AssertionError("Unauthenticated API access was accepted")
    except urllib.error.HTTPError as error:
        assert error.code == 401, error.code
    page = request(base, "/", auth=False, decode=False)
    assert b"<html" in page.lower(), "Web UI HTML was not served"
    created = request(
        base,
        "/api/session",
        {"title": "OpenCode restart proof", "location": {"directory": work}},
    )
    session_id = created["data"]["id"]
    query = urllib.parse.urlencode({"location[directory]": work})
    mcp = request(base, "/api/mcp?" + query)
    seqera = next(
        (server for server in mcp["data"] if server["name"] == "seqera"), None
    )
    deadline = time.monotonic() + 50
    while (
        seqera is None or seqera["status"]["status"] == "pending"
    ) and time.monotonic() < deadline:
        time.sleep(0.5)
        mcp = request(base, "/api/mcp?" + query)
        seqera = next(
            (server for server in mcp["data"] if server["name"] == "seqera"), None
        )
    assert seqera is not None, "Seqera MCP was not registered within 50 seconds"
    status = seqera["status"]["status"]
    assert status in ("needs_auth", "connected"), seqera["status"]
    docker(
        "exec",
        first,
        "python3",
        "-c",
        "from pathlib import Path; Path('/local-data/opencode/work/demo.txt').write_text('hello from OpenCode')",
    )
    docker("stop", first)
    logs = docker("logs", first)
    assert password not in logs, "Web password appeared in container logs"
    assert "Final OpenCode database backup saved" in logs, (
        "No final backup was confirmed"
    )
    assert docker("inspect", "--format", "{{.State.ExitCode}}", first) == "0"
    docker("rm", first)
    containers.remove(first)
    second, restored_base = start("-restored")
    restored = request(restored_base, "/api/session/" + session_id)
    assert restored["data"]["title"] == "OpenCode restart proof"
    marker = docker("exec", second, "cat", work + "/demo.txt")
    assert marker == "hello from OpenCode"
    report = {
        "web_html": "passed",
        "api_auth": "passed",
        "password_logs": "absent",
        "seqera_mcp_status": status,
        "session_restored": True,
        "work_file_restored": True,
        "real_model_turn": "not run",
        "live_fusion": "not tested",
    }
    print(json.dumps(report, indent=2))
except Exception:
    for name in containers:
        logs = subprocess.run(["docker", "logs", name], capture_output=True, text=True)
        safe = (logs.stdout + logs.stderr).replace(password, "<test-password>")
        safe = safe.replace(authorization, "<test-authorization>")
        safe = "\n".join(
            line for line in safe.splitlines() if "server password" not in line
        )
        print(safe[-2000:], file=sys.stderr)
    raise
finally:
    for name in containers:
        subprocess.run(["docker", "stop", name], capture_output=True, check=False)
        subprocess.run(["docker", "rm", "-f", name], capture_output=True, check=False)
    subprocess.run(["docker", "volume", "rm", volume], capture_output=True, check=False)
