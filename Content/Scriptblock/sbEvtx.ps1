
# Windows EventLog collection
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"
$In = "$env:systemdrive\Windows\System32\winevt\Logs"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':') + "\Windows\System32\winevt\Logs"

# Basic triage, see sbEvtxFull for comprehensive
Copy-LiveResponse -path $In -dest $Out -filter "Security.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "System.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "Application.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "Microsoft-Windows-Sysmon%4Operational.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "Microsoft-Windows-Powershell%4Operational.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "Microsoft-Windows-Bits-Client%4Operational.evtx" -forensic
Copy-LiveResponse -path $In -dest $Out -filter "Microsoft-Windows-WinRM%4Operational.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Security.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "System.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Application.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-Sysmon%4Operational.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-Powershell%4Operational.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Logs" -filter "Microsoft-Windows-Bits-Client%4Operational.evtx" -forensic
