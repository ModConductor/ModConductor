#!/usr/bin/env python3
"""Build one complete, unsigned Windows x64 desktop package payload."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "ui/apps/mod_conductor"
NSIS_URL = "https://downloads.sourceforge.net/project/nsis/NSIS%203/3.12/nsis-3.12.zip"
NSIS_SHA256 = "56581f90db321581c5381193d796fffcf2d24b2f8fed2160a6c6a3baa67f2c4f"


def command_output(command: list[str], *, cwd: Path = ROOT) -> str:
    return subprocess.check_output(command, cwd=cwd, text=True).strip()


def pinned_nsis() -> Path:
    executable = ROOT / ".tools/nsis/nsis-3.12/makensis.exe"
    if executable.is_file():
        return executable
    archive = ROOT / ".tools/nsis-3.12.zip"
    archive.parent.mkdir(exist_ok=True)
    if not archive.is_file():
        urllib.request.urlretrieve(NSIS_URL, archive)
    with archive.open("rb") as stream:
        actual = hashlib.file_digest(stream, "sha256").hexdigest()
    if actual != NSIS_SHA256:
        raise SystemExit(f"NSIS archive checksum mismatch: {actual}")
    destination = ROOT / ".tools/nsis"
    destination.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        bundle.extractall(destination)
    return executable


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rid", required=True)
    parser.add_argument("--publish-directory", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--flutter-sdk", type=Path)
    parser.add_argument("--makensis", type=Path)
    parser.add_argument("--source-date-epoch", type=int, help="Required for a scoped source bundle without Git metadata")
    args = parser.parse_args()
    if args.rid != "win-x64" or sys.platform != "win32" or platform.machine().lower() not in ("amd64", "x86_64"):
        parser.error("The Windows package builder supports native Windows x64 only.")
    if args.publish_directory.exists():
        parser.error(f"Package output must be a new directory: {args.publish_directory}")
    if command_output(["dotnet", "--version"]) != "10.0.400":
        parser.error(".NET SDK 10.0.400 is required.")
    rust = subprocess.run(["rustc", "+1.89.0", "--version"], capture_output=True, text=True)
    if rust.returncode != 0:
        subprocess.run(["rustup", "toolchain", "install", "1.89.0", "--profile", "minimal"], check=True)
        rust = subprocess.run(["rustc", "+1.89.0", "--version"], capture_output=True, text=True, check=True)
    if not rust.stdout.startswith("rustc 1.89.0 "):
        parser.error("Rust 1.89.0 is required.")
    flutter = args.flutter_sdk or ROOT / ".tools/flutter"
    if not flutter.exists() and args.flutter_sdk is None:
        subprocess.run([sys.executable, str(ROOT / "tools/bootstrap-flutter.py")], cwd=ROOT, check=True)
    flutter_command = flutter / "bin/flutter.bat"
    if not flutter_command.is_file():
        parser.error(f"Flutter SDK is missing: {flutter}")
    # A newly unpacked SDK prints tool bootstrap progress before machine output.
    subprocess.run([str(flutter_command), "--version"], cwd=ROOT, check=True)
    flutter_details, _ = json.JSONDecoder().raw_decode(command_output([str(flutter_command), "--version", "--machine"]))
    if flutter_details["frameworkVersion"] != "3.47.4" or flutter_details["dartSdkVersion"].split()[0] != "3.13.3":
        parser.error("Flutter 3.47.4 and Dart 3.13.3 are required.")
    nsis = args.makensis or pinned_nsis()
    if command_output([str(nsis), "/VERSION"]).lstrip("v") != "3.12":
        parser.error("NSIS 3.12 is required.")
    if (ROOT / ".git").exists():
        if command_output(["git", "rev-parse", "HEAD"]) != args.revision:
            parser.error("The requested revision is not the checked-out source revision.")
        source_date_epoch = command_output(["git", "log", "-1", "--format=%ct"])
    elif args.source_date_epoch is not None:
        source_date_epoch = str(args.source_date_epoch)
    else:
        parser.error("A scoped source bundle requires --source-date-epoch.")

    scratch = ROOT / ".agent-workspace"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="windows-package-build-", dir=scratch) as temporary:
        work = Path(temporary)
        engine = work / "engine"
        environment = dict(os.environ, CARGO_TARGET_DIR=str(work / "cargo-target"))
        subprocess.run(["dotnet", "restore", "src/ModConductor.Engine/ModConductor.Engine.fsproj", "--locked-mode"], cwd=ROOT, env=environment, check=True)
        subprocess.run([
            "dotnet", "publish", "src/ModConductor.Engine/ModConductor.Engine.fsproj", "-c", "Release", "-r", "win-x64", "--self-contained", "true", "--no-restore",
            "-p:ModConductorLocalPublishVerificationOnly=true", "-o", str(engine),
        ], cwd=ROOT, env=environment, check=True)
        subprocess.run([str(flutter_command), "clean"], cwd=APP, env=environment, check=True)
        subprocess.run([str(flutter_command), "pub", "get", "--enforce-lockfile"], cwd=APP, env=environment, check=True)
        subprocess.run([str(flutter_command), "build", "windows", "--release", "--no-pub"], cwd=APP, env=environment, check=True)
        subprocess.run(["cargo", "+1.89.0", "build", "--locked", "--release", "--target", "x86_64-pc-windows-msvc"], cwd=ROOT / "native/ModConductor.Loot.Helper", env=environment, check=True)
        helper = work / "cargo-target/x86_64-pc-windows-msvc/release/modconductor-loot-helper.exe"
        subprocess.run([
            sys.executable, str(ROOT / "tools/package-windows.py"),
            "--flutter-bundle", str(APP / "build/windows/x64/runner/Release"),
            "--engine-publish", str(engine), "--loot-helper", str(helper),
            "--makensis", str(nsis), "--version", args.version,
            "--source-revision", args.revision, "--source-date-epoch", source_date_epoch,
            "--output", str(args.publish_directory),
        ], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
