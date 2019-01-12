
# Windows Event Trace Logs (ETL)
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Trace Logs (ETL)"

Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\WDI" -dest "$Output\ETW\WDI" -filter "*" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\WDI\LogFiles" -dest "$Output\ETW\WDI\LogFiles" -filter "*.etl" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\LogFiles\WMI" -dest "$Output\ETW\LogFiles\WMI" -filter "*.etl" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\WDI\RtBackup" -dest "$Output\ETW\WDI\LogFiles\RtBackup" -filter "*.etl" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\SleepStudy" -dest "$Output\ETW\SleepStudy" -filter "*.etl" -Forensic

Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Microsoft\Windows\PowerEfficiency Diagnostics\" -dest "$Output\ETW\PowerEfficiencyDiagnostics\" -filter "energy-ntkl.etl" -Forensic
