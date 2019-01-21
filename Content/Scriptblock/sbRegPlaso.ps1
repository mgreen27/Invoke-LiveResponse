
# Windows System Registry hives
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

# Example collection aligning to Plaso processed files
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SECURITY*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SOFTWARE*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SAM*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SYSTEM*" -forensic

Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SECURITY" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SOFTWARE" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SAM" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SYSTEM" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "*.LOG*" -forensic

Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Out\Windows\System32\Config\SystemProfile" -filter "ntuser.dat" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Out\Windows\System32\Config\SystemProfile" -filter "ntuser.dat.LOG*" -forensic

Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser.dat.LOG*" -recurse -forensic
