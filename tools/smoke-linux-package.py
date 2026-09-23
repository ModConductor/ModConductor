#!/usr/bin/env python3
"""Start an extracted Linux desktop payload on a private display."""

import argparse
import json
import os
from pathlib import Path
import resource
import signal
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]


def child_engine(frontend: subprocess.Popen, engine: Path) -> int | None:
    children = Path(f"/proc/{frontend.pid}/task/{frontend.pid}/children")
    if not children.is_file():
        return None
    for pid in children.read_text().split():
        try:
            if Path(f"/proc/{pid}/exe").resolve() == engine:
                return int(pid)
        except (FileNotFoundError, PermissionError):
            continue
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--scratch-directory", type=Path, default=ROOT / ".agent-workspace")
    parser.add_argument("--screenshot", type=Path, help="Save the private desktop display for local review")
    parser.add_argument("--close-window", action="store_true", help="Close the private window and check that the engine exits")
    args = parser.parse_args()
    launcher = args.executable.resolve()
    payload = launcher.parent.parent
    engine = payload / "app/modconductor/engine/ModConductor.Engine"
    metadata = payload / "share/doc/modconductor/provenance.json"
    if launcher != payload / "bin/modconductor" or not engine.is_file() or not metadata.is_file():
        parser.error("Expected an extracted Linux desktop payload.")
    sbom = json.loads((payload / "share/doc/modconductor/sbom.spdx.json").read_text())
    if json.loads(metadata.read_text())["linux_rid"] != "linux-x64" or sbom["packages"][0]["versionInfo"] != args.version:
        parser.error("The Linux payload version does not match the requested version.")

    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    scratch = args.scratch_directory.resolve()
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="package-smoke-", dir=scratch) as temporary:
        directory = Path(temporary)
        for name in ("home", "config", "cache", "data", "runtime"):
            (directory / name).mkdir()
        (directory / "runtime").chmod(0o700)
        display = next(number for number in range(140, 200) if not Path(f"/tmp/.X11-unix/X{number}").exists() and not Path(f"/tmp/.X{number}-lock").exists())
        environment = dict(os.environ)
        environment.pop("WAYLAND_DISPLAY", None)
        environment.update({
            "DISPLAY": f":{display}", "GDK_BACKEND": "x11", "LIBGL_ALWAYS_SOFTWARE": "true",
            "GSETTINGS_BACKEND": "memory", "GTK_USE_PORTAL": "0",
            "DBUS_SESSION_BUS_ADDRESS": "unix:path=" + str(directory / "no-session-bus"),
            "HOME": str(directory / "home"), "XDG_CONFIG_HOME": str(directory / "config"),
            "XDG_CACHE_HOME": str(directory / "cache"), "XDG_DATA_HOME": str(directory / "data"),
            "XDG_RUNTIME_DIR": str(directory / "runtime"),
        })
        with (directory / "xvfb.log").open("w") as display_log, (directory / "application.log").open("w") as application_log:
            server = subprocess.Popen(["Xvfb", f":{display}", "-screen", "0", "1280x800x24", "-nolisten", "tcp"], stdout=display_log, stderr=subprocess.STDOUT)
            frontend = None
            try:
                deadline = time.monotonic() + 10
                while not Path(f"/tmp/.X11-unix/X{display}").exists():
                    if server.poll() is not None or time.monotonic() >= deadline:
                        raise RuntimeError("Private Xvfb did not start.")
                    time.sleep(0.05)
                frontend = subprocess.Popen([str(launcher)], env=environment, stdout=application_log, stderr=subprocess.STDOUT, start_new_session=True)
                deadline = time.monotonic() + 30
                while time.monotonic() < deadline:
                    if frontend.poll() is not None:
                        raise RuntimeError(f"Desktop exited before engine startup: {frontend.returncode}")
                    backend = child_engine(frontend, engine)
                    if backend and any(directory.rglob("state.db")):
                        time.sleep(2)
                        if frontend.poll() is None and child_engine(frontend, engine):
                            if args.screenshot:
                                args.screenshot.parent.mkdir(parents=True, exist_ok=True)
                                subprocess.run(["import", "-window", "root", str(args.screenshot)], env=environment, check=True)
                            if args.close_window:
                                windows = subprocess.check_output(["xdotool", "search", "--onlyvisible", "--pid", str(frontend.pid)], env=environment, text=True).split()
                                if len(windows) != 1:
                                    raise RuntimeError(f"Expected one private application window, found {len(windows)}.")
                                subprocess.run(["xdotool", "windowclose", windows[0]], env=environment, check=True)
                                frontend.wait(timeout=15)
                                if frontend.returncode != 0:
                                    raise RuntimeError(f"Desktop did not close normally: {frontend.returncode}")
                                deadline = time.monotonic() + 10
                                while Path(f"/proc/{backend}").exists() and time.monotonic() < deadline:
                                    time.sleep(0.1)
                                if Path(f"/proc/{backend}").exists():
                                    raise RuntimeError("Bundled engine remained after the desktop closed.")
                                print("Closing the private window stopped the desktop and engine.")
                            print("Extracted desktop and NativeAOT engine started on a private display.")
                            return
                    time.sleep(0.1)
                raise RuntimeError("Desktop did not start its bundled NativeAOT engine.")
            except Exception:
                application_log.flush()
                print((directory / "application.log").read_text()[-4000:], file=sys.stderr)
                raise
            finally:
                if frontend is not None:
                    try:
                        os.killpg(frontend.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                    try:
                        frontend.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        os.killpg(frontend.pid, signal.SIGKILL)
                        frontend.wait()
                server.terminate()
                server.wait(timeout=10)


if __name__ == "__main__":
    main()
