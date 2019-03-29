
# USB Device Log files
Write-Host -ForegroundColor Yellow "`tCollecting USB logs"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

Copy-LiveResponse -path "$env:systemdrive\Windows\Inf" -dest "$Out\Windows\inf" -filter "setupapi.dev.log" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows" -dest $("$Out\Windows" -filter "setupapi.log") -forensic
