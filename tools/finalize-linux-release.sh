#!/usr/bin/env bash
set -euo pipefail
version=$1 release=$2 metadata=$3
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
archive="$release/modconductor-v$version-linux-x64.tar.gz"
[[ -f $archive ]] || { echo "Missing Linux archive: $archive" >&2; exit 1; }
mkdir -p .agent-workspace "$metadata"
work=$(mktemp -d "$PWD/.agent-workspace/native-packages.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
tar -xzf "$archive" -C "$work"
mapfile -t launchers < <(find "$work" -path '*/bin/modconductor' -type f)
[[ ${#launchers[@]} -eq 1 ]] || { echo "Expected one Linux payload" >&2; exit 1; }
payload=$(dirname "$(dirname "${launchers[0]}")")
[[ -x $payload/bin/modconductor ]] || { echo "Linux payload missing" >&2; exit 1; }
[[ $(jq -r .linux_rid "$payload/share/doc/modconductor/provenance.json") == linux-x64 ]] || exit 1
package="$work/deb"
mkdir -p "$package/usr/lib/modconductor" "$package/usr/bin" "$package/usr/share/applications" "$package/usr/share/mime/packages" "$package/usr/share"
cp -a "$payload/." "$package/usr/lib/modconductor/"
install -m755 packaging/linux-installed-launcher.sh "$package/usr/bin/modconductor"
cp packaging/dev.modconductor.mod_conductor.desktop "$package/usr/share/applications/"
cp packaging/modconductor-profile.xml "$package/usr/share/mime/packages/"
cp -a "$payload/share/icons" "$package/usr/share/"
mkdir -p "$package/usr/share/doc"
ln -s ../../lib/modconductor/share/doc/modconductor "$package/usr/share/doc/modconductor"
mkdir -p "$package/DEBIAN"
cat > "$package/DEBIAN/control" <<CONTROL
Package: modconductor
Version: $version-1
Architecture: amd64
Maintainer: Mod Conductor contributors
Section: games
Priority: optional
Homepage: https://github.com/alsi-lawr/ModConductor
Depends: libc6 (>= 2.34), libstdc++6 (>= 12), libgtk-3-0t64, libepoxy0, libsecret-1-0, libegl1, libgles2, libicu74, libunwind8, libssl3t64, zlib1g, libglib2.0-bin, fontconfig, fonts-dejavu-core, gsettings-desktop-schemas, xdg-utils, shared-mime-info
Description: Desktop mod organiser
CONTROL
deb="$release/ModConductor_$version-1_amd64.deb"
dpkg-deb --build --root-owner-group "$package" "$deb"
docker build -t modconductor-rpm-package:local -f tools/rpm-package/Dockerfile tools/rpm-package
mkdir -p "$work/rpmbuild/SPECS" "$work/rpm-tmp"
docker run --rm --init --user "$(id -u):$(id -g)" -v "$root:/src" -w /src \
  -e HOME=/src/.agent-workspace modconductor-rpm-package:local \
  rpmbuild -bb --define "_topdir /src/${work#"$root/"}/rpmbuild" \
  --define "_tmppath /src/${work#"$root/"}/rpm-tmp" \
  --define "mc_version $version" --define "mc_release 1" \
  --define "mc_payload /src/${payload#"$root/"}" \
  --define "mc_launcher /src/packaging/linux-installed-launcher.sh" \
  --define "mc_desktop /src/packaging/dev.modconductor.mod_conductor.desktop" \
  --define "mc_mime /src/packaging/modconductor-profile.xml" \
  packaging/modconductor-fedora.spec
rpm="$release/modconductor-$version-1.fc44.x86_64.rpm"
cp "$work/rpmbuild/RPMS/x86_64/${rpm##*/}" "$rpm"
bash tools/package-appimage.sh "$archive" "$release/modconductor-$version-linux-x64.AppImage" "$version"
appimage="$release/modconductor-$version-linux-x64.AppImage"
cask="$release/modconductor.rb"
cat > "$cask" <<CASK
cask "modconductor" do
  version "$version"
  sha256 "$(sha256sum "$appimage" | cut -d ' ' -f1)"

  url "https://github.com/alsi-lawr/ModConductor/releases/download/v$version/${appimage##*/}"
  name "Mod Conductor"
  desc "Desktop mod organiser"
  homepage "https://github.com/alsi-lawr/ModConductor"

  depends_on :linux

  app_image "${appimage##*/}"
end
CASK
bash tools/generate-aur-package.sh "$archive" "$release" "$version"
recipe="$release/modconductor-bin.PKGBUILD"
srcinfo="$release/modconductor-bin.SRCINFO"
for file in "$deb" "$rpm" "$appimage" "$cask" "$recipe" "$srcinfo"; do
  sha256sum "$file" | sed "s|  $release/|  |" >> "$release/checksums_sha256.txt"
done
jq -n --arg version "$version" --arg archive "${archive##*/}" --arg archiveSha "$(sha256sum "$archive" | cut -d ' ' -f1)" \
  --arg deb "${deb##*/}" --arg debSha "$(sha256sum "$deb" | cut -d ' ' -f1)" \
  --arg rpm "${rpm##*/}" --arg rpmSha "$(sha256sum "$rpm" | cut -d ' ' -f1)" \
  --arg appimage "${appimage##*/}" --arg appimageSha "$(sha256sum "$appimage" | cut -d ' ' -f1)" \
  --arg recipeSha "$(sha256sum "$recipe" | cut -d ' ' -f1)" --arg srcinfoSha "$(sha256sum "$srcinfo" | cut -d ' ' -f1)" \
  '{version:$version,archive:$archive,archive_sha256:$archiveSha,deb:$deb,deb_sha256:$debSha,rpm:$rpm,rpm_sha256:$rpmSha,appimage:$appimage,appimage_sha256:$appimageSha,linux_homebrew_cask:"modconductor.rb",aur_recipe:"modconductor-bin.PKGBUILD",aur_recipe_sha256:$recipeSha,aur_srcinfo:"modconductor-bin.SRCINFO",aur_srcinfo_sha256:$srcinfoSha,signature:"unsigned-local-verification-only"}' > "$metadata/modconductor-linux-x64.json"
