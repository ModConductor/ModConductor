#!/usr/bin/env bash
set -euo pipefail
archive=$1 output=$2 version=$3
root=$(cd "$(dirname "$0")/.." && pwd)
[[ -f $archive && $version =~ ^[0-9]+(\.[0-9]+)*$ ]] || exit 1
archive=$(realpath "$archive")
mkdir -p "$output"
output=$(cd "$output" && pwd)
sha=$(sha256sum "$archive" | cut -d ' ' -f1)
recipe="$output/modconductor-bin.PKGBUILD"
{
  cat <<RECIPE
pkgname=modconductor-bin
pkgver=$version
pkgrel=1
pkgdesc='Desktop mod organiser'
arch=('x86_64')
url='https://github.com/alsi-lawr/ModConductor'
license=('GPL-3.0-or-later' 'GPL-3.0-only' 'MPL-2.0' 'Apache-2.0' 'BSD-3-Clause' 'BSD-2-Clause' 'MIT' '0BSD' 'CC0-1.0' 'CC-BY-4.0' 'Unicode-3.0' 'Unicode-DFS-2016' 'Zlib' 'BSL-1.0' 'FTL' 'IJG')
_release_base='https://github.com/alsi-lawr/ModConductor/releases/download'
depends=('glibc' 'gcc-libs' 'gtk3' 'libepoxy' 'libglvnd' 'libsecret' 'icu' 'libunwind' 'openssl' 'zlib' 'glib2' 'fontconfig' 'ttf-dejavu' 'gsettings-desktop-schemas' 'xdg-utils' 'shared-mime-info')
provides=('modconductor')
conflicts=('modconductor')
options=('!strip' '!debug')
RECIPE
  cat <<'RECIPE'
source=("modconductor-v${pkgver}-linux-x64.tar.gz::${_release_base}/v${pkgver}/modconductor-v${pkgver}-linux-x64.tar.gz")
RECIPE
  printf "sha256sums=('%s')\n" "$sha"
  cat <<'RECIPE'

package() {
  local payload="${srcdir}/modconductor-v${pkgver}-linux-x64"
  install -d "${pkgdir}/usr/lib/modconductor" "${pkgdir}/usr/bin" "${pkgdir}/usr/share/doc"
  cp -a --no-preserve=ownership "${payload}/." "${pkgdir}/usr/lib/modconductor/"
  cat > "${pkgdir}/usr/bin/modconductor" <<'MC_LAUNCHER'
RECIPE
  cat "$root/packaging/linux-installed-launcher.sh"
  cat <<'RECIPE'
MC_LAUNCHER
  chmod 755 "${pkgdir}/usr/bin/modconductor"
  install -Dm644 "${payload}/share/applications/dev.modconductor.mod_conductor.desktop" "${pkgdir}/usr/share/applications/dev.modconductor.mod_conductor.desktop"
  install -Dm644 "${payload}/share/mime/packages/modconductor-profile.xml" "${pkgdir}/usr/share/mime/packages/modconductor-profile.xml"
  install -Dm644 "${payload}/share/icons/hicolor/48x48/apps/dev.modconductor.mod_conductor.png" "${pkgdir}/usr/share/icons/hicolor/48x48/apps/dev.modconductor.mod_conductor.png"
  install -Dm644 "${payload}/share/icons/hicolor/256x256/apps/dev.modconductor.mod_conductor.png" "${pkgdir}/usr/share/icons/hicolor/256x256/apps/dev.modconductor.mod_conductor.png"
  ln -s ../../lib/modconductor/share/doc/modconductor "${pkgdir}/usr/share/doc/modconductor"
  install -d "${pkgdir}/usr/share/licenses"
  ln -s ../../lib/modconductor/share/doc/modconductor "${pkgdir}/usr/share/licenses/modconductor-bin"
}
RECIPE
} > "$recipe"
docker run --rm --init --network none --user "$(id -u):$(id -g)" \
  -v "$output:/recipe" -w /recipe -e HOME=/recipe \
  archlinux@sha256:8745817f349ed24373341ddb92776209eeec3f0364ea48f7f645ac5800d30a50 \
  makepkg --printsrcinfo -p modconductor-bin.PKGBUILD > "$output/modconductor-bin.SRCINFO"
