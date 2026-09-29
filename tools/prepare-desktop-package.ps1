param([Parameter(Mandatory)][string]$Rid, [Parameter(Mandatory)][string]$PublishDirectory)
if ($Rid -ne 'win-x64' -or !(Test-Path $PublishDirectory -PathType Container)) { throw 'Expected Windows x64 publish directory' }
