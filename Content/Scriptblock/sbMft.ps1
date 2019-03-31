
# $MFT collection
Write-Host -ForegroundColor Yellow "`tCollecting `$MFT"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

try{ Invoke-ForensicCopy -InFile "$env:systemdrive\`$MFT" -OutFile ("$Out\`$MFT") -log }
Catch{ Write-Host "`tError: `$MFT raw copy." }
