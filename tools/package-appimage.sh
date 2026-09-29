#!/usr/bin/env bash
set -euo pipefail
archive=$1 output=$2 version=$3
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
mkdir -p .agent-workspace .tools/appimage-tools "$(dirname "$output")"
work=$(mktemp -d "$PWD/.agent-workspace/appimage.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
tar -xzf "$archive" -C "$work"
mapfile -t launchers < <(find "$work" -path '*/bin/modconductor' -type f)
[[ ${#launchers[@]} -eq 1 ]] || { echo "Expected one Linux payload" >&2; exit 1; }
payload=$(dirname "$(dirname "${launchers[0]}")")
[[ $(jq -r '.packages[0].versionInfo' "$payload/share/doc/modconductor/sbom.spdx.json") == "$version" ]] || { echo "AppImage version mismatch" >&2; exit 1; }
app="$work/AppDir/usr/lib/modconductor"
mkdir -p "$app" "$work/AppDir/usr/bin" "$work/AppDir/usr/share/applications" "$work/AppDir/usr/share/mime/packages" "$work/AppDir/usr/share/icons"
cp -a "$payload/." "$app/"
install -m755 packaging/appimage/modconductor.sh "$work/AppDir/usr/bin/modconductor"
cp "$payload/share/applications/dev.modconductor.mod_conductor.desktop" "$work/AppDir/usr/share/applications/"
cp "$payload/share/mime/packages/modconductor-profile.xml" "$work/AppDir/usr/share/mime/packages/"
cp -a "$payload/share/icons/hicolor" "$work/AppDir/usr/share/icons/"
cp docs/third-party/appimage-runtime-LICENSE.txt docs/third-party/linuxdeploy-plugin-gtk-LICENSE.txt "$app/share/doc/modconductor/third-party/"
cp packaging/appimage/AppRun.sh packaging/appimage/fonts.conf tools/appimage-package/build.sh tools/appimage-package/bundled-notices.sh "$work/"
mkdir -p "$work/home" "$work/tmp"
bash tools/bootstrap-appimage-tools.sh
docker build -t modconductor-appimage-tools:local -f tools/appimage-package/Dockerfile tools/appimage-package
docker run --rm --init --network none --user "$(id -u):$(id -g)" -v "$work:/work" \
  -v "$root/.tools/appimage-tools:/tool-cache:ro" -w /work modconductor-appimage-tools:local sh /work/build.sh
mv "$work/modconductor.AppImage" "$output"
chmod 755 "$output"
