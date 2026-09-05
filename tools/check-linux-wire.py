#!/usr/bin/env python3
"""Run the Flutter-to-NativeAOT integration check on a private Linux display."""
import os
from pathlib import Path
import secrets
import shutil
import signal
import subprocess
import sys
import tempfile
import time

root = Path(__file__).resolve().parents[1]
if sys.platform != 'linux':
    raise SystemExit('This check needs native Linux; it does not qualify Windows.')
for tool in ('Xvfb', 'xauth'):
    if shutil.which(tool) is None:
        raise SystemExit(f'Missing preinstalled tool: {tool}. No installer is run.')
engine = root / '.tools/publish/linux-x64/ModConductor.Engine'
if not engine.is_file():
    raise SystemExit('Publish the Linux NativeAOT engine first.')
(root / '.agent-workspace').mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='wire-display-', dir=root / '.agent-workspace') as temporary:
    temporary = Path(temporary)
    display = next(n for n in range(97, 200) if not Path(f'/tmp/.X11-unix/X{n}').exists() and not Path(f'/tmp/.X{n}-lock').exists())
    auth = temporary / 'auth'
    auth.touch(mode=0o600)
    subprocess.run(['xauth', '-f', str(auth)], input=f'add :{display} . {secrets.token_hex(16)}\n', text=True, check=True)
    env = dict(os.environ, DISPLAY=f':{display}', XAUTHORITY=str(auth), GDK_BACKEND='x11', LIBGL_ALWAYS_SOFTWARE='true', FLUTTER_SUPPRESS_ANALYTICS='true', DART_SUPPRESS_ANALYTICS='true')
    env.pop('WAYLAND_DISPLAY', None)
    for variable, directory in [('HOME', 'home'), ('XDG_CONFIG_HOME', 'config'), ('XDG_CACHE_HOME', 'cache'), ('XDG_DATA_HOME', 'data')]:
        (temporary / directory).mkdir()
        env[variable] = str(temporary / directory)
    with (temporary / 'xvfb.log').open('w') as log:
        server = subprocess.Popen(['Xvfb', f':{display}', '-screen', '0', '1440x900x24', '-nolisten', 'tcp', '-auth', str(auth)], stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.monotonic() + 5
            while not Path(f'/tmp/.X11-unix/X{display}').exists():
                if server.poll() is not None or time.monotonic() >= deadline:
                    raise SystemExit('Private Xvfb did not start.')
                time.sleep(.05)
            command = [str(root / '.tools/flutter/bin/flutter'), 'test', 'integration_test/native_wire_test.dart', '-d', 'linux', '--no-pub', '--dart-define=MC_ENGINE_PATH=' + str(engine), '--reporter', 'expanded']
            check = subprocess.Popen(command, cwd=root / 'ui/apps/mod_conductor', env=env, start_new_session=True)
            try:
                code = check.wait(timeout=180)
            except subprocess.TimeoutExpired:
                os.killpg(check.pid, signal.SIGTERM)
                try:
                    check.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(check.pid, signal.SIGKILL)
                    check.wait()
                raise SystemExit('Native wire check exceeded 180 seconds.')
            if code != 0:
                raise SystemExit(code)
        finally:
            server.terminate()
            try:
                server.wait(timeout=3)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()
