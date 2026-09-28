#!/usr/bin/env python3
"""Retain Ubuntu package identities and notices for AppImage-bundled files."""

from pathlib import Path
import shutil
import subprocess
import sys


appdir = Path(sys.argv[1])
documentation = appdir / "usr/lib/modconductor/share/doc/modconductor/third-party/ubuntu-24.04"
documentation.mkdir(parents=True, exist_ok=True)
libraries = appdir / "usr/lib"
packages = {}


def owner(relative: Path) -> tuple[str, Path] | None:
    for source in (Path("/usr/lib/x86_64-linux-gnu") / relative,
                   Path("/lib/x86_64-linux-gnu") / relative,
                   Path("/usr/lib") / relative):
        if not source.exists():
            continue
        for candidate in (source, source.resolve()):
            found = subprocess.run(["dpkg-query", "-S", str(candidate)], text=True,
                                   capture_output=True)
            if found.returncode == 0:
                return found.stdout.split(": ", 1)[0].split(",", 1)[0], source
    return None


for path in sorted(libraries.rglob("*")):
    if not path.is_file() or path.is_relative_to(libraries / "modconductor"):
        continue
    match = owner(path.relative_to(libraries))
    if match:
        package, source = match
        packages.setdefault(package, []).append((path.relative_to(appdir), source))

for resource in ("gsettings-desktop-schemas", "libglib2.0-bin", "libgtk-3-0t64",
                 "fontconfig", "fonts-dejavu-core", "xdg-utils", "libsecret-1-0",
                 "adwaita-icon-theme", "shared-mime-info"):
    packages.setdefault(resource, [])

with (documentation / "bundled-ubuntu-packages.tsv").open("w") as listing:
    listing.write("package\tversion\tsource_package\tsource_version\tappdir_path\tubuntu_path\n")
    for package, files in sorted(packages.items()):
        version = subprocess.check_output(["dpkg-query", "-W", "-f=${Version}", package],
                                          text=True).strip()
        source_package, source_version = subprocess.check_output(
            ["dpkg-query", "-W", "-f=${source:Package}\t${source:Version}", package],
            text=True).rstrip("\n").split("\t")
        source_package = source_package or package.split(":", 1)[0]
        source_version = source_version or version
        copyright_file = Path("/usr/share/doc") / package.split(":", 1)[0] / "copyright"
        if not copyright_file.is_file():
            raise SystemExit(f"Bundled Ubuntu package lacks copyright file: {package}")
        shutil.copy2(copyright_file, documentation / (package.replace(":", "-") + ".copyright"))
        for deployed, source in files or [(Path("."), Path("resource"))]:
            listing.write(f"{package}\t{version}\t{source_package}\t{source_version}\t{deployed}\t{source}\n")
