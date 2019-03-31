
# Execution Collection
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"

# Prefetch
Copy-LiveResponse -path "$env:systemdrive\Windows\Prefetch" -dest "$Out\Windows\Prefetch" -filter *.pf

# Tasks
Copy-LiveResponse -path "$env:systemdrive\Windows\Tasks" -dest "$Out\Windows\Tasks" -filter "*.job"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\Tasks" -dest "$Out\Windows\System32\Tasks" -recurse
Copy-LiveResponse -path "$env:systemdrive\Windows" -dest "$Out\Windows" -filter "SchedLgU.txt"

# AppCompat / Shimcache
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "RecentFileCache.bcf"
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "Amcache.hve"
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "Amcache.hve.LOG*"

# WMI
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\wbem\Repository" -dest "$Out\Windows\System32\wbem\Repository"

# SRUM
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\SRU" -dest "$Out\Windows\System32\SRU"
