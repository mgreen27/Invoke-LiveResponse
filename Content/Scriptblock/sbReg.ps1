
# Registry Collection
Write-Host -ForegroundColor Yellow "`tCollecting Registry Hives"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
# Basic Registry collection
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SECURITY" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SOFTWARE" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SAM" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SYSTEM" -forensic

# System and serice profile hives
Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest  + "\Windows\System32\Config\SystemProfile" -filter "ntuser.dat" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Ou\Windows\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
