"""Guard the KasmVNC autostart contract.

LinuxServer's ``init-kasmvnc-config`` copies ``/defaults/autostart`` to the
hardcoded path ``/config/.config/openbox/autostart``, while ``openbox-autostart``
reads ``${XDG_CONFIG_HOME:-$HOME/.config}/openbox/autostart``. Overriding HOME in
the image points openbox at a file that is never written, so the desktop starts
with no application and the Studio never leaves its loading page.
"""

import re
import unittest
from pathlib import Path

DOCKERFILE = Path(__file__).parents[1] / ".seqera" / "Dockerfile"
LAUNCHER = "/usr/local/bin/start-napari"


class AutostartContractTest(unittest.TestCase):
    def setUp(self):
        self.dockerfile = DOCKERFILE.read_text()

    def test_image_does_not_override_home(self):
        overrides = re.findall(r"^\s*ENV\s+HOME=.*$", self.dockerfile, re.MULTILINE)
        self.assertEqual(overrides, [], "HOME must stay /config from the base image")

    def test_autostart_runs_the_napari_launcher(self):
        self.assertIn(f'echo "{LAUNCHER}" > /defaults/autostart', self.dockerfile)
        self.assertIn(f"COPY start-napari {LAUNCHER}", self.dockerfile)


if __name__ == "__main__":
    unittest.main()
