
# USB Device Log files
Write-Host -ForegroundColor Yellow "`tCollecting USB logs"
          
Invoke-BulkCopy -path "$env:systemdrive\Windows\Inf" -dest "$Output\USB\inf" -filter "setupapi.dev.log" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Output\USB" -filter "setupapi.log" -forensic
