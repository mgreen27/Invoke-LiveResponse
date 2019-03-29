
# Various Log files
Write-Host -ForegroundColor Yellow "`tCollecting various logs"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Copy-LiveResponse -path "$env:systemdrive\Windows\LogFiles" -dest "$Out\Windows\LogFiles" -filter "*.log" -forensic -recurse
Copy-LiveResponse -path "$env:systemdrive\Windows\LogFiles" -dest "$Out\Windows\Logfiles" -filter "*.log.old" -forensic -recurse
