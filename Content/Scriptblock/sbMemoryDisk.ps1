
# Memory Disk artefacts
Write-Host -ForegroundColor Yellow "`tCollecting Memory disk artefacts"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Invoke-BulkCopy -path "$env:systemdrive" -dest $Out  -filter "*.sys" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Out\Windows\" -filter "*.dmp" -forensic
