#!/usr/bin/env python3
"""Build native packages from the assembled Linux archive."""

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-directory", type=Path, required=True)
    parser.add_argument("--metadata-directory", type=Path, required=True)
    args = parser.parse_args()
    archive = args.release_directory / f"modconductor-v{args.version}-linux-x64.tar.gz"
    if not archive.is_file():
        parser.error(f"Linux archive is missing: {archive}")
    package = args.release_directory / f"ModConductor_{args.version}-1_amd64.deb"
    subprocess.run([
        sys.executable, str(ROOT / "tools/package-deb.py"),
        "--archive", str(archive), "--output", str(package), "--version", args.version,
    ], check=True)
    rpm = args.release_directory / f"modconductor-{args.version}-1.fc44.x86_64.rpm"
    subprocess.run([
        sys.executable, str(ROOT / "tools/publish-rpm.py"),
        "--archive", str(archive), "--output", str(rpm), "--version", args.version,
    ], check=True)
    appimage = args.release_directory / f"modconductor-{args.version}-linux-x64.AppImage"
    subprocess.run([
        sys.executable, str(ROOT / "tools/package-appimage.py"),
        "--archive", str(archive), "--output", str(appimage), "--version", args.version,
    ], check=True)
    cask = args.release_directory / "modconductor.rb"
    subprocess.run([
        sys.executable, str(ROOT / "tools/generate-linux-cask.py"),
        "--appimage", str(appimage), "--output", str(cask), "--version", args.version,
    ], check=True)
    checksum_file = args.release_directory / "checksums_sha256.txt"
    checksum_file.write_text(checksum_file.read_text().rstrip("\n") +
                             f"\n{sha256(package)}  {package.name}\n{sha256(rpm)}  {rpm.name}\n"
                             f"{sha256(appimage)}  {appimage.name}\n{sha256(cask)}  {cask.name}\n")
    args.metadata_directory.mkdir(parents=True, exist_ok=True)
    (args.metadata_directory / "modconductor-linux-x64.json").write_text(json.dumps({
        "version": args.version, "archive": archive.name, "archive_sha256": sha256(archive),
        "deb": package.name, "deb_sha256": sha256(package),
        "rpm": rpm.name, "rpm_sha256": sha256(rpm),
        "appimage": appimage.name, "appimage_sha256": sha256(appimage),
        "linux_homebrew_cask": cask.name,
        "signature": "unsigned-local-verification-only",
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
