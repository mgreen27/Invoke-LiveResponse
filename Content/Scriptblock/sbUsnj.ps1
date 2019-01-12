
# USNJournal $J collection
If (! (Test-Path "$Output\Disk")){
     New-Item ($Output + "\Disk") -type directory | Out-Null
}

Write-Host -ForegroundColor Yellow "`tCollecting UsnJournal:`$J"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$Extend\`$UsnJrnl" -OutFile ($Output + "\Disk\`$J") -DataStream "`$J"}
Catch{Write-Host "`tError: UsnJournal:`$J raw copy."}
