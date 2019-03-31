
# $Logfile collection
Write-Host -ForegroundColor Yellow "`tCollecting `$LogFile"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

try{ Invoke-ForensicCopy -InFile "$env:systemdrive\`$LogFile" -OutFile ("$Out\`$LogFile") -log }
Catch{ Write-Host "`tError: `$LogFile raw copy." } 
