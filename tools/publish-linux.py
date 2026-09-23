#!/usr/bin/env python3
"""Run the shared package hook in an Ubuntu FHS build container."""

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
IMAGE = "modconductor-linux-package:local"


def inside_root(path: Path) -> str:
    try:
        return "/src/" + path.resolve().relative_to(ROOT).as_posix()
    except ValueError as error:
        raise SystemExit(f"Path must be in the checkout: {path}") from error


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rid", required=True)
    parser.add_argument("--publish-directory", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--flutter-sdk", type=Path, help="Existing pinned Flutter SDK inside this checkout")
    args = parser.parse_args()
    if args.rid != "linux-x64" or sys.platform != "linux":
        parser.error("The FHS builder supports Linux x64 only.")
    if args.publish_directory.exists():
        parser.error(f"Package output must be a new directory: {args.publish_directory}")
    flutter = args.flutter_sdk or ROOT / ".tools/flutter"
    if not flutter.exists() and args.flutter_sdk is None:
        subprocess.run([sys.executable, str(ROOT / "tools/bootstrap-flutter.py")], cwd=ROOT, check=True)
    if not (flutter / "bin/flutter").is_file():
        parser.error(f"Flutter SDK is missing: {flutter}")
    flutter_bin = inside_root(flutter / "bin")
    output = inside_root(args.publish_directory)
    subprocess.run(["docker", "build", "-t", IMAGE, "-f", str(ROOT / "tools/linux-package/Dockerfile"), str(ROOT / "tools/linux-package")], check=True)
    scratch = ROOT / ".agent-workspace"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="package-linux-", dir=scratch) as temporary:
        work = Path(temporary)
        (work / "home").mkdir()
        environment = {
            "HOME": inside_root(work / "home"),
            "DOTNET_CLI_HOME": inside_root(work / "home"),
            "NUGET_PACKAGES": "/src/.tools/dotnet-cli/.nuget/packages",
            "PUB_CACHE": "/src/.tools/pub-cache",
            "CARGO_HOME": inside_root(work / "cargo-home"),
            "PATH": f"{flutter_bin}:/opt/dotnet:/opt/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        }
        command = ["docker", "run", "--rm", "--init", "--user", f"{os.getuid()}:{os.getgid()}", "-v", f"{ROOT}:/src", "-w", "/src"]
        for key, value in environment.items():
            command.extend(["-e", f"{key}={value}"])
        command.extend([
            IMAGE, "python3", "tools/package-linux.py", "--rid", args.rid,
            "--publish-directory", output, "--version", args.version,
            "--revision", args.revision, "--work-directory", inside_root(work / "build"),
        ])
        subprocess.run(command, check=True)


if __name__ == "__main__":
    main()
