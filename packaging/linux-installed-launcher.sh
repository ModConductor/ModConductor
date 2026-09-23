#!/bin/sh
if [ "$#" -eq 1 ]; then
  case "$1" in
    [nN][xX][mM]://*) exec /usr/lib/modconductor/bin/modconductor --uri "$1" ;;
  esac
fi
exec /usr/lib/modconductor/bin/modconductor "$@"
