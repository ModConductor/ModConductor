#!/usr/bin/env python3
"""Build a Linux x64 AppImage from the assembled portable archive."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

from linux_package_input import extract_payload, package_arguments


ROOT = Path(__file__).resolve().parents[1]
IMAGE = "mc061-appimage-tools:local"


def main() -> None:
    parser, args = package_arguments(__doc__)
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
        payload = extract_payload(archive_path, work, parser)
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
        mime = appdir / "usr/share/mime/packages/modconductor-profile.xml"
        mime.parent.mkdir(parents=True)
        shutil.copy2(payload / "share/mime/packages/modconductor-profile.xml", mime)
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
