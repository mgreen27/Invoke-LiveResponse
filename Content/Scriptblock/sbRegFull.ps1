
# Windows System Registry hives
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
# Relevent hives and recursive folders including ..\regback
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SECURITY*" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SOFTWARE*" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SAM*" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SYSTEM*" -forensic -recurse

# Transaction logs
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\TxR" -dest "$Out\Windows\System32\config\TxR" -filter "*" -forensic

# System ntuser.dat and log files
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\systemprofile" -dest "$Out\Windows\System32\config\SystemProfile" -filter "ntuser*" -forensic

# Service profile user hive
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser*" -recurse -forensic
