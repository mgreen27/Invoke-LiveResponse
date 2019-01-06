
# Various Log files
Write-Host -ForegroundColor Yellow "`tCollecting various logs"
          
Invoke-BulkCopy -folder "$env:systemdrive\Windows\LogFiles" -target "$Output\Logfiles" -filter "*.log" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\LogFiles" -target "$Output\Logfiles" -filter "*.log.old" -forensic -recurse
