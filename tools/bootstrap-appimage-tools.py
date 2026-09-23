#!/usr/bin/env python3
"""Fetch the pinned AppImage packaging tools into the checkout tool cache."""

import argparse
import hashlib
from pathlib import Path
import urllib.request


ROOT = Path(__file__).resolve().parents[1]
TOOLS = {
    "appimagetool-x86_64.AppImage": (
        "https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage",
        "ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0",
    ),
    "linuxdeploy-x86_64.AppImage": (
        "https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20251107-1/linuxdeploy-x86_64.AppImage",
        "c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d",
    ),
    "linuxdeploy-plugin-gtk.sh": (
        "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/7a3fbc31a9e5075073ff8790f26effbac5f84453/linuxdeploy-plugin-gtk.sh",
        "b0f4cbc684a0103a9651f0955b635eaea0096b3a66c0f5a2c2aa337960375171",
    ),
    "runtime-x86_64": (
        "https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64",
        "2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d",
    ),
}


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=ROOT / ".tools/appimage-tools")
    args = parser.parse_args()
    directory = args.directory.resolve()
    directory.mkdir(parents=True, exist_ok=True)
    for name, (url, expected) in TOOLS.items():
        path = directory / name
        if not path.exists():
            temporary = directory / (name + ".download")
            with urllib.request.urlopen(url, timeout=60) as response, temporary.open("wb") as output:
                while block := response.read(1024 * 1024):
                    output.write(block)
            if digest(temporary) != expected:
                temporary.unlink()
                raise SystemExit(f"Downloaded AppImage tool does not match its pinned checksum: {name}")
            temporary.replace(path)
        if digest(path) != expected:
            raise SystemExit(f"Cached AppImage tool does not match its pinned checksum: {name}")
        if name != "runtime-x86_64":
            path.chmod(0o755)
    plugin = directory / "linuxdeploy-plugin-gtk"
    if not plugin.exists():
        plugin.symlink_to("linuxdeploy-plugin-gtk.sh")
    print(f"Pinned AppImage packaging tools: {directory}")


if __name__ == "__main__":
    main()
