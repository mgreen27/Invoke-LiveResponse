
# Prefetch collection
Write-Host -ForegroundColor Yellow "`tCollecting Prefetch (if exist)"
Invoke-BulkCopy -folder "$env:systemdrive\Windows\Prefetch" -target "$Output\Prefetch" -filter *.pf
