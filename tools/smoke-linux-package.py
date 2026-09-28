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


def supported_linux_provenance(provenance: dict) -> bool:
    return provenance.get("linux_rid", provenance.get("nix_system")) in ("linux-x64", "x86_64-linux")


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


def descendant_named(parent: int, name: str) -> int | None:
    pending = [parent]
    while pending:
        pid = pending.pop()
        try:
            if Path(f"/proc/{pid}/exe").resolve().name == name:
                return pid
            pending.extend(int(child) for child in Path(f"/proc/{pid}/task/{pid}/children").read_text().split())
        except (FileNotFoundError, PermissionError, ProcessLookupError):
            continue
    return None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--scratch-directory", type=Path, default=ROOT / ".agent-workspace")
    parser.add_argument("--screenshot", type=Path, help="Save the private desktop display for local review")
    parser.add_argument("--close-window", action="store_true", help="Close the private window and check that the engine exits")
    parser.add_argument("--appimage", action="store_true", help="Smoke an installed Linux AppImage instead of an extracted payload")
    args = parser.parse_args()
    launcher = args.executable.resolve()
    engine = None
    if args.appimage:
        if not launcher.is_file() or launcher.name != f"modconductor-{args.version}-linux-x64.AppImage":
            parser.error("Expected an installed Linux AppImage.")
    else:
        payload = launcher.parent.parent
        engine = payload / "app/modconductor/engine/ModConductor.Engine"
        metadata = payload / "share/doc/modconductor/provenance.json"
        if launcher != payload / "bin/modconductor" or not engine.is_file() or not metadata.is_file():
            parser.error("Expected an extracted Linux desktop payload.")
        sbom = json.loads((payload / "share/doc/modconductor/sbom.spdx.json").read_text())
        if not supported_linux_provenance(json.loads(metadata.read_text())) or sbom["packages"][0]["versionInfo"] != args.version:
            parser.error("The Linux payload version does not match the requested version.")

    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    scratch = args.scratch_directory.resolve()
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="package-smoke-", dir=scratch) as temporary:
        directory = Path(temporary)
        for name in ("home", "config", "cache", "data", "runtime", "tmp"):
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
            "TMPDIR": str(directory / "tmp"),
        })
        if args.appimage:
            environment["APPIMAGE_EXTRACT_AND_RUN"] = "1"
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
                    backend = descendant_named(frontend.pid, "ModConductor.Engine") if args.appimage else child_engine(frontend, engine)
                    if backend and any((directory / "data").rglob("state.db")):
                        time.sleep(2)
                        running_backend = descendant_named(frontend.pid, "ModConductor.Engine") if args.appimage else child_engine(frontend, engine)
                        if frontend.poll() is None and running_backend:
                            if args.screenshot:
                                args.screenshot.parent.mkdir(parents=True, exist_ok=True)
                                subprocess.run(["import", "-window", "root", str(args.screenshot)], env=environment, check=True)
                            if args.close_window:
                                desktop_pid = descendant_named(frontend.pid, "mod_conductor") if args.appimage else frontend.pid
                                if desktop_pid is None:
                                    raise RuntimeError("AppImage desktop process was not found.")
                                windows = subprocess.check_output(["xdotool", "search", "--onlyvisible", "--pid", str(desktop_pid)], env=environment, text=True).split()
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
                            package_kind = "AppImage" if args.appimage else "Extracted desktop"
                            print(f"{package_kind} and NativeAOT engine started on a private display.")
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
