#!/opt/conda/envs/napari/bin/python
import signal
import subprocess
import sys
import tempfile
from pathlib import Path


def startup_state(ready_file, child):
    if ready_file.exists():
        return "ready"
    if child.poll() is not None:
        return "failed"
    return "waiting"


def run_viewer(ready_file):
    import napari
    from qtpy.QtWidgets import QApplication

    viewer = napari.Viewer()
    viewer.window._qt_window.show()
    QApplication.processEvents()
    ready_file.touch()
    napari.run()


def run_splash():
    from PyQt6.QtCore import Qt, QTimer
    from PyQt6.QtWidgets import (
        QApplication,
        QLabel,
        QProgressBar,
        QPushButton,
        QVBoxLayout,
        QWidget,
    )

    app = QApplication(sys.argv)
    splash = QWidget()
    splash.setWindowTitle("Starting napari")
    splash.setWindowFlags(
        Qt.WindowType.FramelessWindowHint | Qt.WindowType.WindowStaysOnTopHint
    )
    splash.setStyleSheet("background: #17191f; color: #f5f7fa;")

    title = QLabel("napari")
    title.setAlignment(Qt.AlignmentFlag.AlignCenter)
    title.setStyleSheet("font-size: 42px; font-weight: 600; color: #ffffff;")

    status = QLabel("Loading viewer and plugins…")
    status.setAlignment(Qt.AlignmentFlag.AlignCenter)
    status.setStyleSheet("font-size: 18px; color: #c5cad3;")

    detail = QLabel("First startup can take a minute.")
    detail.setAlignment(Qt.AlignmentFlag.AlignCenter)
    detail.setStyleSheet("font-size: 14px; color: #858c99;")

    progress = QProgressBar()
    progress.setRange(0, 0)
    progress.setTextVisible(False)
    progress.setFixedSize(360, 8)
    progress.setStyleSheet(
        "QProgressBar { background: #30343d; border: 0; border-radius: 4px; }"
        "QProgressBar::chunk { background: #00c6ff; border-radius: 4px; }"
    )

    close_button = QPushButton("Close")
    close_button.setFixedWidth(120)
    close_button.setStyleSheet(
        "QPushButton { background: #30343d; border: 0; border-radius: 4px;"
        " padding: 10px; color: #ffffff; }"
    )
    close_button.hide()
    close_button.clicked.connect(app.quit)

    layout = QVBoxLayout(splash)
    layout.addStretch()
    layout.addWidget(title)
    layout.addSpacing(20)
    layout.addWidget(status)
    layout.addWidget(detail)
    layout.addSpacing(24)
    layout.addWidget(progress, alignment=Qt.AlignmentFlag.AlignCenter)
    layout.addWidget(close_button, alignment=Qt.AlignmentFlag.AlignCenter)
    layout.addStretch()

    with tempfile.TemporaryDirectory(prefix="napari-startup-") as directory:
        ready_file = Path(directory) / "ready"
        child = subprocess.Popen(
            [sys.executable, str(Path(__file__).resolve()), "--viewer", str(ready_file)]
        )

        def stop(*_args):
            if child.poll() is None:
                child.terminate()
            app.quit()

        signal.signal(signal.SIGINT, stop)
        signal.signal(signal.SIGTERM, stop)

        timer = QTimer()

        def check_startup():
            state = startup_state(ready_file, child)
            if state == "ready":
                splash.hide()
                app.quit()
            elif state == "failed":
                timer.stop()
                status.setText("napari failed to start")
                detail.setText(f"Exit code {child.returncode}. Check Studio logs.")
                progress.hide()
                close_button.show()

        timer.timeout.connect(check_startup)
        timer.start(100)
        splash.setGeometry(app.primaryScreen().geometry())
        splash.show()
        app.exec()

        if child.poll() is None:
            return child.wait()
        return child.returncode


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--viewer":
        run_viewer(Path(sys.argv[2]))
        raise SystemExit(0)
    raise SystemExit(run_splash())
