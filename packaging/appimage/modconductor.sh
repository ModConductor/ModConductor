#!/bin/sh
app="${APPDIR:?}/usr/lib/modconductor/app/modconductor/mod_conductor"
if [ "$#" -eq 1 ]; then
  case "$1" in
    [nN][xX][mM]://*) exec "$app" --uri "$1" ;;
  esac
fi
exec "$app" "$@"
