import importlib.util
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location(
    "studio", Path(__file__).parents[1] / "studio.py"
)
studio = importlib.util.module_from_spec(spec)
spec.loader.exec_module(studio)


class StudioTests(unittest.TestCase):
    def test_backup_includes_committed_wal_and_restores_in_new_runtime(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "persistent"
            root.mkdir()
            env = {}
            db, snapshot, work = studio.prepare(env, root, Path(tmp) / "first-runtime")
            with sqlite3.connect(db) as writer:
                writer.execute("PRAGMA journal_mode=WAL")
                writer.execute("CREATE TABLE session (id TEXT PRIMARY KEY, title TEXT)")
                writer.execute(
                    "INSERT INTO session VALUES ('session-proof', 'persisted')"
                )
                writer.commit()
                self.assertTrue(Path(str(db) + "-wal").exists())
                studio.backup_database(db, snapshot)
            (work / "demo.txt").write_text("hello from OpenCode")
            restored, _, restored_work = studio.prepare(
                {}, root, Path(tmp) / "second-runtime"
            )
            with sqlite3.connect(restored) as reader:
                self.assertEqual(
                    reader.execute("SELECT * FROM session").fetchall(),
                    [("session-proof", "persisted")],
                )
                self.assertEqual(
                    reader.execute("PRAGMA quick_check").fetchone(), ("ok",)
                )
            self.assertEqual(
                (restored_work / "demo.txt").read_text(), "hello from OpenCode"
            )

    def test_backup_failure_preserves_previous_snapshot(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = Path(tmp) / "corrupt.db"
            db.write_bytes(b"not sqlite")
            snapshot = Path(tmp) / "saved.db"
            snapshot.write_bytes(b"previous backup")
            with self.assertRaises(sqlite3.DatabaseError):
                studio.backup_database(db, snapshot)
            self.assertEqual(snapshot.read_bytes(), b"previous backup")

    def test_preserves_user_config_and_never_writes_launch_token(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "persistent"
            root.mkdir()
            runtime = Path(tmp) / "runtime"
            studio.prepare({}, root, runtime)
            config = root / "config/opencode/opencode.json"
            config.write_text(
                '{"model":"user/model","mcp":{"servers":{"other":{"type":"remote","url":"https://example.com/mcp"}}}}'
            )
            original = config.read_text()
            env = {
                "SEQERA_ACCESS_TOKEN": "test-secret",
                "OPENCODE_MODEL": "launch/model",
            }
            studio.prepare(env, root, runtime)
            override = json.loads(env["OPENCODE_CONFIG_CONTENT"])
            self.assertEqual(override["model"], "launch/model")
            self.assertFalse(override["mcp"]["servers"]["seqera"]["oauth"])
            self.assertEqual(
                override["mcp"]["servers"]["seqera"]["headers"]["Authorization"],
                "Bearer {env:SEQERA_ACCESS_TOKEN}",
            )
            self.assertNotIn("test-secret", env["OPENCODE_CONFIG_CONTENT"])
            self.assertEqual(config.read_text(), original)

    def test_rejects_invalid_data_link_and_unsafe_instance(self):
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaises(FileNotFoundError):
                studio.storage_root({"OPENCODE_DATA_LINK": tmp + "/missing"})
            with self.assertRaises(ValueError):
                studio.storage_root({"OPENCODE_DATA_LINK": tmp})
            with self.assertRaises(ValueError):
                studio.storage_root(
                    {
                        "OPENCODE_DATA_LINK": tmp,
                        "OPENCODE_LOCAL_STORAGE": "1",
                        "OPENCODE_INSTANCE": "../escape",
                    }
                )

    def test_unset_data_link_uses_storage_inside_the_studio(self):
        with tempfile.TemporaryDirectory() as tmp:
            local = Path(tmp).resolve() / "local"
            with mock.patch.object(studio, "LOCAL_STORAGE", local):
                for env in ({}, {"OPENCODE_DATA_LINK": ""}):
                    self.assertEqual(studio.storage_root(env), local / "opencode")
                self.assertTrue((local / "opencode").is_dir())
                with self.assertRaises(ValueError):
                    studio.storage_root({"OPENCODE_INSTANCE": "../escape"})

    def test_notices_explain_each_default_only_when_its_input_is_unset(self):
        root = Path("/somewhere/opencode")
        password, storage = studio.default_notices({}, root)
        self.assertIn("OPENCODE_SERVER_PASSWORD is not set", password)
        self.assertIn("server password", password)
        self.assertIn("OPENCODE_DATA_LINK is not set", storage)
        self.assertIn(str(root), storage)
        self.assertIn("checkpoints", storage)
        configured = {
            "OPENCODE_SERVER_PASSWORD": "secret",
            "OPENCODE_DATA_LINK": "/workspace/data/agent-state",
        }
        self.assertEqual(studio.default_notices(configured, root), [])

    def test_existing_local_database_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "persistent"
            root.mkdir()
            runtime = Path(tmp) / "runtime"
            db, snapshot, _ = studio.prepare({}, root, runtime)
            with sqlite3.connect(db) as writer:
                writer.execute("CREATE TABLE proof (value INTEGER)")
                writer.execute("INSERT INTO proof VALUES (1)")
            studio.backup_database(db, snapshot)
            with sqlite3.connect(db) as writer:
                writer.execute("UPDATE proof SET value=2")
            studio.prepare({}, root, runtime)
            with sqlite3.connect(db) as reader:
                self.assertEqual(
                    reader.execute("SELECT value FROM proof").fetchone(), (2,)
                )


if __name__ == "__main__":
    unittest.main()
