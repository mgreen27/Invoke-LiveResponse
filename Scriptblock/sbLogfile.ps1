
# $Logfile collection
If (! (Test-Path "$Output\Disk")) {
    New-Item ($Output + "\Disk") -type directory | Out-Null
}

Write-Host -ForegroundColor Yellow "`tCollecting `$LogFile"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$LogFile" -OutFile ($Output + "\Disk\`$LogFile")}
Catch{Write-Host "`tError: `$LogFile raw copy."} 
