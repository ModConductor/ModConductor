#!/usr/bin/env python3
"""Add the Windows installer and local package-manager recipes to release assets."""

import argparse
import hashlib
import io
import json
from pathlib import Path
import shutil
import tarfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]
PACKAGE_ID = "alsi-lawr.ModConductor"
BASE_URL = "https://github.com/alsi-lawr/ModConductor/releases/download"


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-directory", type=Path, required=True)
    parser.add_argument("--metadata-directory", type=Path, required=True)
    args = parser.parse_args()
    release = args.release_directory
    archive = release / f"modconductor-v{args.version}-win-x64.zip"
    if not archive.is_file():
        parser.error(f"Windows archive is missing: {archive}")
    source_installer = Path("artifacts/publish/win-x64") / f"ModConductor-{args.version}-win-x64-setup.exe"
    installer = release / source_installer.name
    if not installer.is_file():
        if not source_installer.is_file():
            parser.error(f"Windows installer is missing: {source_installer}")
        shutil.copy2(source_installer, installer)

    with zipfile.ZipFile(archive) as bundle:
        matches = [name for name in bundle.namelist() if name.endswith("/mod_conductor.exe") or name == "mod_conductor.exe"]
        if len(matches) != 1:
            parser.error("Windows archive must contain one desktop executable.")
        executable = matches[0]
    archive_url = f"{BASE_URL}/v{args.version}/{archive.name}"
    installer_url = f"{BASE_URL}/v{args.version}/{installer.name}"
    scoop = args.metadata_directory / "scoop/modconductor.json"
    scoop.parent.mkdir(parents=True, exist_ok=True)
    scoop.write_text(json.dumps({
        "version": args.version,
        "description": "Desktop mod organiser",
        "homepage": "https://github.com/alsi-lawr/ModConductor",
        "architecture": {"64bit": {"url": archive_url, "hash": sha256(archive)}},
        "bin": [[executable.replace("/", "\\"), "modconductor"]],
        "shortcuts": [[executable.replace("/", "\\"), "Mod Conductor"]],
    }, indent=2) + "\n")

    chocolatey = args.metadata_directory / "chocolatey"
    (chocolatey / "tools").mkdir(parents=True, exist_ok=True)
    (chocolatey / "modconductor.nuspec").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">\n'
        '  <metadata>\n'
        '    <id>modconductor</id>\n'
        f'    <version>{args.version}</version>\n'
        '    <authors>Mod Conductor contributors</authors>\n'
        '    <projectUrl>https://github.com/alsi-lawr/ModConductor</projectUrl>\n'
        '    <description>Desktop mod organiser</description>\n'
        '  </metadata>\n'
        '  <files><file src="tools\\**" target="tools" /></files>\n'
        '</package>\n'
    )
    (chocolatey / "tools/chocolateyInstall.ps1").write_text(
        "$ErrorActionPreference = 'Stop'\n"
        "$tools = Split-Path -Parent $MyInvocation.MyCommand.Definition\n"
        f"Install-ChocolateyZipPackage -PackageName 'modconductor' -Url '{archive_url}' "
        f"-UnzipLocation $tools -Checksum '{sha256(archive)}' -ChecksumType 'sha256'\n"
        f"$engine = Join-Path $tools '{archive.stem}\\engine'\n"
        "New-Item -ItemType File -Path (Join-Path $engine 'ModConductor.Engine.exe.ignore') -Force | Out-Null\n"
        "New-Item -ItemType File -Path (Join-Path $engine 'modconductor-loot-helper.exe.ignore') -Force | Out-Null\n"
    )

    winget = args.metadata_directory / "manifests/a/alsi-lawr/ModConductor" / args.version
    winget.mkdir(parents=True, exist_ok=True)
    (winget / f"{PACKAGE_ID}.yaml").write_text(
        "# yaml-language-server: $schema=https://aka.ms/winget-manifest.version.1.9.0.schema.json\n\n"
        f"PackageIdentifier: {PACKAGE_ID}\nPackageVersion: {args.version}\n"
        "DefaultLocale: en-US\nManifestType: version\nManifestVersion: 1.9.0\n"
    )
    (winget / f"{PACKAGE_ID}.installer.yaml").write_text(
        "# yaml-language-server: $schema=https://aka.ms/winget-manifest.installer.1.9.0.schema.json\n\n"
        f"PackageIdentifier: {PACKAGE_ID}\nPackageVersion: {args.version}\n"
        "InstallerType: nullsoft\nScope: user\nInstallModes:\n  - interactive\n  - silent\n"
        "InstallerSwitches:\n  Silent: /S\n  SilentWithProgress: /S\n"
        "UpgradeBehavior: install\nProductCode: ModConductor\n"
        "AppsAndFeaturesEntries:\n  - ProductCode: ModConductor\n"
        "Installers:\n  - Architecture: x64\n"
        f"    InstallerUrl: {installer_url}\n    InstallerSha256: {sha256(installer).upper()}\n"
        "ManifestType: installer\nManifestVersion: 1.9.0\n"
    )
    (winget / f"{PACKAGE_ID}.locale.en-US.yaml").write_text(
        "# yaml-language-server: $schema=https://aka.ms/winget-manifest.defaultLocale.1.9.0.schema.json\n\n"
        f"PackageIdentifier: {PACKAGE_ID}\nPackageVersion: {args.version}\n"
        "PackageLocale: en-US\nPublisher: Mod Conductor contributors\n"
        "PackageName: Mod Conductor\nLicense: GPL-3.0-or-later\n"
        "ShortDescription: Desktop mod organiser\n"
        "PackageUrl: https://github.com/alsi-lawr/ModConductor\n"
        "ManifestType: defaultLocale\nManifestVersion: 1.9.0\n"
    )
    source = Path("artifacts/publish/win-x64")
    sidecars = []
    for name in ("payload-sha256.json", "sbom.spdx.json", "provenance.json"):
        original = source / name
        if not original.is_file():
            parser.error(f"Windows package metadata is missing: {original}")
        destination = release / f"modconductor-v{args.version}-win-x64-{name}"
        shutil.copy2(original, destination)
        sidecars.append(destination)
    manifests = source / "dependency-manifests"
    if not manifests.is_dir():
        parser.error(f"Windows dependency manifests are missing: {manifests}")
    manifest_files = sorted(path for path in manifests.rglob("*") if path.is_file())
    if not manifest_files:
        parser.error(f"Windows dependency manifests are empty: {manifests}")
    manifest_archive = release / f"modconductor-v{args.version}-win-x64-dependency-manifests.tar"
    with tarfile.open(manifest_archive, "w") as bundle:
        for path in manifest_files:
            contents = path.read_bytes()
            entry = tarfile.TarInfo(f"dependency-manifests/{path.relative_to(manifests).as_posix()}")
            entry.size = len(contents)
            entry.mode = 0o644
            bundle.addfile(entry, io.BytesIO(contents))
    checksum_file = release / "checksums_sha256.txt"
    with checksum_file.open("a") as stream:
        for path in (installer, *sidecars, manifest_archive):
            stream.write(f"{sha256(path)}  {path.name}\n")
    (args.metadata_directory / "modconductor-windows-x64.json").write_text(json.dumps({
        "version": args.version,
        "archive": archive.name,
        "archive_sha256": sha256(archive),
        "installer": installer.name,
        "installer_sha256": sha256(installer),
        "signature": "unsigned-local-verification-only",
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
