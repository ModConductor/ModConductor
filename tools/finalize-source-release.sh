#!/usr/bin/env bash
set -euo pipefail
version=$1 release=$2 metadata=$3
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
linux="$release/modconductor-v$version-linux-x64.tar.gz"
windows="$release/modconductor-v$version-win-x64-provenance.json"
[[ -f $linux && -f $windows ]] || { echo "Both platform provenance records are required" >&2; exit 1; }
mapfile -t provenance_paths < <(tar -tzf "$linux" | awk '$0 ~ /\/share\/doc\/modconductor\/provenance.json$/')
[[ ${#provenance_paths[@]} -eq 1 ]] || { echo "Expected one Linux provenance record" >&2; exit 1; }
revision=$(tar -xOzf "$linux" "${provenance_paths[0]}" | jq -r .source_revision)
[[ $revision =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid Linux source revision" >&2; exit 1; }
[[ $(jq -r .source_revision "$windows") == "$revision" && $(git rev-parse HEAD) == "$revision" ]] || { echo "Platform and checkout revisions differ" >&2; exit 1; }
name="modconductor-v$version-source"
output="$release/$name.tar.gz"
[[ ! -e $output ]] || { echo "Source archive exists" >&2; exit 1; }
work=$(mktemp -d "$release/source-release.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
vendor="$work/vendor"
cargo +1.89.0 vendor --locked --manifest-path native/ModConductor.Loot.Helper/Cargo.toml "$vendor" > "$work/config.toml"
sed -i "s|$vendor|vendor|g" "$work/config.toml"
grep -F 'directory = "vendor"' "$work/config.toml" >/dev/null
[[ -f $vendor/libloot/Cargo.toml ]] || { echo "Pinned libloot source missing" >&2; exit 1; }
[[ -z $(find "$vendor" -type l -print -quit) ]] || { echo "Vendored source contains symlink" >&2; exit 1; }
raw="$work/source.tar"
git archive --format=tar --prefix="$name/" --output="$raw" "$revision"
printf '%s\n' "$revision" > "$work/SOURCE-REVISION"
mkdir -p "$work/.cargo"
mv "$work/config.toml" "$work/.cargo/config.toml"
tar --append --file="$raw" --owner=0 --group=0 --mtime=@0 --transform="s|^|$name/|" -C "$work" SOURCE-REVISION .cargo/config.toml vendor
gzip -n -9 -c "$raw" > "$output"
sha=$(sha256sum "$output" | cut -d ' ' -f1)
printf '%s  %s\n' "$sha" "${output##*/}" >> "$release/checksums_sha256.txt"
jq -n --arg version "$version" --arg revision "$revision" --arg archive "${output##*/}" --arg sha "$sha" \
  '{version:$version,source_revision:$revision,archive:$archive,archive_sha256:$sha,rust_dependencies:"vendored Cargo.lock closure",signature:"unsigned-local-verification-only"}' > "$metadata/modconductor-source.json"
