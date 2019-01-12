
# $MFT collection
If (! (Test-Path "$Output\Disk")){
    New-Item ($Output + "\Disk") -type directory | Out-Null
}
Write-Host -ForegroundColor Yellow "`tCollecting `$MFT"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$MFT" -OutFile ($Output + "\Disk\`$MFT")}
Catch{Write-Host "`tError: `$MFT raw copy."}
