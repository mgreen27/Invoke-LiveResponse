
# Windows EventLog collection - all
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "*.evtx" -forensic
