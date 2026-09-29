#!/usr/bin/env bash
set -euo pipefail
output='' version='' revision='' source_date_epoch=''
while (($#)); do
  case "$1" in
    --output) output=$2 ;;
    --version) version=$2 ;;
    --revision) revision=$2 ;;
    --source-date-epoch) source_date_epoch=$2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift 2
done
[[ -d $output && -n $version && -n $revision && $source_date_epoch =~ ^[0-9]+$ ]] || exit 2
documents="$output/share/doc/modconductor"
mkdir -p "$documents"
manifest="$documents/payload-sha256.json"
temporary=$(mktemp)
trap 'rm -f "$temporary"' EXIT
find "$output" \( -type f -o -type l \) -print0 | LC_ALL=C sort -z |
  while IFS= read -r -d '' file; do
    [[ -f $file ]] || continue
    jq -n --arg path "${file#"$output"/}" --arg sha "$(sha256sum "$file" | cut -d ' ' -f1)" \
      '{path:$path,sha256:$sha}'
  done | jq -s . > "$temporary"
mv "$temporary" "$manifest"
manifest_sha=$(sha256sum "$manifest" | cut -d ' ' -f1)
created=$(date -u -d "@$source_date_epoch" +%Y-%m-%dT%H:%M:%SZ)
jq -n --slurpfile inventory "$manifest" --arg version "$version" --arg sha "$manifest_sha" --arg created "$created" \
  '{spdxVersion:"SPDX-2.3",dataLicense:"CC0-1.0",SPDXID:"SPDXRef-DOCUMENT",name:("ModConductor-Nix-x86_64-linux-"+$version),documentNamespace:("https://modconductor.invalid/spdx/nix/"+$version+"/"+$sha),creationInfo:{created:$created,creators:["Tool: nix/write-package-metadata.sh"]},packages:[{name:"Mod Conductor",SPDXID:"SPDXRef-ModConductor",versionInfo:$version,downloadLocation:"NOASSERTION",filesAnalyzed:true,licenseConcluded:"NOASSERTION",licenseDeclared:"GPL-3.0-or-later",copyrightText:"NOASSERTION"}],files:($inventory[0]|to_entries|map({fileName:("./"+.value.path),SPDXID:("SPDXRef-File-"+(.key|tostring)),checksums:[{algorithm:"SHA256",checksumValue:.value.sha256}],licenseConcluded:"NOASSERTION",copyrightText:"NOASSERTION"})),relationships:([{spdxElementId:"SPDXRef-DOCUMENT",relatedSpdxElement:"SPDXRef-ModConductor",relationshipType:"DESCRIBES"}]+($inventory[0]|to_entries|map({spdxElementId:"SPDXRef-ModConductor",relatedSpdxElement:("SPDXRef-File-"+(.key|tostring)),relationshipType:"CONTAINS"})))}' > "$documents/sbom.spdx.json"
jq -n --arg revision "$revision" --arg sha "$manifest_sha" \
  '{source_revision:$revision,nix_system:"x86_64-linux",flutter_sdk:"3.47.4",dotnet_sdk:"10.0.400",signature:"unsigned-local-verification-only",payload_manifest_sha256:$sha}' > "$documents/provenance.json"
