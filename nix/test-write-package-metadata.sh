#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
mkdir -p .agent-workspace
work=$(mktemp -d "$PWD/.agent-workspace/nix-metadata-test.XXXXXXXX")
trap 'find "$work" -depth -delete' EXIT
output="$work/output"
mkdir -p "$output/bin" "$output/share/doc/modconductor"
printf 'binary' > "$output/bin/mod_conductor"
ln -s mod_conductor "$output/bin/modconductor"
bash nix/write-package-metadata.sh --output "$output" --version 0.1.0 \
  --revision aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa --source-date-epoch 0
manifest="$output/share/doc/modconductor/payload-sha256.json"
sbom="$output/share/doc/modconductor/sbom.spdx.json"
provenance="$output/share/doc/modconductor/provenance.json"
jq -e 'length == 2 and map(.path) == ["bin/mod_conductor","bin/modconductor"]' "$manifest" >/dev/null
jq -e '.packages[0].versionInfo == "0.1.0" and .creationInfo.created == "1970-01-01T00:00:00Z" and (.files | length) == 2' "$sbom" >/dev/null
jq -e --arg sha "$(sha256sum "$manifest" | cut -d ' ' -f1)" \
  '.source_revision == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" and .payload_manifest_sha256 == $sha' "$provenance" >/dev/null
