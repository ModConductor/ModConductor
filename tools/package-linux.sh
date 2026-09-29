#!/usr/bin/env bash
set -euo pipefail
publish_directory='' version='' revision='' work_directory=''
while (($#)); do
  case "$1" in
    --publish-directory) publish_directory=$2 ;;
    --version) version=$2 ;;
    --revision) revision=$2 ;;
    --work-directory) work_directory=$2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift 2
done
[[ -n $publish_directory && -n $version && -n $revision && -n $work_directory ]] || exit 2
[[ $(uname -m) == x86_64 ]] || { echo "Linux x64 required" >&2; exit 1; }
[[ ! -e $publish_directory ]] || { echo "Package output already exists" >&2; exit 1; }
[[ $(dotnet --version) == 10.0.400 && $(rustc --version) == rustc\ 1.89.0* ]] || { echo "Pinned .NET and Rust required" >&2; exit 1; }
flutter --version
[[ $(flutter --version --machine | jq -r .frameworkVersion) == 3.47.4 ]] || { echo "Flutter 3.47.4 required" >&2; exit 1; }
[[ $(sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' ui/apps/mod_conductor/pubspec.yaml) == "$version" ]] || { echo "Product version mismatch" >&2; exit 1; }
mkdir -p "$work_directory"
export CARGO_TARGET_DIR="$work_directory/cargo-target"
dotnet restore src/ModConductor.Engine/ModConductor.Engine.fsproj --locked-mode
dotnet publish src/ModConductor.Engine/ModConductor.Engine.fsproj -c Release -r linux-x64 --self-contained true --no-restore -p:ModConductorLocalPublishVerificationOnly=true -o "$work_directory/engine"
(
  cd ui/apps/mod_conductor
  flutter clean
  flutter pub get --enforce-lockfile
  flutter build linux --release --no-pub
)
(cd native/ModConductor.Loot.Helper && cargo +1.89.0 build --locked --release)
bundle=ui/apps/mod_conductor/build/linux/x64/release/bundle
engine="$work_directory/engine"
helper="$work_directory/cargo-target/release/modconductor-loot-helper"
for executable in "$bundle/mod_conductor" "$engine/ModConductor.Engine" "$helper"; do
  [[ -x $executable ]] || { echo "Missing executable $executable" >&2; exit 1; }
  elf=$(readelf -l -d "$executable") || { echo "Cannot read ELF metadata: $executable" >&2; exit 1; }
  if grep -E 'interpreter:|RPATH|RUNPATH' <<<"$elf" | grep -q /nix/store/; then
    echo "Nix-linked runtime: $executable" >&2
    exit 1
  fi
done
[[ -d $bundle/data/flutter_assets ]] || { echo "Flutter bundle missing" >&2; exit 1; }
for library in "$bundle"/lib/*.so; do
  elf=$(readelf -d "$library") || { echo "Cannot read ELF metadata: $library" >&2; exit 1; }
  if grep -E 'RPATH|RUNPATH' <<<"$elf" | grep -q /nix/store/; then
    echo "Nix-linked runtime library: $library" >&2
    exit 1
  fi
done
app="$publish_directory/app/modconductor"
mkdir -p "$app/engine"
cp -a "$bundle/." "$app/"
patchelf --remove-rpath "$app/lib/libfile_selector_linux_plugin.so"
cp "$engine/ModConductor.Engine" "$engine/libe_sqlite3.so" "$engine/ModConductor.Engine.staticwebassets.endpoints.json" "$app/engine/"
cp "$helper" "$app/engine/modconductor-loot-helper"
cp third_party/xdelta3/xdelta3-linux-x64 "$app/engine/xdelta3"
chmod 755 "$app/mod_conductor" "$app/engine/ModConductor.Engine" "$app/engine/modconductor-loot-helper" "$app/engine/xdelta3"
install -Dm755 packaging/linux-launcher.sh "$publish_directory/bin/modconductor"
install -Dm644 packaging/dev.modconductor.mod_conductor.desktop "$publish_directory/share/applications/dev.modconductor.mod_conductor.desktop"
install -Dm644 packaging/modconductor-profile.xml "$publish_directory/share/mime/packages/modconductor-profile.xml"
for size in 48 256; do
  install -Dm644 "packaging/icons/hicolor/${size}x${size}/apps/dev.modconductor.mod_conductor.png" \
    "$publish_directory/share/icons/hicolor/${size}x${size}/apps/dev.modconductor.mod_conductor.png"
done
doc="$publish_directory/share/doc/modconductor"
mkdir -p "$doc/third-party"
cp LICENSE docs/SOURCE.md "$doc/"
cp -a docs/third-party/. "$doc/third-party/"
cp ui/packages/mc_ui_foundation/notices/Roboto-LICENSE.txt "$doc/third-party/"
cp third_party/xdelta3/LICENSE "$doc/third-party/xdelta3-LICENSE.txt"
cp third_party/xdelta3/README.md "$doc/third-party/xdelta3-README.md"
while IFS= read -r source; do
  install -Dm644 "$source" "$doc/dependency-manifests/$source"
done < <(printf '%s\n' ui/pubspec.lock native/ModConductor.Loot.Helper/Cargo.lock .config/flutter-sdk.json global.json; find src tests -name packages.lock.json -print | sort)
manifest="$doc/payload-sha256.json"
manifest_tmp="$work_directory/payload-sha256.json"
find "$publish_directory" -type f -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' file; do
  jq -n --arg path "${file#"$publish_directory"/}" --arg sha "$(sha256sum "$file" | cut -d ' ' -f1)" '{path:$path,sha256:$sha}'
done | jq -s . > "$manifest_tmp"
mv "$manifest_tmp" "$manifest"
manifest_sha=$(sha256sum "$manifest" | cut -d ' ' -f1)
created=$(date -u -d "@$(git log -1 --format=%ct)" +%Y-%m-%dT%H:%M:%SZ)
jq -n --slurpfile inventory "$manifest" --arg version "$version" --arg sha "$manifest_sha" --arg created "$created" \
  '{spdxVersion:"SPDX-2.3",dataLicense:"CC0-1.0",SPDXID:"SPDXRef-DOCUMENT",name:("ModConductor-Linux-x64-"+$version),documentNamespace:("https://modconductor.invalid/spdx/linux/"+$version+"/"+$sha),creationInfo:{created:$created,creators:["Tool: tools/package-linux.sh"]},packages:[{name:"Mod Conductor",SPDXID:"SPDXRef-ModConductor",versionInfo:$version,downloadLocation:"NOASSERTION",filesAnalyzed:true,licenseConcluded:"NOASSERTION",licenseDeclared:"GPL-3.0-or-later",copyrightText:"NOASSERTION"}],files:($inventory[0]|to_entries|map({fileName:("./"+.value.path),SPDXID:("SPDXRef-File-"+(.key|tostring)),checksums:[{algorithm:"SHA256",checksumValue:.value.sha256}],licenseConcluded:"NOASSERTION",copyrightText:"NOASSERTION"})),relationships:([{spdxElementId:"SPDXRef-DOCUMENT",relatedSpdxElement:"SPDXRef-ModConductor",relationshipType:"DESCRIBES"}]+($inventory[0]|to_entries|map({spdxElementId:"SPDXRef-ModConductor",relatedSpdxElement:("SPDXRef-File-"+(.key|tostring)),relationshipType:"CONTAINS"})))}' > "$doc/sbom.spdx.json"
jq -n --arg revision "$revision" --arg sha "$manifest_sha" \
  '{source_revision:$revision,linux_rid:"linux-x64",flutter_sdk:"3.47.4",dotnet_sdk:"10.0.400",rust_toolchain:"1.89.0",signature:"unsigned-local-verification-only",payload_manifest_sha256:$sha}' > "$doc/provenance.json"
