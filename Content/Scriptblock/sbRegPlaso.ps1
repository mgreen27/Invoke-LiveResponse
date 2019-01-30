
# Windows System Registry hives
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

# Example collection aligning to Plaso processed files
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SECURITY*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SOFTWARE*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SAM*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SYSTEM*" -forensic

Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SECURITY" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SOFTWARE" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SAM" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "SYSTEM" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\RegBack" -dest "$Out\Windows\System32\config\RegBack" -filter "*.LOG*" -forensic

Copy-LiveResponse -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Out\Windows\System32\Config\SystemProfile" -filter "ntuser.dat" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Out\Windows\System32\Config\SystemProfile" -filter "ntuser.dat.LOG*" -forensic

Copy-LiveResponse -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser.dat.LOG*" -recurse -forensic
