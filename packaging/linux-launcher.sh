#!/bin/sh
base=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ "$#" -eq 1 ]; then
  case "$1" in
    [nN][xX][mM]://*) exec "$base/app/modconductor/mod_conductor" --uri "$1" ;;
  esac
fi
exec "$base/app/modconductor/mod_conductor" "$@"
