
# Windows EventLog collection
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"

# Basic triage, see sbEvtxFull for comprehensive
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "Security.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "System.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "Application.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "Microsoft-Windows-Sysmon%4Operational.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "Microsoft-Windows-Powershell%4Operational.evtx" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "Microsoft-Windows-Bits-Client%4Operational.evtx" -forensic

