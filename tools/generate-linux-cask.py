#!/usr/bin/env python3
"""Write the Linux Homebrew cask for one completed AppImage."""

import argparse
import hashlib
from pathlib import Path


def sha256(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--appimage", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--base-url", default="https://github.com/alsi-lawr/ModConductor/releases/download")
    args = parser.parse_args()
    expected = f"modconductor-{args.version}-linux-x64.AppImage"
    if args.appimage.name != expected:
        parser.error(f"Expected {expected} AppImage filename.")
    url = f"{args.base_url.rstrip('/')}/v{args.version}/{expected}"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        'cask "modconductor" do\n'
        f'  version "{args.version}"\n'
        f'  sha256 "{sha256(args.appimage)}"\n\n'
        f'  url "{url}"\n'
        '  name "Mod Conductor"\n'
        '  desc "Desktop mod organiser"\n'
        '  homepage "https://github.com/alsi-lawr/ModConductor"\n\n'
        '  depends_on :linux\n\n'
        f'  app_image "{expected}"\n'
        'end\n'
    )


if __name__ == "__main__":
    main()
