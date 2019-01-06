
# Anti-Virus Log files
Write-Host -ForegroundColor Yellow "`tCollecting Anti-Virus logs"

# Symantec
Invoke-BulkCopy -folder "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\CurrentVersion\Data\Logs" -target "$Output\AntiVirus\SymantecEPP" -filter "*.log" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\CurrentVersion\Data\Logs\AV" -target "$Output\AntiVirus\SymantecEPP\AV" -filter "*.log" -forensic
Invoke-BulkCopy -folder "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\CurrentVersion\Data\Quarantine" -target "$Output\AntiVirus\SymantecEPP\Quarantine" -filter "*.VBN" -recurse -forensic
Invoke-BulkCopy -folder "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\PersistedData" -target "$Output\AntiVirus\SymantecEPP\PersistedData" -filter "sephwid.xml" -recurse -forensic


$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "DEfault" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

Foreach ($User in $Users) {
    Invoke-BulkCopy -folder "$env:systemdrive\Users\$User" -target "$Output\User\$user" -filter "ntuser.dat" -forensic
    Invoke-BulkCopy -folder "$env:systemdrive\Users\$User\AppData\Local\Symantec\Symantec Endpoint Protection\Logs" -target "$Output\AntiVirus\Symantec\$user\AppData\Local\Microsoft\Windows" -filter "*.log" -forensic
}
