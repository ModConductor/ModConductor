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
shutil.copy2(published, bundle / 'engine' / name)
print(bundle / 'engine' / name)
