#!/usr/bin/env python3
"""Write the installed Nix package inventory, SPDX file list, and build provenance."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path


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
    sbom = {
        "spdxVersion": "SPDX-2.3", "dataLicense": "CC0-1.0", "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"ModConductor-Nix-x86_64-linux-{args.version}",
        "documentNamespace": f"https://modconductor.invalid/spdx/nix/{args.version}/{sha256(manifest)}",
        "creationInfo": {
            "created": datetime.fromtimestamp(args.source_date_epoch, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "creators": ["Tool: nix/write-package-metadata.py"],
        },
        "packages": [{
            "name": "Mod Conductor", "SPDXID": "SPDXRef-ModConductor", "versionInfo": args.version,
            "downloadLocation": "NOASSERTION", "filesAnalyzed": True,
            "licenseConcluded": "NOASSERTION", "licenseDeclared": "NOASSERTION", "copyrightText": "NOASSERTION",
        }],
        "files": [{
            "fileName": "./" + item["path"], "SPDXID": f"SPDXRef-File-{index}",
            "checksums": [{"algorithm": "SHA256", "checksumValue": item["sha256"]}],
            "licenseConcluded": "NOASSERTION", "copyrightText": "NOASSERTION",
        } for index, item in enumerate(inventory)],
        "relationships": [{
            "spdxElementId": "SPDXRef-DOCUMENT", "relatedSpdxElement": "SPDXRef-ModConductor",
            "relationshipType": "DESCRIBES",
        }] + [{
            "spdxElementId": "SPDXRef-ModConductor", "relatedSpdxElement": f"SPDXRef-File-{index}",
            "relationshipType": "CONTAINS",
        } for index in range(len(inventory))],
    }
    (documents / "sbom.spdx.json").write_text(json.dumps(sbom, indent=2) + "\n")
    (documents / "provenance.json").write_text(json.dumps({
        "source_revision": args.revision, "nix_system": "x86_64-linux",
        "flutter_sdk": "3.47.4", "dotnet_sdk": "10.0.400",
        "signature": "unsigned-local-verification-only",
        "payload_manifest_sha256": sha256(manifest),
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
