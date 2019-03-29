
# Memory Disk artefacts
Write-Host -ForegroundColor Yellow "`tCollecting Memory disk artefacts"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Copy-LiveResponse -path "$env:systemdrive" -dest $Out -filter "*.sys" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows" -dest "$Out\Windows" -filter "*.dmp" -forensic
