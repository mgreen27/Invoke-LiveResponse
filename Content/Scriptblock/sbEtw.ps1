
# Windows Event Trace Logs (ETL)
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Trace Logs (ETL)"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

Copy-LiveResponse -path "$env:systemdrive\Windows\System32\WDI" -dest "$Out\Windows\System32\WDI" -filter "*" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\WDI\LogFiles" -dest "$Out\Windows\System32\WDI\LogFiles" -filter "*.etl" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\LogFiles\WMI" -dest "$Out\Windows\System32\LogFiles\WMI" -filter "*.etl" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\WDI\RtBackup" -dest "$Out\Windows\System32\WDI\RtBackup" -filter "*.etl" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\SleepStudy" -dest "$Out\Windows\System32\SleepStudy" -filter "*.etl" -Forensic

Copy-LiveResponse -path "$env:systemdrive\ProgramData\Microsoft\Windows\PowerEfficiency Diagnostics" -dest "$Out\ProgramData\Microsoft\Windows\PowerEfficiency Diagnostics" -filter "energy-ntkl.etl" -Forensic
