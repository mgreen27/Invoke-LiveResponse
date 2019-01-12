
# Execution Collection
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"

Invoke-BulkCopy -path "$env:systemdrive\Windows\Tasks" -dest "$Output\Execution\Tasks" -filter "*.job" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\Tasks" -dest "$Output\Execution\Tasks"-recurse -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "RecentFileCache.bcf" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "Amcache.hve" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "Amcache.hve.LOG*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\wbem\Repository" -dest "$Output\Execution\wbem" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Output\Execution" -filter "SchedLgU.txt" -forensic
