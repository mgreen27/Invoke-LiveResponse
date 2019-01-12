
# Windows System Registry hives
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"

# Example collection aligning to Plaso processed files
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SECURITY*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SOFTWARE*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SAM*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SYSTEM*" -forensic

Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SECURITY" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SOFTWARE" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SAM" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SYSTEM" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "*.LOG*" -forensic

Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Output\Registry\SystemProfile" -filter "ntuser.dat" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Output\Registry\SystemProfile" -filter "ntuser.dat.LOG*" -forensic

Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Output\Registry\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Output\Registry\ServiceProfiles" -filter "ntuser.dat.LOG*" -recurse -forensic
