#!/usr/bin/env python3
"""Build a Fedora 44 x64 RPM from the assembled Linux archive."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--package-revision", type=int, default=1)
    parser.add_argument("--scratch-directory", type=Path, default=ROOT / ".agent-workspace")
    args = parser.parse_args()
    if args.package_revision < 1:
        parser.error("The package revision must be positive.")
    args.scratch_directory.mkdir(parents=True, exist_ok=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="package-rpm-", dir=args.scratch_directory) as temporary:
        work = Path(temporary)
        extracted = work / "archive"
        extracted.mkdir()
        with tarfile.open(args.archive, "r:gz") as archive:
            archive.extractall(extracted, filter="data")
        launchers = list(extracted.glob("bin/modconductor")) + list(extracted.glob("*/bin/modconductor"))
        if len(launchers) != 1:
            parser.error("The Linux archive does not contain one desktop payload.")
        payload = launchers[0].parent.parent
        provenance = json.loads((payload / "share/doc/modconductor/provenance.json").read_text())
        if provenance["linux_rid"] != "linux-x64":
            parser.error("The archive is not a Linux x64 payload.")
        top = work / "rpmbuild"
        (top / "SPECS").mkdir(parents=True)
        (work / "rpm-tmp").mkdir()
        command = ["rpmbuild", "-bb", "--define", f"_topdir {top}", "--define", f"_tmppath {work / 'rpm-tmp'}",
                   "--define", f"mc_version {args.version}", "--define", f"mc_release {args.package_revision}",
                   "--define", f"mc_payload {payload}",
                   "--define", f"mc_launcher {ROOT / 'packaging/linux-installed-launcher.sh'}",
                   "--define", f"mc_desktop {ROOT / 'packaging/dev.modconductor.mod_conductor.desktop'}",
                   str(ROOT / "packaging/modconductor-fedora.spec")]
        subprocess.run(command, check=True)
        built = top / f"RPMS/x86_64/modconductor-{args.version}-{args.package_revision}.fc44.x86_64.rpm"
        shutil.copy2(built, args.output)


if __name__ == "__main__":
    main()
