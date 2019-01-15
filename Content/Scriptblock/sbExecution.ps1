
# Execution Collection
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"

Invoke-BulkCopy -path "$env:systemdrive\Windows\Tasks" -dest "$Output\Execution\Tasks" -filter "*.job"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\Tasks" -dest "$Output\Execution\Tasks"-recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "RecentFileCache.bcf"
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "Amcache.hve" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "Amcache.hve.LOG*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\wbem\Repository" -dest "$Output\Execution\wbem"
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Output\Execution" -filter "SchedLgU.txt"
