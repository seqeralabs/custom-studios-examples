#!/usr/bin/env python3
"""Drive a disposable real OpenCode Studio, retaining proof after cleanup."""
import argparse
import base64
import hashlib
import http.client
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

REPO = Path(__file__).resolve().parents[4]
WORK = "/local-data/opencode/work"
MARKER = "opencode-verification-proof"
FILE_PROMPT = (
    "Use the file write tool to create verification-proof.txt in the current "
    "project containing exactly opencode-verification-proof. Then use the file "
    "read tool to read it back. Do not run shell commands or inspect environment "
    "variables. After both tools complete, reply exactly: Verified " + MARKER
)
MCP_PROMPT = (
    "Use only the Seqera MCP search_seqera_api tool to search public API "
    "documentation for studios. Do not call call_seqera_api, access workspace "
    "data, read files, run shell commands, or inspect environment variables. "
    "Summarize the documented Studio operations in one sentence."
)


class Unreachable(RuntimeError):
    pass


class Run:
    def __init__(self, evidence):
        self.root = evidence.resolve()
        if self.root.is_relative_to(REPO):
            raise ValueError("Evidence must be outside the repository")
        self.root.mkdir(parents=True, exist_ok=True)
        self.private = self.root / ".private.json"
        self.state = json.loads(self.private.read_text()) if self.private.exists() else None

    def redact(self, value):
        text = str(value)
        if self.state:
            password = self.state["password"]
            values = [password, base64.b64encode(f"opencode:{password}".encode()).decode()]
            token_name = self.state.get("token_env")
            if token_name and os.environ.get(token_name):
                values.append(os.environ[token_name])
            for secret in values:
                text = text.replace(secret, "<redacted>")
        return text

    def save(self, name, value):
        raw = json.dumps(value, indent=2) + "\n"
        clean = self.redact(raw)
        if raw != clean:
            raise RuntimeError("Refusing to retain evidence containing a credential")
        (self.root / name).write_text(raw)

    def state_save(self):
        fd = os.open(self.private, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as output:
            json.dump(self.state, output)
        self.private.chmod(0o600)
        public = {k: v for k, v in self.state.items() if k != "password"}
        self.save("run.json", public)

    def action(self, feature, action, **details):
        row = {"feature": feature, "action": action, **details}
        raw = json.dumps(row)
        if self.redact(raw) != raw:
            raise RuntimeError("Credential appeared in action trace")
        with (self.root / "actions.jsonl").open("a") as output:
            output.write(raw + "\n")

    def docker(self, *args, env=None, check=True):
        result = subprocess.run(["docker", *args], capture_output=True, env=env)
        if check and result.returncode:
            # Never dump arguments: environment/registry values may be sensitive.
            raise RuntimeError("Docker operation failed: " + self.redact(result.stderr.decode(errors="replace"))[-800:])
        return result

    def text(self, *args, **kwargs):
        return self.docker(*args, **kwargs).stdout.decode().strip()

    def require_state(self):
        if not self.state:
            raise RuntimeError("Launch first; private run state is absent")

    def inspect_owned(self, name):
        actual = json.loads(self.text("inspect", name))[0]
        if actual["Config"]["Labels"].get("io.seqera.verify.run") != self.state["run_id"]:
            raise RuntimeError("Refusing to drive or remove a container owned by another run")
        return actual

    def request(self, path, body=None, auth=True, envelope=True, raw=False):
        self.require_state()
        headers = {}
        if auth:
            value = f"opencode:{self.state['password']}".encode()
            headers["Authorization"] = "Basic " + base64.b64encode(value).decode()
        data = None
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(self.state["url"] + path, data=data, headers=headers)
        with urllib.request.urlopen(req, timeout=30) as response:
            content = response.read()
        if raw:
            return content
        result = json.loads(content)
        return result["data"] if envelope else result

    def start(self, suffix):
        name = self.state["run_id"] + "-" + suffix
        self.state["containers"].append(name)
        self.state["container"] = name
        self.state_save()  # Record ownership before a failing launch.
        env = dict(os.environ, OPENCODE_SERVER_PASSWORD=self.state["password"])
        args = ["run", "-d", "--platform=linux/amd64", "--name", name,
                "--label", "io.seqera.verify.run=" + self.state["run_id"],
                "-p", "127.0.0.1::3000", "--stop-timeout", "60", "--mount",
                "source=" + self.state["volume"] + ",target=/local-data",
                "-e", "OPENCODE_SERVER_PASSWORD", "-e", "OPENCODE_LOCAL_STORAGE=1",
                "-e", "OPENCODE_DATA_LINK=/local-data", "-e", "OPENCODE_BACKUP_INTERVAL=5",
                "-e", "OPENCODE_MODEL=" + self.state["model"]]
        if self.state.get("token_env"):
            env["SEQERA_ACCESS_TOKEN"] = os.environ[self.state["token_env"]]
            args += ["-e", "SEQERA_ACCESS_TOKEN"]
        args += ["--entrypoint", "python3", self.state["image_id"], "/app/studio.py"]
        self.docker(*args, env=env)
        self.state["url"] = "http://" + self.text("port", name, "3000/tcp")
        self.state_save()
        deadline = time.monotonic() + 90
        while True:
            try:
                self.request("/api/info", envelope=False)
                break
            except (urllib.error.URLError, http.client.HTTPException, OSError):
                if time.monotonic() >= deadline:
                    raise RuntimeError("OpenCode did not become ready in 90 seconds")
                time.sleep(0.5)
        self.action("launch", "container ready", container=name, url=self.state["url"])
        return self.doctor()

    def launch(self, args):
        if self.state or (self.root / "cleanup.json").exists():
            raise RuntimeError("Use a new evidence directory for each run")
        if args.seqera_token_env and not os.environ.get(args.seqera_token_env):
            raise Unreachable("Token environment variable is absent: " + args.seqera_token_env)
        image = json.loads(self.text("image", "inspect", args.image))[0]
        assert image["Architecture"] == "amd64", "Build the linux/amd64 image"
        run_id = "opencode-verify-" + uuid.uuid4().hex[:12]
        version = re.search(r"ARG OPENCODE_VERSION=([^\s]+)", (REPO / ".seqera/Dockerfile").read_text()).group(1)
        self.state = {"run_id": run_id, "password": secrets.token_urlsafe(32),
                      "image_id": image["Id"], "version": version, "volume": run_id + "-data",
                      "containers": [], "sessions": {}, "model": args.model,
                      "token_env": args.seqera_token_env,
                      "source_sha256": {n: hashlib.sha256((REPO / ".seqera" / n).read_bytes()).hexdigest() for n in ["studio.py", "opencode.json"]}}
        self.state_save()
        self.text("volume", "create", "--label", "io.seqera.verify.run=" + run_id, self.state["volume"])
        return self.start("first")

    def doctor(self):
        self.require_state()
        name = self.state["container"]
        actual = self.inspect_owned(name)
        assert actual["State"]["Running"], "Owned container is not running"
        assert actual["Image"] == self.state["image_id"], "Image identity differs"
        assert any(m.get("Name") == self.state["volume"] and m["Destination"] == "/local-data" for m in actual["Mounts"])
        address = self.text("port", name, "3000/tcp")
        assert address.startswith("127.0.0.1:") and self.state["url"] == "http://" + address
        info = self.request("/api/info", envelope=False)
        assert info["version"] == self.state["version"], "OpenCode version differs"
        process = self.text("exec", name, "cat", f"/proc/{info['pid']}/comm")
        assert process == "opencode", "Actual OpenCode process is absent"
        for filename, expected in self.state["source_sha256"].items():
            data = self.docker("exec", name, "cat", "/app/" + filename).stdout
            assert hashlib.sha256(data).hexdigest() == expected, "Image source differs"
            assert hashlib.sha256((REPO / ".seqera" / filename).read_bytes()).hexdigest() == expected, "Working source changed since launch"
        report = {"container": name, "url": self.state["url"], "version": info["version"],
                  "process": process, "ownership": "verified", "image_sources": "exact"}
        self.save("doctor.json", report)
        self.action("doctor", "read-only ownership/process/API/source check passed")
        return report

    def access(self):
        self.doctor()
        page = self.request("/", auth=False, raw=True)
        assert b"<html" in page.lower()
        try:
            self.request("/api/info", auth=False, envelope=False)
        except urllib.error.HTTPError as error:
            assert error.code == 401
        else:
            raise AssertionError("Unauthenticated API was accepted")
        report = {"html": "served", "unauthenticated_api": 401, "authenticated_api": "passed", "browser": "capture separately"}
        self.action("web-access", "GET / and authenticated/unauthenticated GET /api/info", result=report)
        self.save("access.json", report)
        return report

    def export(self, identity):
        return self.request("/api/experimental/session/" + identity + "/export")

    def turn(self, feature, prompt, session_id):
        if session_id:
            identity = session_id
            self.action(feature, "observe existing production fixture", session_id=identity)
        else:
            body = {"title": "Verification " + feature, "location": {"directory": WORK}}
            identity = self.request("/api/session", body)["id"]
            self.state["sessions"][feature] = identity
            self.state["sessions"][feature + "-" + identity] = identity
            self.state_save()
            self.action(feature, "POST /api/session", body=body, session_id=identity)
            self.request("/api/session/" + identity + "/prompt", {"text": prompt})
            self.action(feature, "POST /api/session/{id}/prompt", body={"text": prompt}, session_id=identity)
        self.state["sessions"][feature] = identity
        self.state["sessions"][feature + "-" + identity] = identity
        self.state_save()
        deadline = time.monotonic() + 180
        while True:
            data = self.export(identity)
            users = [i for i, m in enumerate(data["messages"]) if m["type"] == "user" and m.get("text") == prompt]
            if not users:
                if time.monotonic() >= deadline:
                    raise AssertionError("Session does not contain the exact public fixture prompt")
                time.sleep(0.5)
                continue
            recent = data["messages"][users[-1] + 1:]
            if recent and recent[-1]["type"] == "idle":
                finals = [m for m in recent if m["type"] == "assistant" and m.get("finish") == "stop" and m.get("time", {}).get("completed")]
                if not finals:
                    raise RuntimeError("Provider turn ended without a completed assistant answer")
                self.save(feature + "-session.json", data)
                self.save(feature + "-" + identity + "-session.json", data)
                return identity, recent, finals[-1]
            if time.monotonic() >= deadline:
                raise RuntimeError("Model turn did not complete in 180 seconds")
            time.sleep(0.5)

    @staticmethod
    def tools(messages):
        return [p for m in messages if m["type"] == "assistant" for p in m.get("content", []) if p["type"] == "tool"]

    def file_turn(self, session_id):
        self.doctor()
        identity, recent, final = self.turn("file-turn", FILE_PROMPT, session_id)
        tools = self.tools(recent)
        assert {p["name"] for p in tools} == {"write", "read"}, "Expected actual native Write and Read"
        assert all(p["state"]["status"] == "completed" for p in tools)
        assert all(p["state"]["input"]["path"] == WORK + "/verification-proof.txt" for p in tools)
        assert any(MARKER in block.get("text", "") for p in tools if p["name"] == "read"
                   for block in p["state"].get("content", [])), "Native Read result lacks marker"
        answer = "".join(p["text"] for p in final["content"] if p["type"] == "text")
        assert answer == "Verified " + MARKER
        marker = self.docker("exec", self.state["container"], "cat", WORK + "/verification-proof.txt").stdout
        assert marker in (MARKER.encode(), (MARKER + "\n").encode()), "Actual tool-written file differs"
        report = {"session_id": identity, "native_tools": [p["name"] for p in tools],
                  "completed_assistant": answer, "file_sha256": hashlib.sha256(marker).hexdigest()}
        self.action("file-turn", "completed tools/assistant and exact file bytes verified", result=report)
        self.save("file-turn.json", report)
        self.save("file-turn-" + identity + ".json", report)
        return report

    def mcp(self, session_id):
        self.doctor()
        path = "/api/mcp?" + urllib.parse.urlencode({"location[directory]": WORK})
        deadline = time.monotonic() + 60
        while True:
            servers = self.request(path)
            server = next((s for s in servers if s["name"] == "seqera"), None)
            if server and server["status"]["status"] != "pending":
                break
            if time.monotonic() >= deadline:
                raise RuntimeError("Seqera registration did not settle in 60 seconds")
            time.sleep(0.5)
        self.save("mcp-status.json", servers)
        status = server["status"]["status"]
        if status != "connected":
            raise Unreachable("Attempted " + path + "; Seqera reports " + status + "; provide authorized runtime token or interactive OAuth")
        identity, recent, final = self.turn("mcp", MCP_PROMPT, session_id)
        candidates = [p for p in self.tools(recent) if p["name"] == "execute" and (
            any(call.get("tool") == "seqera.search_seqera_api" and call.get("status") == "completed"
                for call in p.get("state", {}).get("metadata", {}).get("toolCalls", []))
            or re.search(r'tools\.seqera(?:\["search_seqera_api"\]|\.search_seqera_api)',
                         p.get("state", {}).get("input", {}).get("code", "")))]
        successful = []
        for part in candidates:
            if part["state"]["status"] != "completed":
                continue
            for block in part["state"].get("content", []):
                try:
                    result = json.loads(block.get("text", ""))
                except json.JSONDecodeError:
                    continue
                if isinstance(result, dict) and result.get("total_suggestions", 0) > 0 and any(x.get("api_name") == "platform_list_studios" for x in result.get("suggestions", [])):
                    successful.append(result)
        assert successful, "No completed native MCP documentation result was observed"
        report = {"status": status, "session_id": identity, "native_public_search": "passed", "suggestions": successful[-1]["total_suggestions"]}
        self.action("seqera-mcp", "native public documentation tool result verified", result=report)
        self.save("mcp.json", report)
        self.save("mcp-" + identity + ".json", report)
        return report

    def stop(self, name):
        self.inspect_owned(name)
        self.docker("stop", "--time", "60", name)
        actual = self.inspect_owned(name)
        assert not actual["State"]["Running"] and actual["State"]["ExitCode"] == 0
        logs = self.docker("logs", name).stdout.decode(errors="replace")
        assert self.state["password"] not in logs, "Password appeared in logs"
        assert "Final OpenCode database backup saved" in logs
        (self.root / (name + ".log")).write_text(self.redact(logs))
        self.action("recovery", "owned writer stopped; final backup and exit 0 confirmed", container=name)

    def recover(self):
        self.doctor()
        if "file-turn" not in self.state["sessions"]:
            raise RuntimeError("Complete file-turn first; no manual marker fixtures")
        baseline = {sid: self.export(sid) for sid in set(self.state["sessions"].values())}
        for data in baseline.values():
            assert data["messages"][-1]["type"] == "idle", "Wait for idle before recovery"
        self.save("recovery-baseline.json", baseline)
        expected_file = self.docker("exec", self.state["container"], "cat", WORK + "/verification-proof.txt").stdout
        assert expected_file in (MARKER.encode(), (MARKER + "\n").encode())
        first = self.state["container"]
        self.stop(first)
        reader = self.state["run_id"] + "-reader"
        self.state["containers"].append(reader)
        self.state_save()
        self.docker("run", "-d", "--platform=linux/amd64", "--name", reader,
                    "--label", "io.seqera.verify.run=" + self.state["run_id"], "--mount",
                    "source=" + self.state["volume"] + ",target=/saved,readonly",
                    "--entrypoint", "python3", self.state["image_id"], "-c", "import time; time.sleep(300)")
        # Independent byte readback, not SQLite opening a Fusion/readonly volume.
        self.inspect_owned(reader)
        for source, target in [("state/opencode.db", "saved-opencode.db"), ("work/verification-proof.txt", "saved-verification-proof.txt")]:
            self.docker("cp", reader + ":/saved/opencode/" + source, str(self.root / target))
        self.docker("stop", reader)
        self.docker("rm", reader)
        import sqlite3
        with sqlite3.connect(self.root / "saved-opencode.db") as db:
            assert db.execute("PRAGMA quick_check").fetchone() == ("ok",)
            for sid, expected in baseline.items():
                rows = db.execute("SELECT id,type,data FROM session_message WHERE session_id=? ORDER BY seq", (sid,)).fetchall()
                stored = [{"id": r[0], "type": r[1], **json.loads(r[2])} for r in rows]
                assert stored == expected["messages"], "Saved database transcript differs"
        assert (self.root / "saved-verification-proof.txt").read_bytes() == expected_file
        self.docker("rm", first)
        self.start("restored")
        after = {sid: self.export(sid) for sid in baseline}
        assert all(after[sid]["messages"] == baseline[sid]["messages"] for sid in baseline)
        marker = self.docker("exec", self.state["container"], "cat", WORK + "/verification-proof.txt").stdout
        assert marker == expected_file
        self.save("recovery-after.json", after)
        report = {"independent_snapshot_integrity": "ok", "complete_transcripts": "identical",
                  "messages": sum(len(d["messages"]) for d in baseline.values()), "file": "exact",
                  "fresh_container": self.state["container"], "live_fusion": "not tested",
                  "abrupt_host_loss": "not tested"}
        self.action("recovery", "fresh-runtime transcripts and file verified", result=report)
        self.save("recovery.json", report)
        return report

    def cleanup(self):
        if not self.state:
            if (self.root / "cleanup.json").exists():
                return json.loads((self.root / "cleanup.json").read_text())
            raise RuntimeError("No owned run state; refusing guessed cleanup")
        evidence = [p.name for p in self.root.iterdir() if p.is_file() and p != self.private]
        for name in self.state["containers"]:
            found = self.docker("inspect", name, check=False)
            if found.returncode:
                continue
            actual = self.inspect_owned(name)
            if actual["State"]["Running"]:
                self.docker("stop", "--time", "60", name)
            self.docker("rm", name)
        found = self.docker("volume", "inspect", self.state["volume"], check=False)
        if found.returncode == 0:
            volume = json.loads(found.stdout)[0]
            assert volume["Labels"].get("io.seqera.verify.run") == self.state["run_id"]
            self.docker("volume", "rm", self.state["volume"])
        for name in self.state["containers"]:
            assert self.docker("inspect", name, check=False).returncode != 0
        assert self.docker("volume", "inspect", self.state["volume"], check=False).returncode != 0
        assert all((self.root / name).is_file() for name in evidence), "Cleanup lost evidence"
        self.private.unlink()
        report = {"owned_containers": "absent", "owned_volume": "absent",
                  "private_password_file": "removed", "evidence_retained": evidence}
        self.save("cleanup.json", report)
        return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path)
    sub = parser.add_subparsers(dest="command", required=True)
    launch = sub.add_parser("launch")
    launch.add_argument("--image", default="opencode-verification:local")
    launch.add_argument("--model", default="opencode/big-pickle")
    launch.add_argument("--seqera-token-env")
    for name in ["doctor", "access", "recover", "cleanup", "prompts"]:
        sub.add_parser(name)
    for name in ["file-turn", "mcp"]:
        sub.add_parser(name).add_argument("--session-id")
    args = parser.parse_args()
    if args.command == "prompts":
        print(json.dumps({"file": FILE_PROMPT, "mcp": MCP_PROMPT}, indent=2))
        return 0
    if not args.evidence:
        parser.error("--evidence is required except for prompts")
    run = Run(args.evidence)
    try:
        if args.command == "launch":
            result = run.launch(args)
        elif args.command == "file-turn":
            result = run.file_turn(args.session_id)
        elif args.command == "mcp":
            result = run.mcp(args.session_id)
        else:
            result = getattr(run, args.command)()
        print(json.dumps(result, indent=2))
        return 0
    except Exception as error:
        report = {"feature": args.command, "outcome": "verified-unreachable" if isinstance(error, Unreachable) else "failed", "reason": run.redact(str(error))}
        run.save(args.command + "-failure.json", report)
        print(json.dumps(report), file=sys.stderr)
        # A failed launch may already have created owned resources.
        if args.command == "launch" and run.state:
            run.cleanup()
        return 2 if isinstance(error, Unreachable) else 1


if __name__ == "__main__":
    sys.exit(main())
