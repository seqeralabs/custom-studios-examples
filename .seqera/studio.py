#!/usr/bin/env python3
"""Run OpenCode with local SQLite and consistent backups on a data link.

Without a data link, everything stays on the Studio's own filesystem.
"""

import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import sqlite3
import subprocess
import sys
import tempfile
import time


# Used when OPENCODE_DATA_LINK is unset. It is on the Studio's own filesystem,
# so only Studio checkpoints keep it.
LOCAL_STORAGE = Path("/var/lib/opencode-studio/local")


def storage_root(env):
    raw = env.get("OPENCODE_DATA_LINK", "")
    local = env.get("OPENCODE_LOCAL_STORAGE") == "1"
    if not raw:
        LOCAL_STORAGE.mkdir(mode=0o700, parents=True, exist_ok=True)
        raw, local = str(LOCAL_STORAGE), True
    mount = Path(raw).resolve(strict=True)
    if not mount.is_dir():
        raise ValueError("OPENCODE_DATA_LINK must be a directory")
    if not local:
        if not mount.is_relative_to("/workspace/data"):
            raise ValueError("OPENCODE_DATA_LINK must be beneath /workspace/data")
        fs = subprocess.check_output(
            ["findmnt", "-T", str(mount), "-n", "-o", "FSTYPE"], text=True
        ).strip()
        if not fs.startswith("fuse"):
            raise ValueError("OPENCODE_DATA_LINK must be on a Fusion/FUSE mount")
    instance = env.get("OPENCODE_INSTANCE", "opencode")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}", instance):
        raise ValueError("OPENCODE_INSTANCE must be a simple directory name")
    root = mount / instance
    root.mkdir(mode=0o700, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=root) as probe:
        probe.write(b"writable")
        probe.flush()
        os.fsync(probe.fileno())
    return root


def backup_database(database, destination):
    """Use SQLite's online backup API, including commits still in the WAL."""
    if not database.exists():
        return False
    with tempfile.TemporaryDirectory(dir=database.parent) as tmp:
        snapshot = Path(tmp) / "snapshot.db"
        deadline = time.monotonic() + 15

        def progress(*_):
            if time.monotonic() > deadline:
                raise TimeoutError("SQLite backup exceeded 15 seconds")

        with sqlite3.connect(database.as_uri() + "?mode=ro", uri=True) as source:
            with sqlite3.connect(snapshot) as target:
                source.backup(target, pages=256, progress=progress, sleep=0.05)
                if target.execute("PRAGMA quick_check").fetchone() != ("ok",):
                    raise RuntimeError("SQLite backup failed its integrity check")
        destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        fd, pending = tempfile.mkstemp(prefix=".snapshot-", dir=destination.parent)
        try:
            with os.fdopen(fd, "wb") as output, snapshot.open("rb") as source:
                shutil.copyfileobj(source, output)
                output.flush()
                os.fsync(output.fileno())
            os.replace(pending, destination)
        finally:
            Path(pending).unlink(missing_ok=True)
    return True


def prepare(env, root, runtime):
    data = runtime / "data" / "opencode"
    data.mkdir(mode=0o700, parents=True, exist_ok=True)
    database = data / "opencode.db"
    snapshot = root / "state" / "opencode.db"
    if not database.exists() and snapshot.exists():
        # Read the cloud object as bytes; SQLite must open only local files.
        pending = database.with_suffix(".restore")
        try:
            shutil.copyfile(snapshot, pending)
            with sqlite3.connect(pending) as source:
                if source.execute("PRAGMA quick_check").fetchone() != ("ok",):
                    raise RuntimeError(
                        "Saved OpenCode database failed its integrity check"
                    )
            os.replace(pending, database)
        finally:
            pending.unlink(missing_ok=True)
    config = root / "config" / "opencode"
    config.mkdir(mode=0o700, parents=True, exist_ok=True)
    config_file = config / "opencode.json"
    if not config_file.exists():
        shutil.copyfile(Path(__file__).with_name("opencode.json"), config_file)
    work = root / "work"
    work.mkdir(mode=0o700, exist_ok=True)
    env.update(
        {
            "XDG_DATA_HOME": str(runtime / "data"),
            "XDG_STATE_HOME": str(runtime / "state"),
            "XDG_CACHE_HOME": str(runtime / "cache"),
            "XDG_CONFIG_HOME": str(root / "config"),
            "OPENCODE_DB": str(database),
        }
    )
    # Add launch settings without modifying the user's persisted config.
    override = json.loads(env.get("OPENCODE_CONFIG_CONTENT", "{}"))
    if env.get("SEQERA_ACCESS_TOKEN"):
        servers = override.setdefault("mcp", {}).setdefault("servers", {})
        servers["seqera"] = {
            "type": "remote",
            "url": "https://mcp.seqera.io/mcp",
            "oauth": False,
            "headers": {"Authorization": "Bearer {env:SEQERA_ACCESS_TOKEN}"},
        }
    if env.get("OPENCODE_MODEL"):
        override["model"] = env["OPENCODE_MODEL"]
    env["OPENCODE_CONFIG_CONTENT"] = json.dumps(override)
    return database, snapshot, work


def default_notices(env, root):
    """Say which defaults apply to unset inputs, and what each one costs."""
    notices = []
    # OpenCode has no mode without a login: it reads either variable, and
    # otherwise generates a password and prints it.
    if not (env.get("OPENCODE_SERVER_PASSWORD") or env.get("OPENCODE_PASSWORD")):
        notices.append(
            "OPENCODE_SERVER_PASSWORD is not set. OpenCode generates a login "
            "password for this start and prints it below as 'server password "
            "<password>'. Enter it when OpenCode asks for a password. It "
            "changes on every start, and anyone who can read these logs can "
            "read it. Set OPENCODE_SERVER_PASSWORD for a fixed password that "
            "stays out of the logs."
        )
    if not env.get("OPENCODE_DATA_LINK"):
        notices.append(
            "OPENCODE_DATA_LINK is not set. Work files, config and database "
            f"backups are kept in {root} inside this Studio. Only Studio "
            "checkpoints keep them: they return when this Studio is stopped "
            "and started, a new Studio starts empty, and nothing is written "
            "to cloud storage. Set OPENCODE_DATA_LINK to a writable data-link "
            "mount to keep them there."
        )
    return notices


def main():
    os.umask(0o077)
    env = os.environ.copy()
    port = int(env.get("CONNECT_TOOL_PORT", "3000"))
    interval = int(env.get("OPENCODE_BACKUP_INTERVAL", "60"))
    if not 1 <= port <= 65535 or interval < 5:
        raise ValueError("Use a valid port and a backup interval of at least 5 seconds")
    root = storage_root(env)
    for notice in default_notices(env, root):
        print(notice, flush=True)
    identity = hashlib.sha256(str(root).encode()).hexdigest()[:16]
    runtime = Path("/var/lib/opencode-studio") / f"{root.name}-{identity}"
    runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
    # Same-host exclusion only. A separate Studio must use a separate instance.
    with (runtime / "writer.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError(
                "Another OpenCode process is using this instance"
            ) from None
        database, snapshot, work = prepare(env, root, runtime)
        stop = False

        def request_stop(*_):
            nonlocal stop
            stop = True

        signal.signal(signal.SIGTERM, request_stop)
        signal.signal(signal.SIGINT, request_stop)
        child = subprocess.Popen(
            ["opencode", "serve", "--hostname", "0.0.0.0", "--port", str(port)],
            cwd=work,
            env=env,
            start_new_session=True,
        )
        next_backup = time.monotonic() + interval
        backup_failed = False
        try:
            while child.poll() is None and not stop:
                if time.monotonic() >= next_backup:
                    try:
                        if backup_database(database, snapshot):
                            print("OpenCode database backup saved", flush=True)
                    except Exception as error:
                        print(
                            f"OpenCode backup failed: {type(error).__name__}",
                            file=sys.stderr,
                            flush=True,
                        )
                    next_backup = time.monotonic() + interval
                time.sleep(0.2)
        finally:
            if child.poll() is None:
                os.killpg(child.pid, signal.SIGTERM)
                try:
                    child.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    os.killpg(child.pid, signal.SIGKILL)
                    child.wait()
            try:
                if backup_database(database, snapshot):
                    print("Final OpenCode database backup saved", flush=True)
            except Exception as error:
                print(
                    f"Final OpenCode backup failed: {type(error).__name__}",
                    file=sys.stderr,
                    flush=True,
                )
                backup_failed = True
        return 1 if backup_failed else (0 if stop else child.returncode)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, RuntimeError, OSError) as error:
        print(f"OpenCode Studio startup failed: {error}", file=sys.stderr)
        sys.exit(1)
