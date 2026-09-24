#!/usr/bin/env python3
"""Launch a packaged Windows desktop privately and close its window."""

import argparse
import ctypes
import os
from pathlib import Path
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
USER32 = ctypes.windll.user32
KERNEL32 = ctypes.windll.kernel32
USER32.GetWindowThreadProcessId.argtypes = (ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong))
USER32.IsWindowVisible.argtypes = (ctypes.c_void_p,)
USER32.PostMessageW.argtypes = (ctypes.c_void_p, ctypes.c_uint, ctypes.c_void_p, ctypes.c_void_p)
KERNEL32.OpenProcess.argtypes = (ctypes.c_ulong, ctypes.c_bool, ctypes.c_ulong)
KERNEL32.OpenProcess.restype = ctypes.c_void_p
KERNEL32.GetExitCodeProcess.argtypes = (ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong))
KERNEL32.CloseHandle.argtypes = (ctypes.c_void_p,)


def engine_pid(parent: int) -> int | None:
    command = (
        "Get-CimInstance Win32_Process -Filter 'ParentProcessId = " + str(parent) + "' | "
        "Where-Object Name -eq 'ModConductor.Engine.exe' | Select-Object -ExpandProperty ProcessId"
    )
    result = subprocess.run(["powershell", "-NoProfile", "-Command", command], capture_output=True, text=True, check=True)
    ids = result.stdout.split()
    return int(ids[0]) if ids else None


def window_of(process: int) -> int | None:
    found = []
    callback_type = ctypes.WINFUNCTYPE(ctypes.c_bool, ctypes.c_void_p, ctypes.c_void_p)

    def visit(window, _):
        owner = ctypes.c_ulong()
        USER32.GetWindowThreadProcessId(window, ctypes.byref(owner))
        if owner.value == process and USER32.IsWindowVisible(window):
            found.append(window)
        return True

    callback = callback_type(visit)
    USER32.EnumWindows(callback, 0)
    return found[0] if found else None


def process_alive(pid: int) -> bool:
    handle = KERNEL32.OpenProcess(0x1000, False, pid)
    if not handle:
        return False
    try:
        exit_code = ctypes.c_ulong()
        return bool(KERNEL32.GetExitCodeProcess(handle, ctypes.byref(exit_code))) and exit_code.value == 259
    finally:
        KERNEL32.CloseHandle(handle)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("executable", type=Path)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    executable = args.executable.resolve()
    if executable.name != "mod_conductor.exe" or not (executable.parent / "engine/ModConductor.Engine.exe").is_file():
        parser.error("Expected a complete Windows desktop payload.")
    scratch = ROOT / ".agent-workspace"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="windows-package-smoke-", dir=scratch) as temporary:
        home = Path(temporary)
        local = home / "AppData" / "Local"
        roaming = home / "AppData" / "Roaming"
        local.mkdir()
        roaming.mkdir()
        environment = dict(os.environ, USERPROFILE=str(home), LOCALAPPDATA=str(local), APPDATA=str(roaming))
        frontend = subprocess.Popen([str(executable)], env=environment, cwd=executable.parent)
        backend = None
        try:
            deadline = time.monotonic() + 45
            while time.monotonic() < deadline:
                if frontend.poll() is not None:
                    raise RuntimeError(f"Windows desktop exited before engine startup: {frontend.returncode}")
                backend = engine_pid(frontend.pid)
                window = window_of(frontend.pid)
                if backend and window and any(local.rglob("state.db")):
                    USER32.PostMessageW(window, 0x0010, 0, 0)
                    frontend.wait(timeout=20)
                    if frontend.returncode != 0:
                        raise RuntimeError(f"Windows desktop did not close normally: {frontend.returncode}")
                    deadline = time.monotonic() + 10
                    while process_alive(backend) and time.monotonic() < deadline:
                        time.sleep(0.1)
                    if process_alive(backend):
                        raise RuntimeError("Windows engine remained after the desktop closed.")
                    print("Windows desktop and NativeAOT engine started; closing the window stopped both.")
                    return
                time.sleep(0.25)
            raise RuntimeError("Windows desktop did not start its bundled engine and private state.")
        finally:
            if frontend.poll() is None:
                frontend.kill()
                frontend.wait()
            if backend is not None:
                deadline = time.monotonic() + 10
                while process_alive(backend) and time.monotonic() < deadline:
                    time.sleep(0.1)


if __name__ == "__main__":
    main()
