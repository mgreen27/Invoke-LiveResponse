
# Memory Disk artefacts
Write-Host -ForegroundColor Yellow "`tCollecting Memory disk artefacts"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Copy-LiveResponse -path "$env:systemdrive" -dest $Out -filter "*.sys"
Copy-LiveResponse -path "$env:systemdrive" -recurse -dest $Out -filter "*.dmp"
