<# 
Filter file for log2timeline for triaging Windows systems.
This is a modification of the SANS 508 windows filter file.
Additions to SANS 508 config file by Mark Hallman Version 1.04 - 2018-12-10
https://raw.githubusercontent.com/mark-hallman/plaso_filters/master/filter_windows.txt

This file can be used by Invoke-LiveResponse to selectively export few key files of 
a Windows system. This file will collect:
    - The MFT file, LogFile and the UsnJrnl
    - Contents of the Recycle Bin\Recycler.
    - Windows Registry files, e.g. SYSTEM and NTUSER.DAT.
    - Shortcut (LNK) files from recent files.
    - Jump list files, automatic and custom destination.
    - Windows Event Log files.
    - Prefetch files.
    - SetupAPI file.
    - Application Compatibility files, the Recentfilecache and AmCachefile.
    - Windows At job files.
    - Browser history: IE, Firefox and Chrome.
    - Browser cookie files: IE.
    - Flash cookies, or LSO\SOL files from the Flash player.
#>


############################################################
# File system artifacts.
############################################################

If (! (Test-Path "$Output\Disk")){
    New-Item ($Output + "\Disk") -type directory | Out-Null
}
$Drives = [System.IO.DriveInfo]::getdrives() | Where-Object {$_.DriveType -eq 'Fixed' -and $_.DriveFormat -eq 'NTFS'} | Select-Object -Property Name

# $MFT - only MFT covering multiple drive usecase
Write-Host -ForegroundColor Yellow "`tCollecting `$MFT"
foreach ( $Drive in $Drives ) {
    $target = $Drive.Name.trimend(":\")
    try{Invoke-ForensicCopy -InFile "$Target`:\`$MFT" -OutFile ($Output + "\Disk\`$MFT_$target")}
    Catch{Write-Host "`tError: `$MFT raw copy."}
}

# USNJournal $J
Write-Host -ForegroundColor Yellow "`tCollecting UsnJournal:`$J"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$Extend\`$UsnJrnl" -OutFile ($Output + "\Disk\`$J") -DataStream "`$J"}
Catch{Write-Host "`tError: UsnJournal:`$J raw copy."}

# $LogFile
Write-Host -ForegroundColor Yellow "`tCollecting `$LogFile"
try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$LogFile" -OutFile ($Output + "\Disk\`$LogFile")}
Catch{Write-Host "`tError: `$LogFile raw copy."} 



############################################################
# Memory artifacts - log2timeline currently does not
# process these artifacts.
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Memory disk artefacts"
# swapfile.sys, pagefile.sys and hiberfil.sys and \Windows\memory.dmp
Invoke-BulkCopy -path "$env:systemdrive" -dest "$Output\Memory" -filter "*.sys" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Output\Memory" -filter "*.dmp" -forensic



############################################################
# File System artifacts - Include for image_export, log2timeline currently does not
# process these artifacts.
############################################################
#\[$]Secure
#\[$]Boot
#\[$]Extend\[$]RmMetadata\[$]TxfLog\[$]Tops



############################################################
# Windows System Registry hives
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Windows System Registry hives"
 
 # System hives
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SECURITY*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SOFTWARE*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SAM*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry" -filter "SYSTEM*" -forensic

# regback folder and all important hives + log files
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SECURITY*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SOFTWARE*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SAM*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config" -dest "$Output\Registry\RegBack" -filter "SYSTEM*" -forensic

# System and Service profile hives
Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Output\Registry\SystemProfile" -filter "ntuser.dat" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Output\Registry\SystemProfile" -filter "ntuser.dat.LOG*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Output\Registry\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Output\Registry\ServiceProfiles" -filter "ntuser.dat.LOG*" -recurse -forensic


############################################################
# Recycle Bin and Recycler
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting RecycleBin Artefacts"
$Drives = [System.IO.DriveInfo]::getdrives() | Where-Object {$_.DriveType -eq 'Fixed'} | Select-Object -Property Name
foreach ( $Drive in $Drives ) {
    $target = $Drive.Name.trimend(":\")
    Invoke-BulkCopy -path "$Drive\`$Recycle.Bin" -dest "$Output\RecycleBin\$Target" -recurse -Exclude desktop.ini
}



############################################################
# Windows Event Logs
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Output\Evtx" -filter "*.evtx" -forensic



############################################################
# Windows Event Trace Logs (ETL)
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Trace Logs (ETL)"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\WDI" -dest "$Output\ETW\WDI" -filter "*" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\WDI\LogFiles" -dest "$Output\ETW\WDI\LogFiles" -filter "*.etl" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\LogFiles\WMI" -dest "$Output\ETW\LogFiles\WMI" -filter "*.etl" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\WDI\RtBackup" -dest "$Output\ETW\WDI\LogFiles\RtBackup" -filter "*.etl" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\SleepStudy" -dest "$Output\ETW\SleepStudy" -filter "*.etl" -Forensic
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Microsoft\Windows\PowerEfficiency Diagnostics\" -dest "$Output\ETW\PowerEfficiencyDiagnostics\" -filter "energy-ntkl.etl" -Forensic



############################################################
# USB Devices log files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting USB logs"
Invoke-BulkCopy -path "$env:systemdrive\Windows\Inf" -dest "$Output\USB\inf" -filter "setupapi.dev.log" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Output\USB" -filter "setupapi.log" -forensic



############################################################
# Various log files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting various logs"
Invoke-BulkCopy -path "$env:systemdrive\Windows\LogFiles" -dest "$Output\Logfiles" -filter "*.log" -forensic -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\LogFiles" -dest "$Output\Logfiles" -filter "*.log.old" -forensic -recurse



############################################################
# Anti-Virus Log and Quarantine files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Anti-Virus logs"

# Symantec
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Symantec" -dest "$Output\AntiVirus\Symantec" -filter "*.log" -recurse
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Symantec" -dest "$Output\AntiVirus\Symantec" -filter "*.VBN" -recurse
Invoke-BulkCopy -path "$env:systemdrive\ProgramData\Symantec" -dest "$Output\AntiVirus\Symantec" -filter "sephwid.xml" -recurse
$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "DEfault" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name
Foreach ($User in $Users) {
    Invoke-BulkCopy -path "$env:systemdrive\Users\$User\AppData\Local\Symantec" -dest "$Output\AntiVirus\Symantec\$user" -filter "*.log"
}
# Add more AV vendors!!!!!



############################################################
# Prefetch files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Prefetch (if exist)"
Invoke-BulkCopy -path "$env:systemdrive\Windows\Prefetch" -dest "$Output\Prefetch" -filter *.pf



############################################################
# Windows Execution Artifacts
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"
Invoke-BulkCopy -path "$env:systemdrive\Windows\Tasks" -dest "$Output\Execution\Tasks" -filter "*.job"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\Tasks" -dest "$Output\Execution\Tasks"-recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "RecentFileCache.bcf"
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "Amcache.hve" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Output\Execution" -filter "Amcache.hve.LOG*" -forensic
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\wbem\Repository" -dest "$Output\Execution\wbem"
Invoke-BulkCopy -path "$env:systemdrive\Windows" -dest "$Output\Execution" -filter "SchedLgU.txt"



############################################################
# SRUM
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting SRUM data"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\SRU" -dest "$Output\SRUM"



############################################################
# Windows Search Index
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Windows Search Index"
Invoke-BulkCopy -path "$env:systemdrive\programdata\microsoft\search\data\applications\windows" -dest "$Output\Search\programdata\microsoft\search\data\applications\windows" -filter "Windows.edb" -forensic



############################################################
# User artifacts
############################################################

Write-Host -ForegroundColor Yellow "`tCollecting User artefacts"
$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "DEfault" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

Foreach ($User in $Users) {
    $profile = "$env:systemdrive\Users\$User"
    $out = "$Output\User\$user"

    # User hives
    Invoke-BulkCopy -path $profile -dest $out -filter "ntuser.dat" -forensic
    Invoke-BulkCopy -path $profile -dest $out -filter "ntuser.dat.log*" -forensic
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows" -dest "$out\AppData\Local\Microsoft\Windows" -filter "UserClass.dat" -forensic
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows" -dest "$out\AppData\Local\Microsoft\Windows" -filter "UserClass.dat.log*" -forensic

    # Recent file activity
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Microsoft\Windows\Recent" -dest "$out\AppData\Roaming\Microsoft\Windows\Recent" -recurse -where "'.lnk','.automaticDestinations-ms','.customDestinations-ms' -eq `$_.extension"
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Microsoft\Office\Recent" -dest "$out\AppData\Roaming\Microsoft\Office\Recent" -filter "*.lnk"
    Invoke-BulkCopy -path "$profile\Desktop" -dest "$out\Desktop" -filter "*.lnk"

    #Invoke-BulkCopy -path "$profile\AppData\Local\ConnectedDevicesPlatform" -dest "$out\AppData\Local\ConnectedDevicesPlatform" -recurse

    # Windows 10 timline
    Invoke-BulkCopy -path "$profile\AppData\ConnectedDevicesPlatform" -dest "$out\AppData\ConnectedDevicesPlatform" -recurse -filter "ActivitivitiesCache.db" -forensic
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows\Explorer" -dest "$out\AppData\Local\Microsoft\Windows\Explorer" -filter "thumbcache*.db"

    # Skype
    Invoke-BulkCopy -path "$profile\AppData\Local\Packages\Microsoft.SkypeApp*\LocalState" -dest "$out\AppData\Local\Packages\Microsoft.SkypeApp*\LocalState" -filter "main.db"

    # Outlook
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Outlook" -dest "$out\AppData\Local\Microsoft\Outlook" -where ".pst,.ost -eq `$_.extension"

    # User Documents - this downloads potentially a lot of data and im removing it for timeline
    #Invoke-BulkCopy -path "$profile\Desktop" -dest "$out\Desktop" -recurse
    #Invoke-BulkCopy -path "$profile\Documents" -dest "$out\Documents";
    #Invoke-BulkCopy -path "$profile\Downloads" -dest "$out\Downloads" -recurse
    #Invoke-BulkCopy -path "$profile\Dropbox" -dest "$out\Dropbox" -recurse
}


############################################################
# Browser artifacts 
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Browser artefacts"
# Internet Explorer Browser history artifact
Foreach ($User in $Users) {
    $profile = "$env:systemdrive\Users\$User"
    $out = "$Output\User\$user"
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Internet Explorer\Recovery" -dest "$out\AppData\Local\Microsoft\Internet Explorer\Recovery" -filter "*.dat" -recurse
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows\History\Low\History.IE5" -dest "$outAppData\Local\Microsoft\Windows\History\Low\History.IE5" -filter "index.dat" -recurse
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5" -dest "$out\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5" -filter "index.dat" -recurse
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Internet Explorer\Recovery" -dest "$out\AppData\Local\Microsoft\Internet Explorer\Recovery" -filter "*.dat" -recurse
    Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows\WebCache" -dest "$out\AppData\Local\Microsoft\Windows\WebCache"
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Microsoft\Windows\IEDownloadHistory" -dest "$out\AppData\Roaming\Microsoft\Windows\IEDownloadHistory"

    $edge = "AppData\Local\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge"
    Invoke-BulkCopy -path "$profile\$edge" -dest "$out\$edge" -filter "spartan.edb" -recurse
    Invoke-BulkCopy -path "$profileAppData\Roaming\Macromedia\FlashPlayer\#SharedObjects" -dest "$out\Roaming\Macromedia\FlashPlayer\#SharedObjects" -filter "*.sol"
    Invoke-BulkCopy -path "$profileAppData\AppData\Roaming\Microsoft\Office\Recent" -dest "$out\AppData\Roaming\Microsoft\Office\Recent" -filter "index.dat"
    Invoke-BulkCopy -path "$profileAppData\*\MicrosoftEdgeBackups\backups\*\DatastoreBackup" -dest "$out\*\MicrosoftEdgeBackups\backups\*\DatastoreBackup" -filter "spartan.edb"
    Invoke-BulkCopy -path "$profileAppData\AppData\Roaming\Microsoft\Windows\Cookies" -dest "$out\AppData\Roaming\Microsoft\Windows\Cookies" -filter "index.dat"

    # Chrome browser history
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Cookies" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Cookies"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Current Session" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Current Session"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Favicons" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Favicons"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\History" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\History" -recurse
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Last Session" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Last Session"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Last Tabs" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Last Tabs"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Preferences" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Preferences"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Shortcuts" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Shortcuts"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Top Sites" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Top Sites"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Bookmarks" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Visited Links" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Visited Links"
    Invoke-BulkCopy -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Web Data" -dest "$out\AppData\Local\Google\Chrome\User Data\Default\Web Data"

    # Firefox browser history
    Invoke-BulkCopy -path "$profile\AppData\Roaming\Mozilla\Firefox\Profiles" -dest "$out\AppData\Roaming\Mozilla\Firefox\Profiles" -filter "*.sqlite" -recurse
}

# System Browser history
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Internet Explorer\Recovery" -dest "$out\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Internet Explorer\Recovery" -filter "*.dat" -recurse
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\History" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\History"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Temporary Internet Files" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Temporary Internet Files"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\WebCache" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\WebCache" -filter "*.dat"
Invoke-BulkCopy -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Cookies" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Cookies" -filter "index.dat" -recurse
