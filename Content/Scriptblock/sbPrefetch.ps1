
# Prefetch collection
Write-Host -ForegroundColor Yellow "`tCollecting Prefetch (if exist)"
Invoke-BulkCopy -path "$env:systemdrive\Windows\Prefetch" -dest "$Output\Prefetch" -filter *.pf
