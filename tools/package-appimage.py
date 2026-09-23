#!/usr/bin/env python3
"""Build a Linux x64 AppImage from the assembled portable archive."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile


ROOT = Path(__file__).resolve().parents[1]
IMAGE = "mc061-appimage-tools:local"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--scratch-directory", type=Path, default=ROOT / ".agent-workspace")
    args = parser.parse_args()
    archive_path = args.archive.resolve()
    output = args.output.resolve()
    scratch = args.scratch_directory.resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["python3", str(ROOT / "tools/bootstrap-appimage-tools.py")], check=True)
    context = ROOT / "tools/appimage-package"
    subprocess.run(["docker", "build", "-t", IMAGE, "-f", str(context / "Dockerfile"), str(context)], check=True)
    with tempfile.TemporaryDirectory(prefix="package-appimage-", dir=scratch) as temporary:
        work = Path(temporary)
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
        sbom = json.loads((payload / "share/doc/modconductor/sbom.spdx.json").read_text())
        if sbom["packages"][0]["versionInfo"] != args.version:
            parser.error("The archive version does not match the requested version.")

        appdir = work / "AppDir"
        app = appdir / "usr/lib/modconductor"
        shutil.copytree(payload, app)
        command = appdir / "usr/bin/modconductor"
        command.parent.mkdir(parents=True)
        shutil.copy2(ROOT / "packaging/appimage/modconductor.sh", command)
        command.chmod(0o755)
        desktop = appdir / "usr/share/applications/dev.modconductor.mod_conductor.desktop"
        desktop.parent.mkdir(parents=True)
        shutil.copy2(payload / "share/applications/dev.modconductor.mod_conductor.desktop", desktop)
        shutil.copytree(payload / "share/icons/hicolor", appdir / "usr/share/icons/hicolor")
        notices = app / "share/doc/modconductor/third-party"
        shutil.copy2(ROOT / "docs/third-party/appimage-runtime-LICENSE.txt", notices)
        shutil.copy2(ROOT / "docs/third-party/linuxdeploy-plugin-gtk-LICENSE.txt", notices)
        for name, source in (("AppRun.sh", "AppRun.sh"), ("fonts.conf", "fonts.conf")):
            shutil.copy2(ROOT / "packaging/appimage" / source, work / name)
        shutil.copy2(context / "bundled-notices.py", work / "bundled-notices.py")
        shutil.copy2(context / "build.sh", work / "build.sh")
        (work / "home").mkdir()
        (work / "tmp").mkdir()
        tool_cache = ROOT / ".tools/appimage-tools"
        subprocess.run([
            "docker", "run", "--rm", "--init", "--network", "none",
            "--user", f"{os.getuid()}:{os.getgid()}",
            "-v", f"{work}:/work", "-v", f"{tool_cache}:/tool-cache:ro",
            "-w", "/work", IMAGE, "sh", "/work/build.sh",
        ], check=True)
        shutil.move(work / "modconductor.AppImage", output)
        output.chmod(0o755)
        print(f"Local unsigned AppImage: {output}")


if __name__ == "__main__":
    main()
