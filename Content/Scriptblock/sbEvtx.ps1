
# Windows EventLog collection
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

# Basic triage, see sbEvtxFull for comprehensive
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Security.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "System.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Application.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-Sysmon%4Operational.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-Powershell%4Operational.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-Bits-Client%4Operational.evtx" -forensic
