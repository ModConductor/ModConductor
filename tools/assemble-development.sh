#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
engine=.tools/publish/linux-x64
bundle=ui/apps/mod_conductor/build/linux/x64/release/bundle
[[ -f $engine/ModConductor.Engine && -d $bundle && -f $engine/libe_sqlite3.so && -f $engine/ModConductor.Engine.staticwebassets.endpoints.json ]] || {
  echo "Publish the engine and build the Flutter bundle first" >&2
  exit 1
}
export CARGO_TARGET_DIR="$root/.tools/loot-helper-target"
(cd native/ModConductor.Loot.Helper && cargo +1.89.0 build --locked --release)
mkdir -p "$bundle/engine"
cp "$engine/ModConductor.Engine" "$engine/libe_sqlite3.so" "$engine/ModConductor.Engine.staticwebassets.endpoints.json" "$bundle/engine/"
cp "$CARGO_TARGET_DIR/release/modconductor-loot-helper" "$bundle/engine/"
