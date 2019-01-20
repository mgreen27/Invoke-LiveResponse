
# Execution Collection
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"

Invoke-BulkCopy -path "$env:systemdrive\Windows\Tasks" -dest "$Out\Windows\Tasks" -filter "*.job"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\Tasks" -dest "$Out\Windows\System32\Tasks" -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "RecentFileCache.bcf"
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "Amcache.hve" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\wbem\Repository" -dest "$Out\Windows\System32\wbem\Repository"
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Out\Windows" -filter "SchedLgU.txt"
