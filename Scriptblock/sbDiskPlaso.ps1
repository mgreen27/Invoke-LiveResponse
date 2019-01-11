
# Disk artefact collection
If (! (Test-Path "$Output\Disk")){
    New-Item ($Output + "\Disk") -type directory | Out-Null
}

# $MFT
Write-Host -ForegroundColor Yellow "`tCollecting `$MFT"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$MFT" -OutFile ($Output + "\Disk\`$MFT")}
Catch{Write-Host "`tError: `$MFT raw copy."}

# USNJournal $J
Write-Host -ForegroundColor Yellow "`tCollecting UsnJournal:`$J"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$Extend\`$UsnJrnl" -OutFile ($Output + "\Disk\`$J") -DataStream "`$J"}
Catch{Write-Host "`tError: UsnJournal:`$J raw copy."}

# $LogFile
Write-Host -ForegroundColor Yellow "`tCollecting `$LogFile"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$LogFile" -OutFile ($Output + "\Disk\`$LogFile")}
Catch{Write-Host "`tError: `$LogFile raw copy."} 
