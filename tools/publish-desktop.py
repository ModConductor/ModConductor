#!/usr/bin/env python3
"""Run the existing platform desktop package builder for the selected RID."""

import argparse
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rid", choices=("linux-x64", "win-x64"), required=True)
    parser.add_argument("--publish-directory", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    args = parser.parse_args()
    script = ROOT / "tools" / ("publish-linux.py" if args.rid == "linux-x64" else "publish-windows.py")
    subprocess.run([sys.executable, str(script), "--rid", args.rid, "--publish-directory", str(args.publish_directory),
                    "--version", args.version, "--revision", args.revision], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
