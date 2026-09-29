#!/usr/bin/env bash
set -euo pipefail
version=$1 release=$2 metadata=$3
archive="$release/modconductor-v$version-win-x64.zip"
[[ -f $archive ]] || { echo "Missing Windows archive: $archive" >&2; exit 1; }
source="artifacts/publish/win-x64"
installer="$release/ModConductor-$version-win-x64-setup.exe"
[[ -f $installer ]] || cp "$source/${installer##*/}" "$installer"
executable=$(unzip -Z1 "$archive" | awk '$0 == "mod_conductor.exe" || $0 ~ /\/mod_conductor.exe$/ {print}')
[[ $(printf '%s\n' "$executable" | wc -l) -eq 1 && -n $executable ]] || { echo "Expected one Windows desktop executable" >&2; exit 1; }
archive_sha=$(sha256sum "$archive" | cut -d ' ' -f1)
installer_sha=$(sha256sum "$installer" | cut -d ' ' -f1)
archive_url="https://github.com/alsi-lawr/ModConductor/releases/download/v$version/${archive##*/}"
installer_url="https://github.com/alsi-lawr/ModConductor/releases/download/v$version/${installer##*/}"
archive_stem=${archive##*/}
archive_stem=${archive_stem%.zip}
mkdir -p "$metadata/scoop" "$metadata/chocolatey/tools" "$metadata/manifests/a/alsi-lawr/ModConductor/$version"
jq -n --arg version "$version" --arg url "$archive_url" --arg hash "$archive_sha" --arg executable "${executable//\//\\}" \
  '{version:$version,description:"Desktop mod organiser",homepage:"https://github.com/alsi-lawr/ModConductor",architecture:{"64bit":{url:$url,hash:$hash}},bin:[[$executable,"modconductor"]],shortcuts:[[$executable,"Mod Conductor"]]}' > "$metadata/scoop/modconductor.json"
cat > "$metadata/chocolatey/modconductor.nuspec" <<NUSPEC
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>modconductor</id>
    <version>$version</version>
    <authors>Mod Conductor contributors</authors>
    <projectUrl>https://github.com/alsi-lawr/ModConductor</projectUrl>
    <description>Desktop mod organiser</description>
  </metadata>
  <files><file src="tools\**" target="tools" /></files>
</package>
NUSPEC
cat > "$metadata/chocolatey/tools/chocolateyInstall.ps1" <<CHOCO
\$ErrorActionPreference = 'Stop'
\$tools = Split-Path -Parent \$MyInvocation.MyCommand.Definition
Install-ChocolateyZipPackage -PackageName 'modconductor' -Url '$archive_url' -UnzipLocation \$tools -Checksum '$archive_sha' -ChecksumType 'sha256'
\$engine = Join-Path \$tools '$archive_stem\engine'
New-Item -ItemType File -Path (Join-Path \$engine 'ModConductor.Engine.exe.ignore') -Force | Out-Null
New-Item -ItemType File -Path (Join-Path \$engine 'modconductor-loot-helper.exe.ignore') -Force | Out-Null
CHOCO
winget="$metadata/manifests/a/alsi-lawr/ModConductor/$version"
cat > "$winget/alsi-lawr.ModConductor.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.version.1.9.0.schema.json

PackageIdentifier: alsi-lawr.ModConductor
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.9.0
YAML
cat > "$winget/alsi-lawr.ModConductor.installer.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.installer.1.9.0.schema.json

PackageIdentifier: alsi-lawr.ModConductor
PackageVersion: $version
InstallerType: nullsoft
Scope: user
InstallModes:
  - interactive
  - silent
InstallerSwitches:
  Silent: /S
  SilentWithProgress: /S
UpgradeBehavior: install
ProductCode: ModConductor
AppsAndFeaturesEntries:
  - ProductCode: ModConductor
Installers:
  - Architecture: x64
    InstallerUrl: $installer_url
    InstallerSha256: ${installer_sha^^}
ManifestType: installer
ManifestVersion: 1.9.0
YAML
cat > "$winget/alsi-lawr.ModConductor.locale.en-US.yaml" <<YAML
# yaml-language-server: \$schema=https://aka.ms/winget-manifest.defaultLocale.1.9.0.schema.json

PackageIdentifier: alsi-lawr.ModConductor
PackageVersion: $version
PackageLocale: en-US
Publisher: Mod Conductor contributors
PackageName: Mod Conductor
License: GPL-3.0-or-later
ShortDescription: Desktop mod organiser
PackageUrl: https://github.com/alsi-lawr/ModConductor
ManifestType: defaultLocale
ManifestVersion: 1.9.0
YAML
printf '%s  %s\n' "$installer_sha" "${installer##*/}" >> "$release/checksums_sha256.txt"
for name in payload-sha256.json sbom.spdx.json provenance.json; do
  sidecar="$release/modconductor-v$version-win-x64-$name"
  cp "$source/$name" "$sidecar"
  sha256sum "$sidecar" | sed "s|  $release/|  |" >> "$release/checksums_sha256.txt"
done
[[ -d $source/dependency-manifests ]] || { echo "Missing Windows dependency manifests" >&2; exit 1; }
manifest_archive="$release/modconductor-v$version-win-x64-dependency-manifests.tar"
tar -cf "$manifest_archive" -C "$source" dependency-manifests
sha256sum "$manifest_archive" | sed "s|  $release/|  |" >> "$release/checksums_sha256.txt"
jq -n --arg version "$version" --arg archive "${archive##*/}" --arg archiveSha "$archive_sha" \
  --arg installer "${installer##*/}" --arg installerSha "$installer_sha" \
  '{version:$version,archive:$archive,archive_sha256:$archiveSha,installer:$installer,installer_sha256:$installerSha,signature:"unsigned-local-verification-only"}' > "$metadata/modconductor-windows-x64.json"
