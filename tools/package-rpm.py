#!/usr/bin/env python3
"""Build a Fedora 44 x64 RPM from the assembled Linux archive."""

from pathlib import Path
import shutil
import subprocess
import tempfile

from linux_package_input import extract_payload, package_arguments


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser, args = package_arguments(__doc__, revision=True)
    args.scratch_directory.mkdir(parents=True, exist_ok=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="package-rpm-", dir=args.scratch_directory) as temporary:
        work = Path(temporary)
        payload = extract_payload(args.archive, work, parser)
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
