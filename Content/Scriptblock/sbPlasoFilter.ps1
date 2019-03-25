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
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

############################################################
# File system artifacts.
############################################################

# $MFT - only MFT covering multiple drive usecase
Write-Host -ForegroundColor Yellow "`tCollecting `$MFT"
try{ Invoke-ForensicCopy -InFile "$env:systemdrive\`$MFT" -OutFile ("$Out\`$MFT") -log }
Catch{ Write-Host "`tError: `$MFT raw copy." }

# USNJournal $J
Write-Host -ForegroundColor Yellow "`tCollecting UsnJournal:`$J"
try{ Invoke-ForensicCopy -InFile "$env:systemdrive\`$Extend\`$UsnJrnl" -OutFile (("$Out\`$J")) -DataStream "`$J" -log }
Catch{ Write-Host "`tError: UsnJournal:`$J raw copy." }

# $LogFile
Write-Host -ForegroundColor Yellow "`tCollecting `$LogFile"
try{ Invoke-ForensicCopy -InFile "$env:systemdrive\`$LogFile" -OutFile ("$Out\`$LogFile") -log }
Catch{ Write-Host "`tError: `$LogFile raw copy." } 



############################################################
# Memory artifacts - log2timeline currently does not
# process these artifacts.
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Memory disk artefacts"
# swapfile.sys, pagefile.sys and hiberfil.sys and \Windows\memory.dmp
Copy-LiveResponse -path "$env:systemdrive" -dest "$Out" -filter "*.sys" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows" -dest "$Out\Windows" -filter "*.dmp" -forensic



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
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SECURITY*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SOFTWARE*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SAM*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config" -dest "$Out\Windows\System32\config" -filter "SYSTEM*" -forensic

# regback folder and all important hives + log files
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\Regback" -dest "$Out\Windows\System32\config\RegBack" -filter "SECURITY*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\Regback" -dest "$Out\Windows\System32\config\RegBack" -filter "SOFTWARE*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\Regback" -dest "$Out\Windows\System32\config\RegBack" -filter "SAM*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\Regback" -dest "$Out\Windows\System32\config\RegBack" -filter "SYSTEM*" -forensic

# System and Service profile hives
Copy-LiveResponse -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Out\Windows\System32\config\SystemProfile" -filter "ntuser.dat" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\system32\config\systemprofile" -dest "$Out\Windows\System32\config\SystemProfile" -filter "ntuser.dat.LOG*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser.dat" -recurse -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\ServiceProfiles" -dest "$Out\Windows\ServiceProfiles" -filter "ntuser.dat.LOG*" -recurse -forensic


############################################################
# Recycle Bin and Recycler
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting RecycleBin Artefacts"
$Drives = [System.IO.DriveInfo]::getdrives() | Where-Object {$_.DriveType -eq 'Fixed'} | Select-Object -Property Name
foreach ( $Drive in $Drives ) {
    $target = $Drive.Name.trimend(":\")
    Copy-LiveResponse -path "$Drive\`$Recycle.Bin" -dest "$Output\$target\RecycleBin\" -recurse -Exclude desktop.ini
}



############################################################
# Windows Event Logs
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Logs"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\winevt\Logs" -dest "$Out\Windows\System32\winevt\Log" -filter "*.evtx" -forensic



############################################################
# Windows Event Trace Logs (ETL)
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Windows Event Trace Logs (ETL)"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\WDI" -dest "$Out\Windows\System32\WDI" -filter "*" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\WDI\LogFiles" -dest "C:\Windows\System32\WDI\LogFiles" -filter "*.etl" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\LogFiles\WMI" -dest "C:\Windows\System32\LogFiles\WMI" -filter "*.etl" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\WDI\RtBackup" -dest "$Out\Windows\System32\WDI\RtBackup" -filter "*.etl" -Forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\SleepStudy" -dest "$Out\Windows\System32\SleepStudy" -filter "*.etl" -Forensic
Copy-LiveResponse -path "$env:systemdrive\ProgramData\Microsoft\Windows\PowerEfficiency Diagnostics" -dest "$Out\ProgramData\Microsoft\Windows\PowerEfficiency Diagnostics" -filter "energy-ntkl.etl" -Forensic



############################################################
# USB Devices log files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting USB logs"
Copy-LiveResponse -path "$env:systemdrive\Windows\Inf" -dest "$Out\Windows\inf" -filter "setupapi.dev.log" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows" -dest "$Out\Windows" -filter "setupapi.log" -forensic



############################################################
# Various log files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting various logs"
Copy-LiveResponse -path "$env:systemdrive\Windows\LogFiles" -dest "$Out\Windows\LogFiless" -filter "*.log" -forensic -recurse
Copy-LiveResponse -path "$env:systemdrive\Windows\LogFiles" -dest "$Out\Windows\LogFiles" -filter "*.log.old" -forensic -recurse



############################################################
# Anti-Virus Log and Quarantine files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Anti-Virus logs"

# Symantec
Copy-LiveResponse -path "$env:systemdrive\ProgramData\Symantec" -dest "$Out\ProgramData\Symantec" -filter "*.log" -recurse
Copy-LiveResponse -path "$env:systemdrive\ProgramData\Symantec" -dest "$Out\ProgramData\Symantec" -filter "*.VBN" -recurse
Copy-LiveResponse -path "$env:systemdrive\ProgramData\Symantec" -dest "$Out\ProgramData\Symantec" -filter "sephwid.xml" -recurse
$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "DEfault" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name
Foreach ($User in $Users) {
    Copy-LiveResponse -path "$env:systemdrive\Users\$User\AppData\Local\Symantec" -dest "$Out\Users\$User\AppData\Local\Symantec" -filter "*.log"
}
# Add more AV vendors!!!!!



############################################################
# Prefetch files
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Prefetch (if exist)"
Copy-LiveResponse -path "$env:systemdrive\Windows\Prefetch" -dest "$Out\Windows\Prefetch" -filter *.pf



############################################################
# Windows Execution Artifacts
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Evidence of Execution"
Copy-LiveResponse -path "$env:systemdrive\Windows\Tasks" -dest "$Out\Execution\Tasks" -filter "*.job"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\Tasks" -dest "$Out\Windows\System32\Tasks"-recurse
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "RecentFileCache.bcf"
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "Amcache.hve" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\AppCompat\Programs" -dest "$Out\Windows\AppCompat\Programs" -filter "Amcache.hve.LOG*" -forensic
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\wbem\Repository" -dest "$Out\Windows\System32\wbem\Repository"
Copy-LiveResponse -path "$env:systemdrive\Windows" -dest "$Out\Windows" -filter "SchedLgU.txt"



############################################################
# SRUM
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting SRUM data"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\SRU" -dest "$Out\Windows\System32\SRU"



############################################################
# Windows Search Index
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Windows Search Index"
Copy-LiveResponse -path "$env:systemdrive\programdata\microsoft\search\data\applications\windows" -dest "$Out\programdata\microsoft\Search\programdata\microsoft\search\data\applications\windows" -filter "Windows.edb" -forensic



############################################################
# User artifacts
############################################################

Write-Host -ForegroundColor Yellow "`tCollecting User artefacts"
$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object {
$_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "DEfault" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

Foreach ($User in $Users) {
    $profile = "$env:systemdrive\Users\$User"

    # User hives
    Copy-LiveResponse -path $profile -dest $out -filter "ntuser.dat" -forensic
    Copy-LiveResponse -path $profile -dest $out -filter "ntuser.dat.log*" -forensic
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows" -dest "$out\Users\$user\AppData\Local\Microsoft\Windows" -filter "UsrClass.dat" -forensic
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows" -dest "$out\Users\$user\AppData\Local\Microsoft\Windows" -filter "UsrClass.dat.log*" -forensic

    # Recent file activity
    Copy-LiveResponse -path "$profile\AppData\Roaming\Microsoft\Windows\Recent" -dest "$out\Users\$user\AppData\Roaming\Microsoft\Windows\Recent" -recurse -where "'.lnk','.automaticDestinations-ms','.customDestinations-ms' -eq `$_.extension"
    Copy-LiveResponse -path "$profile\AppData\Roaming\Microsoft\Office\Recent" -dest "$out\Users\$user\AppData\Roaming\Microsoft\Office\Recent" -filter "*.lnk"
    Copy-LiveResponse -path "$profile\Desktop" -dest "$out\Desktop" -filter "*.lnk"

    #Copy-LiveResponse -path "$profile\AppData\Local\ConnectedDevicesPlatform" -dest "$out\AppData\Local\ConnectedDevicesPlatform" -recurse

    # Windows 10 timline
    Copy-LiveResponse -path "$profile\AppData\ConnectedDevicesPlatform" -dest "$out\Users\$user\AppData\ConnectedDevicesPlatform" -recurse -filter "ActivitivitiesCache.db" -forensic
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows\Explorer" -dest "$out\Users\$user\AppData\Local\Microsoft\Windows\Explorer" -filter "thumbcache*.db"

    # Skype
    Copy-LiveResponse -path "$profile\AppData\Local\Packages\Microsoft.SkypeApp*\LocalState" -dest "$out\Users\$user\AppData\Local\Packages\Microsoft.SkypeApp*\LocalState" -filter "main.db"

    # Outlook
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Outlook" -dest "$out\Users\$user\AppData\Local\Microsoft\Outlook" -where ".pst,.ost -eq `$_.extension"

    # User Documents - this downloads potentially a lot of data and im removing it for timeline
    #Copy-LiveResponse -path "$profile\Desktop" -dest "$out\Users\$user\Desktop" -recurse
    #Copy-LiveResponse -path "$profile\Documents" -dest "$out\Users\$user\Documents";
    #Copy-LiveResponse -path "$profile\Downloads" -dest "$out\Users\$user\Downloads" -recurse
    #Copy-LiveResponse -path "$profile\Dropbox" -dest "$out\Users\$user\Dropbox" -recurse
}


############################################################
# Browser artifacts 
############################################################
Write-Host -ForegroundColor Yellow "`tCollecting Browser artefacts"
# Internet Explorer Browser history artifact
Foreach ($User in $Users) {
    $profile = "$env:systemdrive\Users\$User"

    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Internet Explorer\Recovery" -dest "$out\Users\$user\AppData\Local\Microsoft\Internet Explorer\Recovery" -filter "*.dat" -recurse
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows\History\Low\History.IE5" -dest "$out\Users\$user\AppData\Local\Microsoft\Windows\History\Low\History.IE5" -filter "index.dat" -recurse
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5" -dest "$out\Users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.IE5" -filter "index.dat" -recurse
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Internet Explorer\Recovery" -dest "$out\Users\$user\AppData\Local\Microsoft\Internet Explorer\Recovery" -filter "*.dat" -recurse
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows\WebCache" -dest "$out\Users\$user\AppData\Local\Microsoft\Windows\WebCache"
    Copy-LiveResponse -path "$profile\AppData\Roaming\Microsoft\Windows\IEDownloadHistory" -dest "$out\Users\$user\AppData\Roaming\Microsoft\Windows\IEDownloadHistory"

    $edge = "AppData\Local\Packages\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\AC\MicrosoftEdge"
    Copy-LiveResponse -path "$profile\$edge" -dest "$out\Users\$user\$edge" -filter "spartan.edb" -recurse
    Copy-LiveResponse -path "$profileAppData\Roaming\Macromedia\FlashPlayer\#SharedObjects" -dest "$out\Users\$user\Roaming\Macromedia\FlashPlayer\#SharedObjects" -filter "*.sol"
    Copy-LiveResponse -path "$profileAppData\AppData\Roaming\Microsoft\Office\Recent" -dest "$out\Users\$user\AppData\Roaming\Microsoft\Office\Recent" -filter "index.dat"
    Copy-LiveResponse -path "$profileAppData\*\MicrosoftEdgeBackups\backups\*\DatastoreBackup" -dest "$out\Users\$user\*\MicrosoftEdgeBackups\backups\*\DatastoreBackup" -filter "spartan.edb"
    Copy-LiveResponse -path "$profileAppData\AppData\Roaming\Microsoft\Windows\Cookies" -dest "$out\Users\$user\AppData\Roaming\Microsoft\Windows\Cookies" -filter "index.dat"

    # Chrome browser history
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Cookies" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Cookies"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Current Session" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Current Session"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Favicons" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Favicons"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\History" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\History" -recurse
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Last Session" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Last Session"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Last Tabs" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Last Tabs"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Preferences" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Preferences"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Shortcuts" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Shortcuts"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Top Sites" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Top Sites"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Bookmarks" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Visited Links" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Visited Links"
    Copy-LiveResponse -path "$profile\AppData\Local\Google\Chrome\User Data\Default\Web Data" -dest "$out\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Web Data"

    # Firefox browser history
    Copy-LiveResponse -path "$profile\AppData\Roaming\Mozilla\Firefox\Profiles" -dest "$out\AppData\Roaming\Mozilla\Firefox\Profiles" -filter "*.sqlite" -recurse
}

# System Browser history
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Internet Explorer\Recovery" -dest "$out\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Internet Explorer\Recovery" -filter "*.dat" -recurse
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\History" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\History"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Temporary Internet Files" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Temporary Internet Files"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\WebCache" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\WebCache" -filter "*.dat"
Copy-LiveResponse -path "$env:systemdrive\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Cookies" -dest "$out\System32\config\systemprofile\AppData\Local\Microsoft\Windows\Cookies" -filter "index.dat" -recurse
