
# Anti-Virus Log files
Write-Host -ForegroundColor Yellow "`tCollecting Anti-Virus logs"

# Symantec
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\CurrentVersion\Data\Logs" -dest "$Output\AntiVirus\SymantecEPP" -filter "*.log" -forensic
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\CurrentVersion\Data\Logs\AV" -dest "$Output\AntiVirus\SymantecEPP\AV" -filter "*.log" -forensic
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\CurrentVersion\Data\Quarantine" -dest "$Output\AntiVirus\SymantecEPP\Quarantine" -filter "*.VBN" -recurse -forensic
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Symantec\Symantec Endpoint Protection\PersistedData" -dest "$Output\AntiVirus\SymantecEPP\PersistedData" -filter "sephwid.xml" -recurse -forensic


$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "DEfault" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

Foreach ($User in $Users) {
    Invoke-BulkCopy -path "$env:systemdrive\Users\$User\AppData\Local\Symantec\Symantec Endpoint Protection\Logs" -dest "$Output\AntiVirus\Symantec\$user\AppData\Local\Microsoft\Windows" -filter "*.log" -forensic
}
