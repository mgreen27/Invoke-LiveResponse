
# Memory Disk artefacts
Write-Host -ForegroundColor Yellow "`tCollecting Memory disk artefacts"

Invoke-BulkCopy -folder "$env:systemdrive" -target "$Output\Memory" -filter "*.sys" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows" -target "$Output\Memory" -filter "*.dmp" -forensic
