
# Disk artefact collection
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

If (! (Test-Path $Out)){
     New-Item ($Out) -type directory | Out-Null
}

# $MFT
Write-Host -ForegroundColor Yellow "`tCollecting `$MFT"
try { Invoke-ForensicCopy -InFile "$env:systemdrive\`$MFT" -OutFile ("$Out\`$MFT") -log }
Catch { Write-Host "`tError: `$MFT raw copy." }

# USNJournal $J
Write-Host -ForegroundColor Yellow "`tCollecting UsnJournal:`$J"
try { Invoke-ForensicCopy -InFile "$env:systemdrive\`$Extend\`$UsnJrnl" -OutFile ("$Out\`$J") -DataStream "`$J" -log }
Catch { Write-Host "`tError: UsnJournal:`$J raw copy." }

# $LogFile
Write-Host -ForegroundColor Yellow "`tCollecting `$LogFile"
try {Invoke-ForensicCopy -InFile "$env:systemdrive\`$LogFile" -OutFile ("$Out\`$LogFile") -log }
Catch {Write-Host "`tError: `$LogFile raw copy." } 
