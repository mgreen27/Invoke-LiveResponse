
# Execution Collection
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"

Copy-LiveResponse -path "$env:systemdrive\Windows\Tasks" -dest "$Out\Windows\Tasks" -filter "*.job"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\Tasks" -dest "$Out\Windows\System32\Tasks" -recurse
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "RecentFileCache.bcf"
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "Amcache.hve" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\wbem\Repository" -dest "$Out\Windows\System32\wbem\Repository"
Copy-LiveResponse -path "$env:systemdrive\Windows" -dest "$Out\Windows" -filter "SchedLgU.txt"
