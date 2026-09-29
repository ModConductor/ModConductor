param(
  [Parameter(Mandatory)][string]$Rid,
  [Parameter(Mandatory)][string]$PublishDirectory,
  [Parameter(Mandatory)][string]$Version,
  [Parameter(Mandatory)][string]$Revision
)
$ErrorActionPreference = 'Stop'
if ($Rid -ne 'win-x64' -or [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne 'X64') { throw 'Native Windows x64 required' }
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
if (Test-Path $PublishDirectory) { throw "Package output already exists: $PublishDirectory" }
$productVersion = ([regex]::Match((Get-Content ui/apps/mod_conductor/pubspec.yaml -Raw), '(?m)^version: (\d+\.\d+\.\d+)')).Groups[1].Value
if ($productVersion -ne $Version) { throw "Product version $productVersion differs from $Version" }
if ((dotnet --version) -ne '10.0.400') { throw '.NET SDK 10.0.400 required' }
if ((git rev-parse HEAD).Trim() -ne $Revision) { throw 'Source revision mismatch' }
rustup toolchain install 1.89.0 --profile minimal
if ($LASTEXITCODE -ne 0) { throw 'Rust toolchain installation failed' }
$flutterConfig = Get-Content .config/flutter-sdk.json -Raw | ConvertFrom-Json
$flutter = Join-Path $root '.tools/flutter/bin/flutter.bat'
if (!(Test-Path $flutter)) {
  New-Item -ItemType Directory -Force .tools | Out-Null
  $archive = Join-Path $root '.tools/flutter.zip'
  Invoke-WebRequest $flutterConfig.windows.url -OutFile $archive
  if ((Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $flutterConfig.windows.sha256) { throw 'Flutter archive checksum mismatch' }
  Expand-Archive $archive -DestinationPath .tools
  Remove-Item $archive
}
& $flutter --version
if ($LASTEXITCODE -ne 0) { throw 'Flutter bootstrap failed' }
$flutterDetails = (& $flutter --version --machine | Out-String | ConvertFrom-Json)
if ($flutterDetails.frameworkVersion -ne '3.47.4' -or !$flutterDetails.dartSdkVersion.StartsWith('3.13.3')) { throw 'Pinned Flutter/Dart version mismatch' }
$nsisArchive = Join-Path $root '.tools/nsis-3.12.zip'
$nsis = Join-Path $root '.tools/nsis/nsis-3.12/makensis.exe'
if (!(Test-Path $nsis)) {
  Invoke-WebRequest 'https://downloads.sourceforge.net/project/nsis/NSIS%203/3.12/nsis-3.12.zip' -OutFile $nsisArchive
  if ((Get-FileHash $nsisArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne '56581f90db321581c5381193d796fffcf2d24b2f8fed2160a6c6a3baa67f2c4f') { throw 'NSIS archive checksum mismatch' }
  Expand-Archive $nsisArchive -DestinationPath .tools/nsis
}
if ((& $nsis /VERSION).TrimStart('v') -ne '3.12') { throw 'NSIS 3.12 required' }
New-Item -ItemType Directory -Force .agent-workspace | Out-Null
$work = Join-Path $root ('.agent-workspace/windows-package-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $work | Out-Null
try {
  $env:CARGO_TARGET_DIR = Join-Path $work 'cargo-target'
  dotnet restore src/ModConductor.Engine/ModConductor.Engine.fsproj --locked-mode
  if ($LASTEXITCODE -ne 0) { throw 'Engine restore failed' }
  $engine = Join-Path $work 'engine'
  dotnet publish src/ModConductor.Engine/ModConductor.Engine.fsproj -c Release -r win-x64 --self-contained true --no-restore -p:ModConductorLocalPublishVerificationOnly=true -o $engine
  if ($LASTEXITCODE -ne 0) { throw 'Engine publish failed' }
  Push-Location ui/apps/mod_conductor
  try {
    & $flutter clean
    if ($LASTEXITCODE -ne 0) { throw 'Flutter clean failed' }
    & $flutter pub get --enforce-lockfile
    if ($LASTEXITCODE -ne 0) { throw 'Flutter restore failed' }
    & $flutter build windows --release --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Flutter build failed' }
  } finally { Pop-Location }
  Push-Location native/ModConductor.Loot.Helper
  try {
    cargo +1.89.0 build --locked --release --target x86_64-pc-windows-msvc
    if ($LASTEXITCODE -ne 0) { throw 'LOOT helper build failed' }
  } finally { Pop-Location }
  & "$PSScriptRoot/package-windows.ps1" -FlutterBundle 'ui/apps/mod_conductor/build/windows/x64/runner/Release' -EnginePublish $engine -LootHelper (Join-Path $work 'cargo-target/x86_64-pc-windows-msvc/release/modconductor-loot-helper.exe') -Makensis $nsis -Version $Version -SourceRevision $Revision -Output $PublishDirectory
} finally {
  Remove-Item $work -Recurse -Force
}
