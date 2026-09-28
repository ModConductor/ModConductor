#!/usr/bin/env python3
"""Run the Flutter-to-NativeAOT integration check on a private Linux display."""
import argparse
import json
import os
from pathlib import Path
import resource
import secrets
import shutil
import signal
import subprocess
import sys
import tempfile
import time

def handle_picker(request: Path, window: str, fixture: Path, env: dict[str, str], output: Path | None) -> None:
    def key(*parts):
        subprocess.run(['xdotool', *parts], env=env, check=True)
    value = json.loads(request.read_text())
    subprocess.run(['xdotool', 'windowmove', window, '20', '20', 'windowsize', window, '1000', '760'], env=env, check=True)
    if output and shutil.which('import'):
        subprocess.run(['import', '-window', 'root', str(fixture / (request.stem + '.png'))], env=env, check=True)
    key('windowfocus', '--sync', window)
    time.sleep(.3)
    if value['cancel']:
        key('key', 'Escape')
    else:
        key('key', 'alt+Home')
        time.sleep(.5)
        key('key', 'ctrl+l')
        time.sleep(.3)
        key('type', '--clearmodifiers', '--delay', '1', value['path'])
        key('key', 'Return')
        time.sleep(.5)
        still_open = subprocess.run(['xdotool', 'search', '--onlyvisible', '--name', '^Choose Directory$'], env=env, capture_output=True)
        if still_open.returncode == 0:
            key('key', 'Return')
    close_deadline = time.monotonic() + 10
    while subprocess.run(['xdotool', 'search', '--onlyvisible', '--name', '^Choose Directory$'], env=env, capture_output=True).returncode == 0:
        if time.monotonic() >= close_deadline:
            if output and shutil.which('import'):
                subprocess.run(['import', '-window', 'root', str(fixture / (request.stem + '-after.png'))], env=env, check=True)
            raise RuntimeError('The private directory dialog did not close.')
        time.sleep(.1)
    request.with_suffix('.done').touch()

parser = argparse.ArgumentParser()
journey = parser.add_mutually_exclusive_group()
journey.add_argument('--workspaces', action='store_true')
journey.add_argument('--collections', action='store_true')
journey.add_argument('--profile-mods', action='store_true')
journey.add_argument('--organization', action='store_true')
parser.add_argument('--output', type=Path)
args = parser.parse_args()
if args.output:
    args.output.mkdir(parents=True, exist_ok=True)
root = Path(__file__).resolve().parents[1]
resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
if sys.platform != 'linux':
    raise SystemExit('This check needs native Linux; it does not qualify Windows.')
for tool in ('Xvfb', 'xauth', *(['xdotool'] if args.workspaces else [])):
    if shutil.which(tool) is None:
        raise SystemExit(f'Missing preinstalled tool: {tool}. No installer is run.')
engine = Path(os.environ.get('MC_ENGINE_PATH', root / '.tools/publish/linux-x64/ModConductor.Engine')).resolve()
if not engine.is_file():
    raise SystemExit('Publish the Linux NativeAOT engine first.')
fixture_tool = Path(os.environ.get('MC_NATIVE_FIXTURE', root / '.tools/publish/native-fixtures/ModConductor.Native.Fixtures')).resolve()
if (args.workspaces or args.collections) and not fixture_tool.is_file():
    raise SystemExit('Publish the Linux NativeAOT fixture first.')
(root / '.agent-workspace').mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix='wire-display-', dir=root / '.agent-workspace') as temporary:
    temporary = Path(temporary)
    display = next(n for n in range(97, 200) if not Path(f'/tmp/.X11-unix/X{n}').exists() and not Path(f'/tmp/.X{n}-lock').exists())
    auth = temporary / 'auth'
    auth.touch(mode=0o600)
    subprocess.run(['xauth', '-f', str(auth)], input=f'add :{display} . {secrets.token_hex(16)}\n', text=True, check=True)
    env = dict(os.environ, DISPLAY=f':{display}', XAUTHORITY=str(auth), GDK_BACKEND='x11', LIBGL_ALWAYS_SOFTWARE='true', FLUTTER_SUPPRESS_ANALYTICS='true', DART_SUPPRESS_ANALYTICS='true')
    env.pop('WAYLAND_DISPLAY', None)
    env.update(GTK_USE_PORTAL='0', DBUS_SESSION_BUS_ADDRESS='unix:path=' + str(temporary / 'no-session-bus'), GSETTINGS_BACKEND='memory')
    (temporary / 'runtime').mkdir(mode=0o700)
    env['XDG_RUNTIME_DIR'] = str(temporary / 'runtime')
    fixture = temporary / 'fixture'
    fixture.mkdir()
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
            command = [str(root / '.tools/flutter/bin/flutter'), 'test', 'integration_test/organization_native_test.dart' if args.organization else 'integration_test/workspaces_native_test.dart' if args.workspaces else 'integration_test/profile_mods_native_test.dart' if args.profile_mods else 'integration_test/collections_native_test.dart' if args.collections else 'integration_test/native_wire_test.dart', '-d', 'linux', '--no-pub', '--dart-define=MC_ENGINE_PATH=' + str(engine), '--reporter', 'expanded', *(['--verbose'] if os.environ.get('MC_VERBOSE_NATIVE') == '1' else [])]
            if args.collections or args.profile_mods or args.organization:
                command.append('--dart-define=MC_COLLECTION_OUTPUT=' + str(fixture))
            if args.workspaces:
                command.append('--dart-define=MC_UI_FIXTURE=' + str(fixture))
            if args.workspaces or args.collections:
                command.append('--dart-define=MC_NATIVE_FIXTURE=' + str(fixture_tool))
            check = subprocess.Popen(command, cwd=root / 'ui/apps/mod_conductor', env=env, start_new_session=True)
            try:
                deadline = time.monotonic() + 240
                handled = set()
                while check.poll() is None:
                    if time.monotonic() >= deadline:
                        raise subprocess.TimeoutExpired(command, 240)
                    for request in fixture.glob('picker-*.json'):
                        if request.name in handled:
                            continue
                        found = subprocess.run(['xdotool', 'search', '--onlyvisible', '--name', '^Choose Directory$'], env=env, text=True, capture_output=True)
                        if found.returncode != 0:
                            continue
                        windows = found.stdout.split()
                        if len(windows) != 1:
                            raise RuntimeError('Expected one private directory dialog.')
                        handle_picker(request, windows[0], fixture, env, args.output)
                        handled.add(request.name)
                    time.sleep(.1)
                code = check.returncode
            except subprocess.TimeoutExpired:
                os.killpg(check.pid, signal.SIGTERM)
                try:
                    check.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(check.pid, signal.SIGKILL)
                    check.wait()
                raise SystemExit('Native UI check exceeded 240 seconds.')
            if code != 0:
                raise SystemExit(code)
        finally:
            if 'check' in locals() and check.poll() is None:
                os.killpg(check.pid, signal.SIGTERM)
                check.wait(timeout=10)
            if args.output:
                for item in fixture.iterdir():
                    if item.is_file():
                        shutil.copy2(item, args.output / item.name)
                shutil.copy2(temporary / 'xvfb.log', args.output / 'xvfb.log')
            server.terminate()
            try:
                server.wait(timeout=3)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()
