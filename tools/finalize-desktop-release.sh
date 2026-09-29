#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 6 && $1 == --version && $3 == --release-directory && $5 == --metadata-directory ]] || exit 2
version=$2 release=$4 metadata=$6
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
release=$(realpath "$release")
metadata=$(realpath -m "$metadata")
bash tools/finalize-linux-release.sh "$version" "$release" "$metadata"
bash tools/finalize-windows-release.sh "$version" "$release" "$metadata"
bash tools/finalize-source-release.sh "$version" "$release" "$metadata"
