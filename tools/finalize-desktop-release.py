#!/usr/bin/env python3
"""Finalize the Linux and Windows assets of one desktop package run."""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    for script in ("finalize-linux-release.py", "finalize-windows-release.py", "finalize-source-release.py"):
        subprocess.run([sys.executable, str(ROOT / "tools" / script), *sys.argv[1:]], check=True)


if __name__ == "__main__":
    main()
