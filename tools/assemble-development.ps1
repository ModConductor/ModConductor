$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$engine = '.tools/publish/win-x64'
$bundle = 'ui/apps/mod_conductor/build/windows/x64/runner/Release'
foreach ($path in @("$engine/ModConductor.Engine.exe","$engine/e_sqlite3.dll","$engine/ModConductor.Engine.staticwebassets.endpoints.json",$bundle)) {
  if (!(Test-Path $path)) { throw "Publish the engine and build the Flutter bundle first: $path" }
}
$env:CARGO_TARGET_DIR = Join-Path $root '.tools/loot-helper-target'
Push-Location native/ModConductor.Loot.Helper
try {
  cargo +1.89.0 build --locked --release --target x86_64-pc-windows-msvc
  if ($LASTEXITCODE -ne 0) { throw 'LOOT helper build failed' }
} finally { Pop-Location }
New-Item -ItemType Directory -Force "$bundle/engine" | Out-Null
Copy-Item "$engine/ModConductor.Engine.exe","$engine/e_sqlite3.dll","$engine/ModConductor.Engine.staticwebassets.endpoints.json","$env:CARGO_TARGET_DIR/x86_64-pc-windows-msvc/release/modconductor-loot-helper.exe" "$bundle/engine/"
