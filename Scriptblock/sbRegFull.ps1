
# Windows System Registry hives
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"

# Relevent hives and recursive folders including ..\regback
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SECURITY*" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SOFTWARE*" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SAM*" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SYSTEM*" -forensic -recurse

# Transaction logs
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config\TxR" -target "$Output\Registry\TxR" -filter "*" -forensic

# System ntuser.dat and log files
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config\systemprofile" -target "$Output\Registry\SystemProfile" -filter "ntuser*" -forensic

# Service profile user hive
Invoke-BulkCopy -folder "$env:systemdrive\Windows\ServiceProfiles" -target "$Output\Registry\ServiceProfiles" -filter "ntuser*" -recurse -forensic
