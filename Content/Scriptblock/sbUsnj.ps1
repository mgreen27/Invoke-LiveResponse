
# USNJournal $J collection
Write-Host -ForegroundColor Yellow "`tCollecting UsnJournal:`$J"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

try{ Invoke-ForensicCopy -InFile "$env:systemdrive\`$Extend\`$UsnJrnl" -OutFile (("$Out\`$J")) -DataStream "`$J" -log }
Catch{ Write-Host "`tError: UsnJournal:`$J raw copy." }
