
# USNJournal $J collection
Write-Host -ForegroundColor Yellow "`tCollecting UsnJournal:`$J"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

If (! (Test-Path $Out)){
     New-Item ($Out) -type directory | Out-Null
}

try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$Extend\`$UsnJrnl" -OutFile (("$Out\`$J")) -DataStream "`$J"}
Catch{Write-Host "`tError: UsnJournal:`$J raw copy."}
