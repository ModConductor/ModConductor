param([Parameter(Mandatory=$true)][string]$EnginePath)
$ErrorActionPreference='Stop'
$directory=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ModConductor\session-keys'
$provider=[System.Security.Cryptography.CngProvider]::MicrosoftSoftwareKeyStorageProvider
$owned=@()
function KeyExists($name) { [System.Security.Cryptography.CngKey]::Exists($name,$provider) }
function StartEngine {
 $before=@(Get-ChildItem $directory -Filter '*.lease' -ErrorAction SilentlyContinue | ForEach-Object Name)
 $p=New-Object System.Diagnostics.Process
 $p.StartInfo.FileName=$EnginePath
 $p.StartInfo.UseShellExecute=$false
 $p.StartInfo.RedirectStandardInput=$true
 $p.StartInfo.RedirectStandardOutput=$true
 $p.StartInfo.RedirectStandardError=$true
 $p.Start() | Out-Null
 $script:owned += $p
 $handle=$p.Handle
 $bytes=New-Object byte[] 32
 $random=[System.Security.Cryptography.RandomNumberGenerator]::Create()
 try {$random.GetBytes($bytes)} finally {$random.Dispose()}
 $capability=([BitConverter]::ToString($bytes)).Replace('-','').ToLowerInvariant()
 $p.StandardInput.Write($capability+"`n")
 $p.StandardInput.Flush()
 $ready=$p.StandardOutput.ReadLineAsync()
 if(-not $ready.Wait(15000)){throw 'The engine did not announce its endpoint.'}
 if(-not $ready.Result -or $ready.Result.Contains($capability)){throw 'Invalid public bootstrap.'}
 $new=@(Get-ChildItem $directory -Filter '*.lease' | Where-Object {$_.Name -notin $before})
 if($new.Count -ne 1){throw 'Run this check without another engine launch in progress.'}
 $name='ModConductor.Session.'+$new[0].BaseName
 if(-not (KeyExists $name)){throw 'The named session key is absent.'}
 return @{process=$p;key=$name;lease=$new[0].FullName}
}
function CloseEngine($session) {
 $session.process.StandardInput.Close()
 if(-not $session.process.WaitForExit(10000)){throw 'The engine did not stop.'}
 if($session.process.ExitCode -ne 0){throw 'The engine did not exit cleanly.'}
 if((KeyExists $session.key) -or (Test-Path $session.lease)){throw 'Normal close left a session key or lease.'}
}
$foreignName='ModConductor.Session.'+[Guid]::NewGuid().ToString('N')
$parameters=New-Object System.Security.Cryptography.CngKeyCreationParameters
$parameters.Provider=$provider
$foreign=[System.Security.Cryptography.CngKey]::Create([System.Security.Cryptography.CngAlgorithm]::Rsa,$foreignName,$parameters)
try {
 $normal=StartEngine
 CloseEngine $normal
 $crashed=StartEngine
 $live=StartEngine
 $crashed.process.Kill()
 $crashed.process.WaitForExit()
 if(-not (KeyExists $crashed.key) -or -not (Test-Path $crashed.lease)){throw 'The crash did not retain its cleanup record.'}
 $restarted=StartEngine
 if((KeyExists $crashed.key) -or (Test-Path $crashed.lease)){throw 'Startup did not clean the abandoned key.'}
 if($live.process.HasExited -or -not (KeyExists $live.key) -or -not (Test-Path $live.lease)){throw 'Cleanup changed a live session.'}
 if(-not (KeyExists $foreignName)){throw 'Cleanup removed a foreign key.'}
 CloseEngine $live
 CloseEngine $restarted
 @{normalExitDeletion=$true;crashCleanup=$true;liveSessionPreserved=$true;foreignKeyPreserved=$true} | ConvertTo-Json
} finally {
 foreach($p in $owned){
  if(-not $p.HasExited){$p.StandardInput.Close(); $p.WaitForExit(10000) | Out-Null}
  $p.Dispose()
 }
 $foreign.Delete()
 $foreign.Dispose()
}
