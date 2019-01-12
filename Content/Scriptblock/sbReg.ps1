
# Registry Collection
Write-Host -ForegroundColor Yellow "`tCollecting Registry Hives"

# Basic Registry collection
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SECURITY" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SOFTWARE" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SAM" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SYSTEM" -forensic

# System and serice profile hives
Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Output\Registry\SystemProfile" -filter "ntuser.dat" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Output\Registry\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
