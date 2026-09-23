#!/bin/sh
set -eu

appdir=/work/AppDir
tools=/tool-cache
export TMPDIR=/work/tmp HOME=/work/home ARCH=x86_64
export PATH="$tools:$PATH"
export LD_LIBRARY_PATH="$appdir/usr/lib/modconductor/app/modconductor/lib"
export DEPLOY_GTK_VERSION=3

"$tools/linuxdeploy-x86_64.AppImage" --appimage-extract-and-run \
  --appdir "$appdir" \
  --deploy-deps-only "$appdir/usr/lib/modconductor/app/modconductor" \
  --library /usr/lib/x86_64-linux-gnu/libsecret-1.so.0 \
  --library /usr/lib/x86_64-linux-gnu/libssl.so.3 \
  --library /usr/lib/x86_64-linux-gnu/libunwind.so.8 \
  --library /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 \
  --library /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 \
  --library /usr/lib/x86_64-linux-gnu/libfribidi.so.0 \
  --library /usr/lib/x86_64-linux-gnu/libfreetype.so.6 \
  --library /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 \
  --library /usr/lib/x86_64-linux-gnu/libicui18n.so.74 \
  --executable /usr/bin/gsettings \
  --executable /usr/bin/gio \
  --desktop-file "$appdir/usr/share/applications/dev.modconductor.mod_conductor.desktop" \
  --icon-file "$appdir/usr/share/icons/hicolor/256x256/apps/dev.modconductor.mod_conductor.png" \
  --custom-apprun /work/AppRun.sh \
  --plugin gtk

cp /work/AppRun.sh "$appdir/AppRun"
chmod 755 "$appdir/AppRun"
cp /usr/bin/xdg-open /usr/bin/xdg-mime "$appdir/usr/bin/"
mkdir -p "$appdir/usr/share/fonts/truetype/dejavu" "$appdir/etc/fonts"
cp /usr/share/fonts/truetype/dejavu/*.ttf "$appdir/usr/share/fonts/truetype/dejavu/"
cp -a /usr/share/icons/Adwaita "$appdir/usr/share/icons/"
cp -a /usr/share/mime "$appdir/usr/share/"
cp /work/fonts.conf "$appdir/etc/fonts/fonts.conf"

python3 /work/bundled-notices.py "$appdir"

unset LD_LIBRARY_PATH
"$tools/appimagetool-x86_64.AppImage" --appimage-extract-and-run \
  --runtime-file "$tools/runtime-x86_64" \
  "$appdir" /work/modconductor.AppImage
