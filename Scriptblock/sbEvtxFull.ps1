
# Windows EventLog collection - all
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\winevt\Logs" -target "$Output\Evtx" -filter "*.evtx" -forensic
