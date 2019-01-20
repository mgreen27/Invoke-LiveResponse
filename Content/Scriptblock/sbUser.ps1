
# User artefact collection, currently user hives only
Write-Host -ForegroundColor Yellow "`tCollecting User Artefacts"
                       
$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "Default" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

Foreach ($User in $Users) {
    $profile = "$env:systemdrive\Users\$User"
    $Out = "$Output\" + $env:systemdrive.TrimEnd(':') + "\Users\$user"


    # User hives
    Invoke-BulkCopy -path $profile -dest $out -filter "ntuser.dat" -forensic
    Invoke-BulkCopy -path $profile -dest $out -filter "ntuser.dat.log*" -forensic
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows" -dest "$out\AppData\Local\Microsoft\Windows" -filter "UserClass.dat" -forensic

    # recent files
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Microsoft\Windows\Recent" -dest "$out\AppData\Roaming\Microsoft\Windows\Recent" -recurse
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Microsoft\Office\Recent" -dest "$out\AppData\Roaming\Microsoft\Office\Recent" -recurse

    # Outlook
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Outlook" -dest "$out\AppData\Local\Microsoft\Outlook" -where "'.pst','.ost' -eq `$_.extension"

    # Powershell
    #Invoke-BulkCopy -path "$profile\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline" -dest "$out\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline" -filter "ConsoleHost_history.txt"

    # Browser Artifacts
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Microsoft\Windows\IEDownloadHistory" -dest "$out\AppData\Roaming\Microsoft\Windows\IEDownloadHistory" #-filter "index.dat" # IE8-9
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows\WebCache" -dest "$out\AppData\Local\Microsoft\Windows\WebCache" -filter "WebCacheV*.dat" # IE10-11
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Mozilla\Firefox\Profiles" -dest "$out\AppData\Roaming\Mozilla\Firefox\Profiles" -recurse -filter "downloads.sqlite" # Firefox v3-25
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Mozilla\Firefox\Profiles" -dest "$out\AppData\Roaming\Mozilla\Firefox\Profiles" -recurse -filter "places.sqlite" # Firefox v26+
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\History" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\History" # Chrome Win7/8/10

    # Windows 10 Timeline
    Invoke-BulkCopy -path "$profile\AppData\ConnectedDevicesPlatform" -dest "$out\AppData\ConnectedDevicesPlatform" -recurse -filter "ActivitivitiesCache.db" -forensic

}
