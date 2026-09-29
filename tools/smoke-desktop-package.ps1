param([Parameter(Mandatory)][string]$Executable, [Parameter(Mandatory)][string]$Version)
$ErrorActionPreference = 'Stop'
$app = (Resolve-Path $Executable).Path
if ((Split-Path $app -Leaf) -ne 'mod_conductor.exe' -or !(Test-Path (Join-Path (Split-Path $app) 'engine/ModConductor.Engine.exe'))) { throw 'Incomplete Windows desktop payload' }
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$work = Join-Path $root ('.agent-workspace/windows-smoke-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force "$work/AppData/Local", "$work/AppData/Roaming" | Out-Null
$oldProfile, $oldLocal, $oldRoaming = $env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA
$env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA = $work, "$work/AppData/Local", "$work/AppData/Roaming"
$frontend = $null
try {
  $frontend = Start-Process $app -PassThru -WorkingDirectory (Split-Path $app)
  $engine = $null
  for ($attempt = 0; $attempt -lt 180; $attempt++) {
    $frontend.Refresh()
    if ($frontend.HasExited) { throw "Desktop exited before engine startup: $($frontend.ExitCode)" }
    $engine = Get-CimInstance Win32_Process -Filter "ParentProcessId = $($frontend.Id)" | Where-Object Name -eq 'ModConductor.Engine.exe' | Select-Object -First 1
    $state = Get-ChildItem "$work/AppData/Local" -Filter state.db -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($engine -and $state) { break }
    Start-Sleep -Milliseconds 250
  }
  if (!$engine -or !$state) { throw 'Desktop did not start its bundled engine and private state' }
  if (!$frontend.CloseMainWindow()) { throw 'Desktop window did not open' }
  if (!$frontend.WaitForExit(20000) -or $frontend.ExitCode -ne 0) { throw 'Desktop did not close normally' }
  for ($attempt = 0; $attempt -lt 40; $attempt++) {
    if (!(Get-Process -Id $engine.ProcessId -ErrorAction SilentlyContinue)) { break }
    Start-Sleep -Milliseconds 250
  }
  if (Get-Process -Id $engine.ProcessId -ErrorAction SilentlyContinue) { throw 'Bundled engine remained after desktop closed' }
  Write-Host 'Windows desktop and NativeAOT engine started; closing the window stopped both.'
} finally {
  if ($frontend -and !$frontend.HasExited) { $frontend.Kill(); $frontend.WaitForExit() }
  $env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA = $oldProfile, $oldLocal, $oldRoaming
  Remove-Item $work -Recurse -Force
}
