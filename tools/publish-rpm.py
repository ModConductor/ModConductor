#!/usr/bin/env python3
"""Build the Fedora RPM with rpmbuild inside a small Fedora tool image."""

import argparse
import os
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
IMAGE = "modconductor-rpm-package:local"


def inside_root(path: Path) -> str:
    try:
        return "/src/" + path.resolve().relative_to(ROOT).as_posix()
    except ValueError as error:
        raise SystemExit(f"Path must be in the checkout: {path}") from error


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    context = ROOT / "tools/rpm-package"
    subprocess.run(["docker", "build", "-t", IMAGE, "-f", str(context / "Dockerfile"), str(context)], check=True)
    subprocess.run([
        "docker", "run", "--rm", "--init", "--user", f"{os.getuid()}:{os.getgid()}",
        "-v", f"{ROOT}:/src", "-w", "/src", "-e", "HOME=/src/.agent-workspace",
        IMAGE, "python3", "tools/package-rpm.py", "--archive", inside_root(args.archive),
        "--output", inside_root(args.output), "--version", args.version,
    ], check=True)


if __name__ == "__main__":
    main()
