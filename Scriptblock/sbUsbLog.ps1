
# USB Device Log files
Write-Host -ForegroundColor Yellow "`tCollecting USB logs"
          
Invoke-BulkCopy -folder "$env:systemdrive\Windows\Inf" -target "$Output\USB\inf" -filter "setupapi.dev.log" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows" -target "$Output\USB" -filter "setupapi.log" -forensic
