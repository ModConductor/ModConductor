#!/usr/bin/env python3
"""Build and assemble one local Linux x64 desktop payload on an FHS runner."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "ui/apps/mod_conductor"
VERSION = re.search(r"^version: (\d+\.\d+\.\d+)", (APP / "pubspec.yaml").read_text(), re.MULTILINE).group(1)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def files_under(directory: Path) -> list[Path]:
    return sorted((path for path in directory.rglob("*") if path.is_file()), key=lambda path: path.relative_to(directory).as_posix())


def copy_required(source: Path, destination: Path) -> None:
    if not source.is_file():
        raise SystemExit(f"Required Linux runtime asset is missing: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def require_fhs_binary(path: Path) -> None:
    if not path.is_file() or not os.access(path, os.X_OK):
        raise SystemExit(f"Executable Linux runtime asset is missing: {path}")
    elf = subprocess.run(["readelf", "-l", "-d", str(path)], text=True, capture_output=True, check=True).stdout
    if "/nix/store/" in "\n".join(line for line in elf.splitlines() if "interpreter:" in line or "RPATH" in line or "RUNPATH" in line):
        raise SystemExit(f"Linux runtime asset is linked to the Nix store: {path}")


def require_tool_versions() -> None:
    expected = ((["dotnet", "--version"], "10.0.400"), (["rustc", "--version"], "rustc 1.89.0"))
    for command, prefix in expected:
        actual = subprocess.check_output(command, text=True).strip()
        if not actual.startswith(prefix):
            raise SystemExit(f"Expected {prefix}, found {actual}")
    flutter_output = subprocess.check_output(["flutter", "--version", "--machine"], text=True)
    flutter, _ = json.JSONDecoder().raw_decode(flutter_output.lstrip())
    if flutter["frameworkVersion"] != "3.47.4" or flutter["dartSdkVersion"].split()[0] != "3.13.3":
        raise SystemExit(f"Expected Flutter 3.47.4 and Dart 3.13.3, found {flutter['frameworkVersion']} and {flutter['dartSdkVersion']}")


def build(working: Path) -> tuple[Path, Path, Path]:
    environment = dict(os.environ, CARGO_TARGET_DIR=str(working / "cargo-target"))
    subprocess.run(["dotnet", "restore", "src/ModConductor.Engine/ModConductor.Engine.fsproj", "--locked-mode"], cwd=ROOT, env=environment, check=True)
    engine = working / "engine"
    subprocess.run([
        "dotnet", "publish", "src/ModConductor.Engine/ModConductor.Engine.fsproj", "-c", "Release", "-r", "linux-x64", "--self-contained", "true", "--no-restore",
        "-p:ModConductorLocalPublishVerificationOnly=true", "-o", str(engine),
    ], cwd=ROOT, env=environment, check=True)
    subprocess.run(["flutter", "clean"], cwd=APP, env=environment, check=True)
    subprocess.run(["flutter", "pub", "get", "--enforce-lockfile"], cwd=APP, env=environment, check=True)
    subprocess.run(["flutter", "build", "linux", "--release", "--no-pub"], cwd=APP, env=environment, check=True)
    subprocess.run(["cargo", "+1.89.0", "build", "--locked", "--release"], cwd=ROOT / "native/ModConductor.Loot.Helper", env=environment, check=True)
    return APP / "build/linux/x64/release/bundle", engine, working / "cargo-target/release/modconductor-loot-helper"


def assemble(bundle: Path, engine: Path, helper: Path, output: Path, revision: str) -> None:
    if output.exists():
        raise SystemExit(f"Package output must be a new directory: {output}")
    if not (bundle / "data/flutter_assets").is_dir():
        raise SystemExit("Build the Linux Flutter release bundle first.")
    require_fhs_binary(bundle / "mod_conductor")
    require_fhs_binary(engine / "ModConductor.Engine")
    require_fhs_binary(helper)
    for library in (bundle / "lib").glob("*.so"):
        dynamic = subprocess.run(["readelf", "-d", str(library)], text=True, capture_output=True, check=True).stdout
        if any("/nix/store/" in line for line in dynamic.splitlines() if "RPATH" in line or "RUNPATH" in line):
            raise SystemExit(f"Linux runtime library is linked to the Nix store: {library}")

    app = output / "app/modconductor"
    shutil.copytree(bundle, app)
    for name in ("ModConductor.Engine", "libe_sqlite3.so", "ModConductor.Engine.staticwebassets.endpoints.json"):
        copy_required(engine / name, app / "engine" / name)
    copy_required(helper, app / "engine/modconductor-loot-helper")
    for name in ("mod_conductor", "engine/ModConductor.Engine", "engine/modconductor-loot-helper"):
        (app / name).chmod(0o755)

    launcher = output / "bin/modconductor"
    launcher.parent.mkdir(parents=True)
    copy_required(ROOT / "packaging/linux-launcher.sh", launcher)
    launcher.chmod(0o755)
    desktop = output / "share/applications/dev.modconductor.mod_conductor.desktop"
    copy_required(ROOT / "packaging/dev.modconductor.mod_conductor.desktop", desktop)

    documents = output / "share/doc/modconductor"
    shutil.copytree(ROOT / "docs/third-party", documents / "third-party")
    copy_required(ROOT / "ui/packages/mc_ui_foundation/notices/Roboto-LICENSE.txt", documents / "third-party/Roboto-LICENSE.txt")
    copy_required(ROOT / "docs/third-party/libloot-LICENSE.txt", documents / "third-party/libloot-LICENSE.txt")
    locks = sorted((ROOT / "src").glob("*/packages.lock.json")) + sorted((ROOT / "tests").glob("*/packages.lock.json"))
    for source in (ROOT / "ui/pubspec.lock", ROOT / "native/ModConductor.Loot.Helper/Cargo.lock", ROOT / ".config/flutter-sdk.json", ROOT / "global.json", *locks):
        copy_required(source, documents / "dependency-manifests" / source.relative_to(ROOT))

    inventory = [{"path": path.relative_to(output).as_posix(), "sha256": sha256(path)} for path in files_under(output)]
    manifest = documents / "payload-sha256.json"
    manifest.write_text(json.dumps(inventory, indent=2) + "\n")
    date = datetime.fromtimestamp(int(subprocess.check_output(["git", "log", "-1", "--format=%ct"], cwd=ROOT, text=True)), timezone.utc)
    sbom = {
        "spdxVersion": "SPDX-2.3", "dataLicense": "CC0-1.0", "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"ModConductor-Linux-x64-{VERSION}",
        "documentNamespace": f"https://modconductor.invalid/spdx/linux/{VERSION}/{sha256(manifest)}",
        "creationInfo": {"created": date.strftime("%Y-%m-%dT%H:%M:%SZ"), "creators": ["Tool: tools/package-linux.py"]},
        "packages": [{"name": "Mod Conductor", "SPDXID": "SPDXRef-ModConductor", "versionInfo": VERSION, "downloadLocation": "NOASSERTION", "filesAnalyzed": True, "licenseConcluded": "NOASSERTION", "licenseDeclared": "NOASSERTION", "copyrightText": "NOASSERTION"}],
        "files": [{"fileName": "./" + item["path"], "SPDXID": f"SPDXRef-File-{index}", "checksums": [{"algorithm": "SHA256", "checksumValue": item["sha256"]}], "licenseConcluded": "NOASSERTION", "copyrightText": "NOASSERTION"} for index, item in enumerate(inventory)],
        "relationships": [{"spdxElementId": "SPDXRef-DOCUMENT", "relatedSpdxElement": "SPDXRef-ModConductor", "relationshipType": "DESCRIBES"}] + [{"spdxElementId": "SPDXRef-ModConductor", "relatedSpdxElement": f"SPDXRef-File-{index}", "relationshipType": "CONTAINS"} for index in range(len(inventory))],
    }
    (documents / "sbom.spdx.json").write_text(json.dumps(sbom, indent=2) + "\n")
    (documents / "provenance.json").write_text(json.dumps({
        "source_revision": revision, "linux_rid": "linux-x64", "flutter_sdk": "3.47.4", "dotnet_sdk": "10.0.400", "rust_toolchain": "1.89.0",
        "signature": "unsigned-local-verification-only", "payload_manifest_sha256": sha256(manifest),
    }, indent=2) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rid", required=True)
    parser.add_argument("--publish-directory", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--work-directory", type=Path, required=True)
    args = parser.parse_args()
    if args.rid != "linux-x64" or platform.machine().lower() not in ("x86_64", "amd64") or platform.system() != "Linux":
        parser.error("This package builder supports Linux x64 only.")
    if args.version != VERSION:
        parser.error(f"Expected product version {VERSION}, found {args.version}.")
    require_tool_versions()
    working = args.work_directory.resolve()
    working.mkdir(parents=True, exist_ok=True)
    bundle, engine, helper = build(working)
    assemble(bundle, engine, helper, args.publish_directory.resolve(), args.revision)
    print(f"Local unsigned Linux payload: {args.publish_directory}")


if __name__ == "__main__":
    main()
