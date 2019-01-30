
# Prefetch collection
Write-Host -ForegroundColor Yellow "`tCollecting Prefetch"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Copy-LiveResponse -path "$env:systemdrive\Windows\Prefetch" -dest "$Out\Windows\Prefetch" -filter *.pf
