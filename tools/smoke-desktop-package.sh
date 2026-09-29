#!/usr/bin/env bash
set -euo pipefail
launcher=$1
[[ $2 == --version && -n $3 ]] || exit 2
version=$3
appimage=false close_window=false
for argument in "${@:4}"; do
  case "$argument" in
    --appimage) appimage=true ;;
    --close-window) close_window=true ;;
    *) echo "Unknown smoke option: $argument" >&2; exit 2 ;;
  esac
done
if $appimage; then
  [[ -f $launcher && ${launcher##*/} == "modconductor-$version-linux-x64.AppImage" ]] || { echo "Expected installed AppImage" >&2; exit 1; }
  export APPIMAGE_EXTRACT_AND_RUN=1
else
  payload=$(cd "$(dirname "$launcher")/.." && pwd)
  [[ -x $launcher && -x $payload/app/modconductor/engine/ModConductor.Engine ]] || { echo "Incomplete Linux desktop payload" >&2; exit 1; }
  [[ $(jq -r .linux_rid "$payload/share/doc/modconductor/provenance.json") == linux-x64 ]] || exit 1
  [[ $(jq -r '.packages[0].versionInfo' "$payload/share/doc/modconductor/sbom.spdx.json") == "$version" ]] || exit 1
fi
find_descendant() {
  local parent=$1 name=$2 child found
  [[ $(basename "$(readlink "/proc/$parent/exe" 2>/dev/null)" 2>/dev/null) == "$name" ]] && { echo "$parent"; return 0; }
  for child in $(pgrep -P "$parent" || :); do
    found=$(find_descendant "$child" "$name") && { echo "$found"; return 0; }
  done
  return 1
}
mkdir -p .agent-workspace
work=$(mktemp -d "$PWD/.agent-workspace/package-smoke.XXXXXXXX")
socket=$(mktemp -d "$PWD/.agent-workspace/s.XXXXXXXX")
display=
for number in {140..199}; do
  if [[ ! -e /tmp/.X11-unix/X$number && ! -e /tmp/.X$number-lock ]]; then display=$number; break; fi
done
[[ -n $display ]] || { echo "No private display available" >&2; exit 1; }
xvfb_pid='' frontend_pid=''
# shellcheck disable=SC2329
cleanup() {
  [[ -z $frontend_pid ]] || kill -- -"$frontend_pid" 2>/dev/null || :
  [[ -z $xvfb_pid ]] || kill "$xvfb_pid" 2>/dev/null || :
  rm -rf "$work" "$socket"
}
trap cleanup EXIT
mkdir -p "$work"/{home,config,cache,data,runtime}
chmod 700 "$work/runtime"
ulimit -c 0
Xvfb ":$display" -screen 0 1280x800x24 -nolisten tcp >"$work/xvfb.log" 2>&1 &
xvfb_pid=$!
for attempt in {1..100}; do
  [[ -S /tmp/.X11-unix/X$display ]] && break
  kill -0 "$xvfb_pid" || { cat "$work/xvfb.log"; exit 1; }
  sleep .1
done
[[ -S /tmp/.X11-unix/X$display ]] || exit 1
export DISPLAY=:$display GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=true
export GSETTINGS_BACKEND=memory GTK_USE_PORTAL=0
export DBUS_SESSION_BUS_ADDRESS="unix:path=$work/no-session-bus"
export HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache"
export XDG_DATA_HOME="$work/data" XDG_RUNTIME_DIR="$work/runtime" TMPDIR="$socket"
unset WAYLAND_DISPLAY
setsid "$launcher" >"$work/application.log" 2>&1 &
frontend_pid=$!
for ((attempt=0; attempt<150; attempt++)); do
  kill -0 "$frontend_pid" || { cat "$work/application.log"; echo "Desktop exited before startup" >&2; exit 1; }
  backend=$(find_descendant "$frontend_pid" ModConductor.Engine || :)
  if find "$work/data" -name state.db -print -quit | grep -q . && [[ -n $backend ]]; then
    if $close_window; then
      desktop_pid=$frontend_pid
      $appimage && desktop_pid=$(find_descendant "$frontend_pid" mod_conductor)
      mapfile -t windows < <(xdotool search --onlyvisible --pid "$desktop_pid")
      [[ ${#windows[@]} -eq 1 ]] || { echo "Expected one desktop window" >&2; exit 1; }
      xdotool windowclose "${windows[0]}"
      for ((close_attempt=0; close_attempt<100; close_attempt++)); do
        kill -0 "$frontend_pid" 2>/dev/null || break
        sleep .1
      done
      kill -0 "$frontend_pid" 2>/dev/null && { echo "Desktop did not close" >&2; exit 1; }
      for close_attempt in {1..100}; do
        [[ -e /proc/$backend ]] || break
        sleep .1
      done
      [[ ! -e /proc/$backend ]] || { echo "Engine remained after desktop closed" >&2; exit 1; }
    fi
    echo "Linux desktop and bundled engine started with private state"
    exit 0
  fi
  sleep .2
done
cat "$work/application.log"
echo "Desktop did not start its bundled engine and private state" >&2
exit 1
