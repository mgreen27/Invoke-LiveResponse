
# Windows System Registry hives
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"

Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SECURITY*" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SOFTWARE*" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SAM*" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry" -filter "SYSTEM*" -forensic

Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry\RegBack" -filter "SECURITY" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry\RegBack" -filter "SOFTWARE" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry\RegBack" -filter "SAM" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry\RegBack" -filter "SYSTEM" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\config" -target "$Output\Registry\RegBack" -filter "*.LOG*" -forensic

Invoke-BulkCopy -folder "$env:systemdrive\Windows\system32\config\systemprofile" -target "$Output\Registry\SystemProfile" -filter "ntuser.dat" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\system32\config\systemprofile" -target "$Output\Registry\SystemProfile" -filter "ntuser.dat.LOG*" -forensic

Invoke-BulkCopy -folder "$env:systemdrive\Windows\ServiceProfiles" -target "$Output\Registry\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
Invoke-BulkCopy -folder "$env:systemdrive\Windows\ServiceProfiles" -target "$Output\Registry\ServiceProfiles" -filter "ntuser.dat.LOG*" -recurse -forensic
