#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
mkdir -p .agent-workspace
work=$(mktemp -d "$PWD/.agent-workspace/linux-smoke-test.XXXXXXXX")
trap 'find "$work" -depth -delete' EXIT
payload="$work/payload"
engine="$payload/app/modconductor/engine/ModConductor.Engine"
launcher="$payload/bin/modconductor"
mkdir -p "$(dirname "$engine")" "$(dirname "$launcher")" "$payload/share/doc/modconductor"
cat > "$work/engine.c" <<'C'
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    sleep((unsigned int)atoi(argv[1]));
    return 0;
}
C
cc "$work/engine.c" -o "$engine"
cat > "$launcher" <<'LAUNCHER'
#!/usr/bin/env bash
mkdir -p "$XDG_DATA_HOME"
touch "$XDG_DATA_HOME/state.db"
"$(dirname "$0")/../app/modconductor/engine/ModConductor.Engine" "$ENGINE_DURATION" &
wait
LAUNCHER
chmod 755 "$launcher"
printf '{"linux_rid":"linux-x64"}\n' > "$payload/share/doc/modconductor/provenance.json"
printf '{"packages":[{"versionInfo":"0.1.0"}]}\n' > "$payload/share/doc/modconductor/sbom.spdx.json"
ENGINE_DURATION=10 bash tools/smoke-desktop-package.sh "$launcher" --version 0.1.0
if ENGINE_DURATION=1 bash tools/smoke-desktop-package.sh "$launcher" --version 0.1.0 > "$work/failure.log" 2>&1; then
  echo "Short-lived engine passed the bounded liveness check" >&2
  exit 1
fi
grep -Fq 'exited during the startup check' "$work/failure.log"
if pgrep -f "$engine" >/dev/null; then
  echo "Package smoke left a fixture engine running" >&2
  exit 1
fi
