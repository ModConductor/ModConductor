#!/usr/bin/env python3
"""Attach the exact committed source and vendored Rust dependencies to a release."""

import argparse
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def revision_from_linux(archive: Path) -> str:
    with tarfile.open(archive, "r:gz") as bundle:
        candidates = [member for member in bundle if member.name.endswith("/share/doc/modconductor/provenance.json")]
        if len(candidates) != 1:
            raise SystemExit("Linux archive must contain one provenance.json")
        with bundle.extractfile(candidates[0]) as stream:
            return json.load(stream)["source_revision"]


def add_file(bundle: tarfile.TarFile, name: str, data: bytes, mode: int = 0o644) -> None:
    entry = tarfile.TarInfo(name)
    entry.size = len(data)
    entry.mode = mode
    bundle.addfile(entry, io.BytesIO(data))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-directory", type=Path, required=True)
    parser.add_argument("--metadata-directory", type=Path, required=True)
    args = parser.parse_args()
    release = args.release_directory
    linux = release / f"modconductor-v{args.version}-linux-x64.tar.gz"
    windows = release / f"modconductor-v{args.version}-win-x64-provenance.json"
    if not linux.is_file() or not windows.is_file():
        parser.error("Both platform provenance records are required before source finalization")
    revision = revision_from_linux(linux)
    if revision != json.loads(windows.read_text())["source_revision"]:
        parser.error("Linux and Windows source revisions differ")
    if not re.fullmatch(r"[0-9a-f]{40}", revision):
        parser.error("Platform provenance does not name a full Git commit")
    if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip() != revision:
        parser.error("The release source checkout differs from the platform binaries")

    name = f"modconductor-v{args.version}-source"
    output = release / f"{name}.tar.gz"
    if output.exists():
        parser.error(f"Source archive already exists: {output}")
    with tempfile.TemporaryDirectory(prefix="source-release-", dir=release) as temporary:
        scratch = Path(temporary)
        vendor = scratch / "vendor"
        result = subprocess.run([
            "cargo", "+1.89.0", "vendor", "--locked", "--manifest-path",
            str(ROOT / "native/ModConductor.Loot.Helper/Cargo.toml"), str(vendor),
        ], cwd=ROOT, text=True, stdout=subprocess.PIPE, check=True)
        config = result.stdout.replace(str(vendor), "vendor")
        if str(vendor) in config or 'directory = "vendor"' not in config:
            parser.error("Cargo did not produce a portable vendor configuration")
        if not (vendor / "libloot/Cargo.toml").is_file():
            parser.error("The pinned libloot source is missing from the Cargo vendor output")
        raw = scratch / "source.tar"
        subprocess.run(["git", "archive", "--format=tar", f"--prefix={name}/",
                        "--output", str(raw), revision], cwd=ROOT, check=True)
        with tarfile.open(raw, "a") as bundle:
            add_file(bundle, f"{name}/SOURCE-REVISION", (revision + "\n").encode())
            add_file(bundle, f"{name}/.cargo/config.toml", config.encode())
            for path in sorted(vendor.rglob("*")):
                if path.is_symlink():
                    parser.error(f"Vendored source has a symlink: {path}")
                if path.is_file():
                    relative = path.relative_to(vendor).as_posix()
                    add_file(bundle, f"{name}/vendor/{relative}", path.read_bytes(),
                             0o755 if path.stat().st_mode & 0o111 else 0o644)
        compressed_output = scratch / output.name
        with raw.open("rb") as source, compressed_output.open("wb") as destination:
            with gzip.GzipFile(fileobj=destination, mode="wb", filename="", mtime=0) as compressed:
                for block in iter(lambda: source.read(1024 * 1024), b""):
                    compressed.write(block)
        compressed_output.replace(output)

    digest = sha256(output)
    with (release / "checksums_sha256.txt").open("a") as checksums:
        checksums.write(f"{digest}  {output.name}\n")
    args.metadata_directory.mkdir(parents=True, exist_ok=True)
    (args.metadata_directory / "modconductor-source.json").write_text(json.dumps({
        "version": args.version, "source_revision": revision,
        "archive": output.name, "archive_sha256": digest,
        "rust_dependencies": "vendored Cargo.lock closure",
        "signature": "unsigned-local-verification-only",
    }, indent=2) + "\n")
    print(f"Matching source archive: {output}")


if __name__ == "__main__":
    main()
