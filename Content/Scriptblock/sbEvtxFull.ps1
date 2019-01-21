
# Windows EventLog collection - all
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "*.evtx" -forensic
