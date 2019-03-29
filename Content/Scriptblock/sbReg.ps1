
# Registry Collection
Write-Host -ForegroundColor Yellow "`tCollecting Registry Hives"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
# Basic Registry collection
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SECURITY" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SOFTWARE" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SAM" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\Config" -filter "SYSTEM" -forensic

# System and serice profile hives
Copy-LiveResponse -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest  + "$Out\Windows\System32\Config\SystemProfile" -filter "ntuser.dat" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
