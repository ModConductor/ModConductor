#!/usr/bin/env python3
"""Run the selected platform's complete desktop package smoke."""

from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    script = "smoke-windows-package.py" if sys.platform == "win32" else "smoke-linux-package.py"
    subprocess.run([sys.executable, str(ROOT / "tools" / script), *sys.argv[1:]], check=True)


if __name__ == "__main__":
    main()
