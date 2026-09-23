#!/usr/bin/env python3
"""Record the assembled Linux archive checksum for package review."""

import argparse
import hashlib
import json
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-directory", type=Path, required=True)
    parser.add_argument("--metadata-directory", type=Path, required=True)
    args = parser.parse_args()
    archive = args.release_directory / f"ModConductor-{args.version}-linux-x64.tar.gz"
    if not archive.is_file():
        parser.error(f"Linux archive is missing: {archive}")
    digest = hashlib.sha256()
    with archive.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    checksum = digest.hexdigest()
    args.metadata_directory.mkdir(parents=True, exist_ok=True)
    (args.metadata_directory / "modconductor-linux-x64.json").write_text(json.dumps({
        "version": args.version, "archive": archive.name, "sha256": checksum,
        "signature": "unsigned-local-verification-only",
    }, indent=2) + "\n")


if __name__ == "__main__":
    main()
