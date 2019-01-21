
# Various Log files
Write-Host -ForegroundColor Yellow "`tCollecting various logs"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Invoke-BulkCopy -path "$env:systemdrive\Windows\LogFiles" -dest "$Out\Windows\LogFiles" -filter "*.log" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\LogFiles" -dest "$Out\Windows\Logfiles" -filter "*.log.old" -forensic -recurse
