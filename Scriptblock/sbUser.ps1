
# User artefact collection, currently user hives only
Write-Host -ForegroundColor Yellow "`tCollecting User Artefacts"
                       
$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "DEfault" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

Foreach ($User in $Users) {
    Invoke-BulkCopy -folder "$env:systemdrive\Users\$User" -target "$Output\User\$user" -filter "ntuser.dat" -forensic
    Invoke-BulkCopy -folder "$env:systemdrive\Users\$User\AppData\Local\Microsoft\Windows" -target "$Output\User\$user\AppData\Local\Microsoft\Windows" -filter "UserClass.dat" -forensic
}
