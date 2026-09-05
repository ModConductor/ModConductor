"""Install the pinned official Flutter SDK into an absent .tools/flutter directory."""

import hashlib
import json
import platform
from pathlib import Path
import sys
import tarfile
import tempfile
import urllib.request
import zipfile

root = Path(__file__).resolve().parents[1]
target = root / ".tools"
settings = json.loads((root / ".config/flutter-sdk.json").read_text())

if platform.machine().lower() not in ("x86_64", "amd64"):
    sys.exit("The current Flutter SDK pin supports x64 Linux and Windows only.")

system = {"linux": "linux", "win32": "windows"}[sys.platform]
archive = settings[system]
if (target / "flutter").exists():
    sys.exit(".tools/flutter already exists; use it or explicitly remove it before reinstalling.")

target.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(dir=target) as temporary:
    download = Path(temporary) / "flutter-sdk"
    urllib.request.urlretrieve(archive["url"], download)
    with download.open("rb") as stream:
        actual_hash = hashlib.file_digest(stream, "sha256").hexdigest()
    if actual_hash != archive["sha256"]:
        sys.exit("Flutter SDK checksum does not match .config/flutter-sdk.json.")
    if system == "windows":
        with zipfile.ZipFile(download) as bundle:
            bundle.extractall(target)
    else:
        with tarfile.open(download) as bundle:
            bundle.extractall(target, filter="data")

print(f"Flutter {settings['version']} installed at {target / 'flutter'}")
