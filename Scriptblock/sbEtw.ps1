
# Windows Event Trace Logs (ETL)
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Trace Logs (ETL)"

Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\WDI" -target "$Output\ETW\WDI" -filter "*" -Forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\WDI\LogFiles" -target "$Output\ETW\WDI\LogFiles" -filter "*.etl" -Forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\LogFiles\WMI" -target "$Output\ETW\LogFiles\WMI" -filter "*.etl" -Forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\WDI\RtBackup" -target "$Output\ETW\WDI\LogFiles\RtBackup" -filter "*.etl" -Forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\SleepStudy" -target "$Output\ETW\SleepStudy" -filter "*.etl" -Forensic

Invoke-BulkCopy -folder "$env:systemdrive\ProgramData\Microsoft\Windows\PowerEfficiency Diagnostics\" -target "$Output\ETW\PowerEfficiencyDiagnostics\" -filter "energy-ntkl.etl" -Forensic
