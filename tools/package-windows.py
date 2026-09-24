#!/usr/bin/env python3
"""Assemble local, unsigned Windows installer and portable packages from built inputs."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import zipfile


ROOT = Path(__file__).resolve().parents[1]
VERSION = re.search(
    r"^version: (\d+\.\d+\.\d+)",
    (ROOT / "ui/apps/mod_conductor/pubspec.yaml").read_text(),
    re.MULTILINE,
).group(1)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def files_under(directory: Path) -> list[Path]:
    return sorted((path for path in directory.rglob("*") if path.is_file()), key=lambda p: p.relative_to(directory).as_posix())


def copy_required(source: Path, destination: Path) -> None:
    if not source.is_file():
        raise SystemExit(f"Required Windows runtime asset is missing: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def nsis_path(path: Path) -> str:
    return str(path).replace("/", "\\")


def write_uninstall_manifest(payload: Path, destination: Path) -> None:
    files = files_under(payload)
    directories = sorted(
        {parent for path in files for parent in path.relative_to(payload).parents if parent != Path(".")},
        key=lambda path: (-len(path.parts), path.as_posix()),
    )
    lines = [f'Delete "$INSTDIR\\{nsis_path(path.relative_to(payload))}"' for path in files]
    lines.extend(f'RMDir "$INSTDIR\\{nsis_path(path)}"' for path in directories)
    lines.append('RMDir "$INSTDIR"')
    destination.write_text("\n".join(lines) + "\n")


def write_zip(payload: Path, destination: Path) -> None:
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files_under(payload):
            relative = path.relative_to(payload).as_posix()
            entry = zipfile.ZipInfo(f"ModConductor/{relative}", date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o644 << 16
            with path.open("rb") as source, archive.open(entry, "w", force_zip64=True) as target:
                shutil.copyfileobj(source, target, length=1024 * 1024)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--flutter-bundle", type=Path, default=ROOT / "ui/apps/mod_conductor/build/windows/x64/runner/Release")
    parser.add_argument("--engine-publish", type=Path, default=ROOT / ".tools/publish/win-x64")
    parser.add_argument("--loot-helper", type=Path, required=True)
    parser.add_argument("--makensis", default="makensis")
    parser.add_argument("--version", help="Expected release version")
    parser.add_argument("--source-revision", help="Exact source bundle identifier when no Git checkout is available")
    parser.add_argument("--source-date-epoch", type=int, help="Source timestamp when no Git checkout is available")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.version is not None and args.version != VERSION:
        parser.error(f"Expected application version {args.version}, found {VERSION}.")
    if (args.source_revision is None) != (args.source_date_epoch is None):
        parser.error("--source-revision and --source-date-epoch must be given together")

    flutter = args.flutter_bundle.resolve()
    if not (flutter / "mod_conductor.exe").is_file() or not (flutter / "data/flutter_assets").is_dir():
        raise SystemExit("Build the Windows Flutter release bundle first.")
    if args.output.exists():
        raise SystemExit(f"Package output must be a new directory: {args.output}")
    version_check = subprocess.run([args.makensis, "/VERSION"], text=True, capture_output=True, check=True)
    if version_check.stdout.strip().lstrip("v") != "3.12":
        raise SystemExit(f"NSIS 3.12 is required, found {version_check.stdout.strip()!r}")

    output = args.output.resolve()
    payload = output / "payload"
    shutil.copytree(flutter, payload)
    engine = args.engine_publish.resolve()
    for name in ("ModConductor.Engine.exe", "e_sqlite3.dll", "ModConductor.Engine.staticwebassets.endpoints.json"):
        copy_required(engine / name, payload / "engine" / name)
    copy_required(args.loot_helper.resolve(), payload / "engine/modconductor-loot-helper.exe")
    shutil.copytree(ROOT / "docs/third-party", payload / "notices")
    copy_required(ROOT / "ui/packages/mc_ui_foundation/notices/Roboto-LICENSE.txt", payload / "notices/Roboto-LICENSE.txt")
    copy_required(ROOT / "docs/third-party/libloot-LICENSE.txt", payload / "notices/libloot-LICENSE.txt")
    copy_required(ROOT / "docs/third-party/nsis-LICENSE.txt", payload / "notices/nsis-LICENSE.txt")

    inputs = output / "dependency-manifests"
    inputs.mkdir()
    locks = sorted((ROOT / "src").glob("*/packages.lock.json")) + sorted((ROOT / "tests").glob("*/packages.lock.json"))
    for source in [ROOT / "ui/pubspec.lock", ROOT / "native/ModConductor.Loot.Helper/Cargo.lock", ROOT / ".config/flutter-sdk.json", ROOT / "global.json", *locks]:
        copy_required(source, inputs / source.relative_to(ROOT))

    inventory = [{"path": path.relative_to(payload).as_posix(), "sha256": sha256(path)} for path in files_under(payload)]
    (output / "payload-sha256.json").write_text(json.dumps(inventory, indent=2) + "\n")
    source_revision = args.source_revision or subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    source_date_epoch = args.source_date_epoch or int(subprocess.check_output(["git", "log", "-1", "--format=%ct"], cwd=ROOT, text=True))
    sbom = {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"ModConductor-Windows-x64-{VERSION}",
        "documentNamespace": f"https://modconductor.invalid/spdx/windows/{VERSION}/{sha256(output / 'payload-sha256.json')}",
        "creationInfo": {"created": datetime.fromtimestamp(source_date_epoch, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "creators": ["Tool: tools/package-windows.py"]},
        "packages": [{"name": "Mod Conductor", "SPDXID": "SPDXRef-ModConductor", "versionInfo": VERSION, "downloadLocation": "NOASSERTION", "filesAnalyzed": True, "licenseConcluded": "NOASSERTION", "licenseDeclared": "NOASSERTION", "copyrightText": "NOASSERTION"}],
        "files": [{"fileName": "./" + item["path"], "SPDXID": f"SPDXRef-File-{index}", "checksums": [{"algorithm": "SHA256", "checksumValue": item["sha256"]}], "licenseConcluded": "NOASSERTION", "copyrightText": "NOASSERTION"} for index, item in enumerate(inventory)],
        "relationships": [{"spdxElementId": "SPDXRef-DOCUMENT", "relatedSpdxElement": "SPDXRef-ModConductor", "relationshipType": "DESCRIBES"}] + [{"spdxElementId": "SPDXRef-ModConductor", "relatedSpdxElement": f"SPDXRef-File-{index}", "relationshipType": "CONTAINS"} for index in range(len(inventory))],
    }
    (output / "sbom.spdx.json").write_text(json.dumps(sbom, indent=2) + "\n")
    (output / "provenance.json").write_text(json.dumps({
        "source_revision": source_revision,
        "source_is_scoped_bundle": args.source_revision is not None,
        "source_worktree_dirty": None if args.source_revision is not None else bool(subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT)),
        "flutter_sdk": json.loads((ROOT / ".config/flutter-sdk.json").read_text())["version"],
        "windows_rid": "win-x64",
        "installer_builder": "NSIS 3.12",
        "signature": "unsigned-local-verification-only",
        "payload_manifest_sha256": sha256(output / "payload-sha256.json"),
    }, indent=2) + "\n")

    write_uninstall_manifest(payload, output / "uninstall-files.nsh")
    portable = output / f"ModConductor-{VERSION}-win-x64-portable.zip"
    write_zip(payload, portable)
    installer = output / f"ModConductor-{VERSION}-win-x64-setup.exe"
    subprocess.run([
        args.makensis,
        f"/DPAYLOAD={nsis_path(payload)}",
        f"/DUNINSTALL_FILES={nsis_path(output / 'uninstall-files.nsh')}",
        f"/DOUTPUT={nsis_path(installer)}",
        f"/DVERSION={VERSION}",
        f"/DAPP_ICON={nsis_path(ROOT / 'ui/apps/mod_conductor/windows/runner/resources/app_icon.ico')}",
        str(ROOT / "tools/windows-installer.nsi"),
    ], check=True)
    (output / "SHA256SUMS").write_text("".join(f"{sha256(path)}  {path.name}\n" for path in (installer, portable)))
    print(f"Local unsigned Windows packages: {installer} and {portable}")


if __name__ == "__main__":
    main()
