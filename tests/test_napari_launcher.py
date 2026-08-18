import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


LAUNCHER = Path(__file__).parents[1] / ".seqera" / "napari-launcher.py"


def load_launcher():
    if not LAUNCHER.exists():
        raise AssertionError("Napari splash launcher is missing")
    spec = importlib.util.spec_from_file_location("napari_launcher", LAUNCHER)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class StartupStateTest(unittest.TestCase):
    def test_waits_until_viewer_reports_ready(self):
        launcher = load_launcher()
        child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(10)"])
        try:
            with tempfile.TemporaryDirectory() as directory:
                ready = Path(directory) / "ready"
                self.assertEqual(launcher.startup_state(ready, child), "waiting")
                ready.touch()
                self.assertEqual(launcher.startup_state(ready, child), "ready")
        finally:
            child.terminate()
            child.wait()

    def test_reports_child_failure_before_viewer_is_ready(self):
        launcher = load_launcher()
        child = subprocess.Popen([sys.executable, "-c", "raise SystemExit(7)"])
        child.wait()
        with tempfile.TemporaryDirectory() as directory:
            ready = Path(directory) / "ready"
            self.assertEqual(launcher.startup_state(ready, child), "failed")


if __name__ == "__main__":
    unittest.main()
