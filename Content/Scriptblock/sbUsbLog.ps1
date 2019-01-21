
# USB Device Log files
Write-Host -ForegroundColor Yellow "`tCollecting USB logs"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

Invoke-BulkCopy -path "$env:systemdrive\Windows\Inf" -dest "$Out\Windows\inf" -filter "setupapi.dev.log" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest $("$Out\Windows" -filter "setupapi.log") -forensic
