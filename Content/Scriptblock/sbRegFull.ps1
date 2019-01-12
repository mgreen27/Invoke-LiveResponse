
# Windows System Registry hives
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"

# Relevent hives and recursive folders including ..\regback
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SECURITY*" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SOFTWARE*" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SAM*" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SYSTEM*" -forensic -recurse

# Transaction logs
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\TxR" -dest "$Output\Registry\TxR" -filter "*" -forensic

# System ntuser.dat and log files
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\systemprofile" -dest "$Output\Registry\SystemProfile" -filter "ntuser*" -forensic

# Service profile user hive
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Output\Registry\ServiceProfiles" -filter "ntuser*" -recurse -forensic
