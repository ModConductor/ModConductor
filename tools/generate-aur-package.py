#!/usr/bin/env python3
"""Create a standalone Arch package recipe for the assembled Linux archive."""

import argparse
import hashlib
import os
from pathlib import Path
import re
import shlex
import subprocess


ROOT = Path(__file__).resolve().parents[1]
ARCH_IMAGE = "archlinux@sha256:8745817f349ed24373341ddb92776209eeec3f0364ea48f7f645ac5800d30a50"
DEPENDENCIES = (
    "glibc", "gcc-libs", "gtk3", "libepoxy", "libglvnd", "libsecret",
    "icu", "libunwind", "openssl", "zlib", "glib2", "fontconfig",
    "ttf-dejavu", "gsettings-desktop-schemas", "xdg-utils",
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output-directory", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--package-revision", type=int, default=1)
    parser.add_argument("--base-url", default="https://github.com/alsi-lawr/ModConductor/releases/download")
    args = parser.parse_args()
    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)*", args.version):
        parser.error("The Arch package version must contain only numeric parts.")
    if args.package_revision < 1:
        parser.error("The package revision must be positive.")
    expected = f"modconductor-v{args.version}-linux-x64.tar.gz"
    if args.archive.name != expected or not args.archive.is_file():
        parser.error(f"Expected the assembled {expected} archive.")

    output = args.output_directory.resolve()
    output.mkdir(parents=True, exist_ok=True)
    launcher = (ROOT / "packaging/linux-installed-launcher.sh").read_text()
    dependencies = " ".join(shlex.quote(name) for name in DEPENDENCIES)
    recipe = (
        "pkgname=modconductor-bin\n"
        f"pkgver={args.version}\n"
        f"pkgrel={args.package_revision}\n"
        "pkgdesc='Desktop mod organiser'\n"
        "arch=('x86_64')\n"
        "url='https://github.com/alsi-lawr/ModConductor'\n"
        f"_release_base={shlex.quote(args.base_url.rstrip('/'))}\n"
        f"depends=({dependencies})\n"
        "provides=('modconductor')\n"
        "conflicts=('modconductor')\n"
        "options=('!strip' '!debug')\n"
        'source=("modconductor-v${pkgver}-linux-x64.tar.gz::${_release_base}/v${pkgver}/modconductor-v${pkgver}-linux-x64.tar.gz")\n'
        f"sha256sums=('{sha256(args.archive)}')\n"
        "\n"
        "package() {\n"
        '  local payload="${srcdir}/modconductor-v${pkgver}-linux-x64"\n'
        '  install -d "${pkgdir}/usr/lib/modconductor" "${pkgdir}/usr/bin" "${pkgdir}/usr/share/doc"\n'
        '  cp -a --no-preserve=ownership "${payload}/." "${pkgdir}/usr/lib/modconductor/"\n'
        '  cat > "${pkgdir}/usr/bin/modconductor" <<\'MC_LAUNCHER\'\n'
        f"{launcher}"
        "MC_LAUNCHER\n"
        '  chmod 755 "${pkgdir}/usr/bin/modconductor"\n'
        '  install -Dm644 "${payload}/share/applications/dev.modconductor.mod_conductor.desktop" "${pkgdir}/usr/share/applications/dev.modconductor.mod_conductor.desktop"\n'
        '  install -Dm644 "${payload}/share/icons/hicolor/48x48/apps/dev.modconductor.mod_conductor.png" "${pkgdir}/usr/share/icons/hicolor/48x48/apps/dev.modconductor.mod_conductor.png"\n'
        '  install -Dm644 "${payload}/share/icons/hicolor/256x256/apps/dev.modconductor.mod_conductor.png" "${pkgdir}/usr/share/icons/hicolor/256x256/apps/dev.modconductor.mod_conductor.png"\n'
        '  ln -s ../../lib/modconductor/share/doc/modconductor "${pkgdir}/usr/share/doc/modconductor"\n'
        "}\n"
    )
    recipe_path = output / "modconductor-bin.PKGBUILD"
    recipe_path.write_text(recipe)
    result = subprocess.run([
        "docker", "run", "--rm", "--init", "--network", "none",
        "--user", f"{os.getuid()}:{os.getgid()}",
        "-v", f"{output}:/recipe", "-w", "/recipe", "-e", "HOME=/recipe",
        ARCH_IMAGE, "makepkg", "--printsrcinfo", "-p", recipe_path.name,
    ], text=True, stdout=subprocess.PIPE, check=True)
    (output / "modconductor-bin.SRCINFO").write_text(result.stdout)
    print(f"Local Arch recipe: {recipe_path}")


if __name__ == "__main__":
    main()
