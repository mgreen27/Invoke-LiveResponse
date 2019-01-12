
# Memory Disk artefacts
Write-Host -ForegroundColor Yellow "`tCollecting Memory disk artefacts"

Invoke-BulkCopy -path "$env:systemdrive" -dest "$Output\Memory" -filter "*.sys" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Output\Memory" -filter "*.dmp" -forensic
