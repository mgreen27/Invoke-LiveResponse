
# Prefetch collection
Write-Host -ForegroundColor Yellow "`tCollecting Prefetch"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
Invoke-BulkCopy -path "$env:systemdrive\Windows\Prefetch" -dest "$Out\Windows\Prefetch" -filter *.pf
