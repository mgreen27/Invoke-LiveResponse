
# Anti-Virus Log files
Write-Host -ForegroundColor Yellow "`tCollecting Anti-Virus logs"

# Symantec
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
$Symantec = "ProgramData\Symantec\Symantec Endpoint Protection"
Invoke-BulkCopy -path "$env:systemdrive\$Symantec\CurrentVersion\Data\Logs" -dest "$Out\$Symantec\CurrentVersion\Data\Logs" -filter "*.log" -forensic
Invoke-BulkCopy -path "$env:systemdrive\$Symantec\CurrentVersion\Data\Logs\AV" -dest "$Out\$Symantec\CurrentVersion\Data\Logs\AV" -filter "*.log" -forensic
Invoke-BulkCopy -path "$env:systemdrive\$Symantec\CurrentVersion\Data\Quarantine" -dest "$Out\$Symantec\CurrentVersion\Data\Quarantine" -filter "*.VBN" -recurse -forensic
Invoke-BulkCopy -path "$env:systemdrive\$Symantec\PersistedData" -dest "$Out\$Symantec\PersistedData" -filter "sephwid.xml" -recurse -forensic


$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "Default" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

Foreach ($User in $Users) {
    Invoke-BulkCopy -path "$env:systemdrive\Users\$User\AppData\Local\Symantec\Symantec Endpoint Protection\Logs" -dest "$Out\Users\$user\AppData\Local\Symantec\Symantec Endpoint Protection\Logs" -filter "*.log" -forensic
}
