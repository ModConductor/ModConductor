#!/bin/sh
here=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export APPDIR="${APPDIR:-$here}"
export PATH="$APPDIR/usr/bin:$PATH"
export LD_LIBRARY_PATH="$APPDIR/usr/lib:$APPDIR/usr/lib/modconductor/app/modconductor/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export FONTCONFIG_FILE="$APPDIR/etc/fonts/fonts.conf"
. "$APPDIR/apprun-hooks/linuxdeploy-plugin-gtk.sh"
exec "$APPDIR/usr/lib/modconductor/bin/modconductor" "$@"
