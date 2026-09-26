"""Read the assembled Linux payload used by native package builders."""

import argparse
import json
from pathlib import Path
import tarfile


ROOT = Path(__file__).resolve().parents[1]


def package_arguments(description: str, *, revision: bool = False) -> tuple[argparse.ArgumentParser, argparse.Namespace]:
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    if revision:
        parser.add_argument("--package-revision", type=int, default=1)
    parser.add_argument("--scratch-directory", type=Path, default=ROOT / ".agent-workspace")
    args = parser.parse_args()
    if revision and args.package_revision < 1:
        parser.error("The package revision must be positive.")
    return parser, args


def extract_payload(archive_path: Path, work: Path, parser: argparse.ArgumentParser) -> Path:
    extracted = work / "archive"
    extracted.mkdir()
    with tarfile.open(archive_path, "r:gz") as archive:
        archive.extractall(extracted, filter="data")
    launchers = list(extracted.glob("bin/modconductor")) + list(extracted.glob("*/bin/modconductor"))
    if len(launchers) != 1:
        parser.error("The Linux archive does not contain one desktop payload.")
    payload = launchers[0].parent.parent
    provenance = json.loads((payload / "share/doc/modconductor/provenance.json").read_text())
    if provenance["linux_rid"] != "linux-x64":
        parser.error("The archive is not a Linux x64 payload.")
    return payload
