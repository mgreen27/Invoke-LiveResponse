
# Various Log files
Write-Host -ForegroundColor Yellow "`tCollecting various logs"
          
Invoke-BulkCopy -path "$env:systemdrive\Windows\LogFiles" -dest "$Output\Logfiles" -filter "*.log" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\LogFiles" -dest "$Output\Logfiles" -filter "*.log.old" -forensic -recurse
