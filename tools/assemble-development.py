#!/usr/bin/env python3
"""Add the published engine and pinned LOOT helper to a local Flutter bundle."""
from pathlib import Path
import os
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
platform = {'linux': 'linux', 'win32': 'windows'}[sys.platform]
rid = 'linux-x64' if platform == 'linux' else 'win-x64'
name = 'ModConductor.Engine' + ('.exe' if platform == 'windows' else '')
published = root / '.tools/publish' / rid / name
bundle = root / 'ui/apps/mod_conductor/build' / platform / 'x64' / ('release/bundle' if platform == 'linux' else 'runner/Release')
if not published.is_file() or not bundle.is_dir():
    raise SystemExit('Publish the engine and build the Flutter bundle first.')
(bundle / 'engine').mkdir(exist_ok=True)
native_sqlite = 'e_sqlite3.dll' if platform == 'windows' else 'libe_sqlite3.so'
sqlite = published.parent / native_sqlite
if not sqlite.is_file():
    raise SystemExit('The published engine is missing its SQLite native library.')
assets = published.parent / 'ModConductor.Engine.staticwebassets.endpoints.json'
if not assets.is_file():
    raise SystemExit('The published engine is missing its static web assets.')
target = root / '.tools/loot-helper-target'
environment = dict(os.environ, CARGO_TARGET_DIR=str(target))
command = ['cargo', '+1.89.0', 'build', '--locked', '--release']
if platform == 'windows':
    command.extend(['--target', 'x86_64-pc-windows-msvc'])
subprocess.run(command, cwd=root / 'native/ModConductor.Loot.Helper', env=environment, check=True)
helper = target / ('x86_64-pc-windows-msvc/release' if platform == 'windows' else 'release') / ('modconductor-loot-helper.exe' if platform == 'windows' else 'modconductor-loot-helper')
if not helper.is_file():
    raise SystemExit('The pinned LOOT helper build did not produce an executable.')
shutil.copy2(published, bundle / 'engine' / name)
shutil.copy2(sqlite, bundle / 'engine' / native_sqlite)
shutil.copy2(assets, bundle / 'engine' / assets.name)
shutil.copy2(helper, bundle / 'engine' / helper.name)
print(bundle / 'engine' / name)
