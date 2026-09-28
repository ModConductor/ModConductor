#!/usr/bin/env python3
"""Prepare a hosted RID payload for the desktop smoke check."""

import argparse
from pathlib import Path
import subprocess
import sys


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rid", required=True)
    parser.add_argument("--publish-directory", type=Path, required=True)
    args = parser.parse_args()
    if not args.publish_directory.is_dir():
        parser.error(f"Published payload is missing: {args.publish_directory}")
    if args.rid == "win-x64" and sys.platform == "win32":
        return
    if args.rid != "linux-x64" or sys.platform != "linux":
        parser.error("The desktop smoke preparation supports native Linux and Windows x64 only.")

    subprocess.run(["sudo", "apt-get", "update"], check=True)
    subprocess.run([
        "sudo", "apt-get", "install", "-y", "--no-install-recommends",
        "libegl1", "libgles2", "libgtk-3-0t64", "libepoxy0", "libsecret-1-0",
        "libicu74", "libunwind8", "libssl3t64", "zlib1g", "libglib2.0-bin",
        "fontconfig", "fonts-dejavu-core", "gsettings-desktop-schemas",
        "xdg-utils", "shared-mime-info", "xvfb", "xauth", "xdotool",
    ], check=True)


if __name__ == "__main__":
    main()
