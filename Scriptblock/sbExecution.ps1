
# Execution Collection
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"

Invoke-BulkCopy -folder "$env:systemdrive\Windows\Tasks" -target "$Output\Execution\Tasks" -filter "*.job" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\Tasks" -target "$Output\Execution\Tasks"-recurse -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\AppCompat\Programs" -target "$Output\Execution" -filter "RecentFileCache.bcf" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\AppCompat\Programs" -target "$Output\Execution" -filter "Amcache.hve" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\AppCompat\Programs" -target "$Output\Execution" -filter "Amcache.hve.LOG*" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\wbem\Repository" -target "$Output\Execution\wbem" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows" -target "$Output\Execution" -filter "SchedLgU.txt" -forensic
