param(
  [Parameter(Mandatory)][string]$FlutterBundle,
  [Parameter(Mandatory)][string]$EnginePublish,
  [Parameter(Mandatory)][string]$LootHelper,
  [Parameter(Mandatory)][string]$Makensis,
  [Parameter(Mandatory)][string]$Version,
  [Parameter(Mandatory)][string]$SourceRevision,
  [Parameter(Mandatory)][string]$Output
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$FlutterBundle = (Resolve-Path $FlutterBundle).Path
$EnginePublish = (Resolve-Path $EnginePublish).Path
$LootHelper = (Resolve-Path $LootHelper).Path
$Output = [IO.Path]::GetFullPath($Output)
if (Test-Path $Output) { throw "Package output exists: $Output" }
if (!(Test-Path "$FlutterBundle/mod_conductor.exe") -or !(Test-Path "$FlutterBundle/data/flutter_assets")) { throw 'Flutter release bundle missing' }
if ((& $Makensis /VERSION).TrimStart('v') -ne '3.12') { throw 'NSIS 3.12 required' }
function Copy-Required([string]$source, [string]$destination) {
  if (!(Test-Path $source -PathType Leaf)) { throw "Required package asset missing: $source" }
  New-Item -ItemType Directory -Force (Split-Path $destination) | Out-Null
  Copy-Item $source $destination
}
function Hash([string]$path) { (Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Write-Json([object]$value, [string]$path) {
  $value | ConvertTo-Json -Depth 30 | Set-Content -Encoding utf8NoBOM $path
}
function Files([string]$directory) {
  Get-ChildItem $directory -File -Recurse | Sort-Object { [IO.Path]::GetRelativePath($directory, $_.FullName).Replace('\','/') }
}
New-Item -ItemType Directory -Force $Output | Out-Null
$payload = Join-Path $Output 'payload'
Copy-Item $FlutterBundle $payload -Recurse
foreach ($name in @('ModConductor.Engine.exe','e_sqlite3.dll','ModConductor.Engine.staticwebassets.endpoints.json')) {
  Copy-Required (Join-Path $EnginePublish $name) (Join-Path $payload "engine/$name")
}
Copy-Required $LootHelper "$payload/engine/modconductor-loot-helper.exe"
Copy-Required "$root/third_party/xdelta3/xdelta3-win-x64.exe" "$payload/engine/xdelta3.exe"
Copy-Required "$root/LICENSE" "$payload/LICENSE"
Copy-Required "$root/docs/SOURCE.md" "$payload/notices/SOURCE.md"
Copy-Item "$root/docs/third-party/*" "$payload/notices" -Recurse -Force
Copy-Required "$root/ui/packages/mc_ui_foundation/notices/Roboto-LICENSE.txt" "$payload/notices/Roboto-LICENSE.txt"
Copy-Required "$root/third_party/xdelta3/LICENSE" "$payload/notices/xdelta3-LICENSE.txt"
Copy-Required "$root/third_party/xdelta3/README.md" "$payload/notices/xdelta3-README.md"
$inputs = Join-Path $Output 'dependency-manifests'
$manifests = @('ui/pubspec.lock','native/ModConductor.Loot.Helper/Cargo.lock','.config/flutter-sdk.json','global.json') +
  @(Get-ChildItem src,tests -Filter packages.lock.json -Recurse | ForEach-Object { [IO.Path]::GetRelativePath($root, $_.FullName) })
foreach ($source in $manifests) { Copy-Required "$root/$source" "$inputs/$source" }
$inventory = @(Files $payload | ForEach-Object {
  [ordered]@{ path = [IO.Path]::GetRelativePath($payload, $_.FullName).Replace('\','/'); sha256 = Hash $_.FullName }
})
$manifest = Join-Path $Output 'payload-sha256.json'
Write-Json $inventory $manifest
$manifestHash = Hash $manifest
$created = [DateTimeOffset]::FromUnixTimeSeconds([long](git log -1 --format=%ct)).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')
$files = @()
$relationships = @([ordered]@{ spdxElementId='SPDXRef-DOCUMENT'; relatedSpdxElement='SPDXRef-ModConductor'; relationshipType='DESCRIBES' })
for ($index=0; $index -lt $inventory.Count; $index++) {
  $item=$inventory[$index]; $id="SPDXRef-File-$index"
  $files += [ordered]@{ fileName="./$($item.path)"; SPDXID=$id; checksums=@([ordered]@{algorithm='SHA256';checksumValue=$item.sha256}); licenseConcluded='NOASSERTION'; copyrightText='NOASSERTION' }
  $relationships += [ordered]@{ spdxElementId='SPDXRef-ModConductor'; relatedSpdxElement=$id; relationshipType='CONTAINS' }
}
$sbom = [ordered]@{
  spdxVersion='SPDX-2.3'; dataLicense='CC0-1.0'; SPDXID='SPDXRef-DOCUMENT'
  name="ModConductor-Windows-x64-$Version"; documentNamespace="https://modconductor.invalid/spdx/windows/$Version/$manifestHash"
  creationInfo=[ordered]@{created=$created;creators=@('Tool: tools/package-windows.ps1')}
  packages=@([ordered]@{name='Mod Conductor';SPDXID='SPDXRef-ModConductor';versionInfo=$Version;downloadLocation='NOASSERTION';filesAnalyzed=$true;licenseConcluded='NOASSERTION';licenseDeclared='GPL-3.0-or-later';copyrightText='NOASSERTION'})
  files=$files; relationships=$relationships
}
Write-Json $sbom "$Output/sbom.spdx.json"
Write-Json ([ordered]@{source_revision=$SourceRevision;source_is_scoped_bundle=$false;source_worktree_dirty=$false;flutter_sdk='3.47.4';windows_rid='win-x64';installer_builder='NSIS 3.12';signature='unsigned-local-verification-only';payload_manifest_sha256=$manifestHash}) "$Output/provenance.json"
$deletes = @(Files $payload | ForEach-Object { 'Delete "$INSTDIR\' + [IO.Path]::GetRelativePath($payload, $_.FullName) + '"' })
$directories = @(Files $payload | ForEach-Object {
  $parent = [IO.Path]::GetDirectoryName([IO.Path]::GetRelativePath($payload, $_.FullName))
  while ($parent) { $parent; $parent = [IO.Path]::GetDirectoryName($parent) }
} | Sort-Object -Unique | Sort-Object { $_.Split('\').Count } -Descending)
$deletes += @($directories | ForEach-Object { 'RMDir "$INSTDIR\' + $_ + '"' })
$deletes += 'RMDir "$INSTDIR"'
$deletes | Set-Content -Encoding utf8NoBOM "$Output/uninstall-files.nsh"
$portable = "$Output/ModConductor-$Version-win-x64-portable.zip"
Add-Type -AssemblyName System.IO.Compression
$zip = [IO.Compression.ZipFile]::Open($portable, 'Create')
try {
  foreach ($file in (Files $payload)) {
    $relative = [IO.Path]::GetRelativePath($payload, $file.FullName).Replace('\','/')
    $entry = $zip.CreateEntry("ModConductor/$relative", [IO.Compression.CompressionLevel]::Optimal)
    $entry.LastWriteTime = [DateTimeOffset]::Parse('1980-01-01T00:00:00Z')
    $input = $file.OpenRead(); $outputStream = $entry.Open()
    try { $input.CopyTo($outputStream) } finally { $input.Dispose(); $outputStream.Dispose() }
  }
} finally { $zip.Dispose() }
$installer = "$Output/ModConductor-$Version-win-x64-setup.exe"
$nsisArguments = @(
  "/DPAYLOAD=$payload", "/DUNINSTALL_FILES=$Output/uninstall-files.nsh",
  "/DOUTPUT=$installer", "/DVERSION=$Version",
  "/DAPP_ICON=$root/ui/apps/mod_conductor/windows/runner/resources/app_icon.ico",
  "$root/tools/windows-installer.nsi"
)
& $Makensis @nsisArguments
if ($LASTEXITCODE -ne 0) { throw 'NSIS installer build failed' }
@("$((Hash $installer))  $(Split-Path $installer -Leaf)","$((Hash $portable))  $(Split-Path $portable -Leaf)") | Set-Content -Encoding ascii "$Output/SHA256SUMS"
