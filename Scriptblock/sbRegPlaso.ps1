
# Windows System Registry hives supported by plaso
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"

# relevent hives and recursive folders including ..\regback
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SECURITY*" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SOFTWARE*" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SAM*" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SYSTEM*" -forensic -recurse

# System ntuser.dat and log files
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "*.dat" -forensic -recurse
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry\" -filter "*.LOG*" -forensic -recurse

# will collect service profile user hive
Invoke-BulkCopy -folder "$env:systemdrive\Windows\ServiceProfiles" -target "$Output\Registry\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\ServiceProfiles" -target "$Output\Registry\ServiceProfiles" -filter "ntuser.dat.LOG*" -recurse -forensic
