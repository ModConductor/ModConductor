#!/usr/bin/env python3
"""Build an Ubuntu 24.04 amd64 package from the assembled Linux archive."""

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile


ROOT = Path(__file__).resolve().parents[1]
DEPENDS = (
    "libc6 (>= 2.34), libstdc++6 (>= 12), libgtk-3-0t64, libepoxy0, "
    "libsecret-1-0, libegl1, libgles2, libicu74, libunwind8, "
    "libssl3t64, zlib1g, libglib2.0-bin, fontconfig, fonts-dejavu-core, "
    "gsettings-desktop-schemas, xdg-utils"
)


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
    with tempfile.TemporaryDirectory(prefix="package-deb-", dir=args.scratch_directory) as temporary:
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

        package = work / "package"
        app = package / "usr/lib/modconductor"
        shutil.copytree(payload, app)
        command = package / "usr/bin/modconductor"
        command.parent.mkdir(parents=True)
        shutil.copy2(ROOT / "packaging/linux-installed-launcher.sh", command)
        command.chmod(0o755)
        desktop = package / "usr/share/applications/dev.modconductor.mod_conductor.desktop"
        desktop.parent.mkdir(parents=True)
        shutil.copy2(ROOT / "packaging/dev.modconductor.mod_conductor.desktop", desktop)
        shutil.copytree(payload / "share/icons/hicolor", package / "usr/share/icons/hicolor")
        documentation = package / "usr/share/doc/modconductor"
        documentation.parent.mkdir(parents=True)
        documentation.symlink_to("../../lib/modconductor/share/doc/modconductor", target_is_directory=True)

        control = package / "DEBIAN/control"
        control.parent.mkdir()
        control.write_text(
            "Package: modconductor\n"
            f"Version: {args.version}-{args.package_revision}\n"
            "Architecture: amd64\n"
            "Maintainer: Mod Conductor contributors\n"
            "Section: games\n"
            "Priority: optional\n"
            "Homepage: https://github.com/alsi-lawr/ModConductor\n"
            f"Depends: {DEPENDS}\n"
            "Description: Desktop mod organiser\n"
        )
        subprocess.run(["dpkg-deb", "--build", "--root-owner-group", str(package), str(args.output)], check=True)


if __name__ == "__main__":
    main()
