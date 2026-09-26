#!/usr/bin/env python3
"""Write the installed Nix package inventory, SPDX file list, and build provenance."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from package_metadata import spdx_document


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--revision", required=True)
    parser.add_argument("--source-date-epoch", type=int, required=True)
    args = parser.parse_args()
    output = args.output
    documents = output / "share/doc/modconductor"
    files = sorted(path for path in output.rglob("*") if path.is_file())
    inventory = [{"path": path.relative_to(output).as_posix(), "sha256": sha256(path)} for path in files]
    manifest = documents / "payload-sha256.json"
    manifest.write_text(json.dumps(inventory, indent=2) + "\n")
    sbom = spdx_document(
        inventory, args.version, "Nix-x86_64-linux", "nix", sha256(manifest),
        datetime.fromtimestamp(args.source_date_epoch, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "nix/write-package-metadata.py",
    )
    (documents / "sbom.spdx.json").write_text(json.dumps(sbom, indent=2) + "\n")
    (documents / "provenance.json").write_text(json.dumps({
        "source_revision": args.revision, "nix_system": "x86_64-linux",
        "flutter_sdk": "3.47.4", "dotnet_sdk": "10.0.400",
        "signature": "unsigned-local-verification-only",
        "payload_manifest_sha256": sha256(manifest),
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
