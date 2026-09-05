#!/usr/bin/env python3
"""Copy the already published engine into the already built native Flutter bundle."""
from pathlib import Path
import shutil
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
shutil.copy2(published, bundle / 'engine' / name)
shutil.copy2(sqlite, bundle / 'engine' / native_sqlite)
print(bundle / 'engine' / name)
