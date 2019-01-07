function Invoke-LiveResponse
{
<#
.SYNOPSIS
    A Module for Live Response and Forensic collections. 

    Name: Invoke-LiveResponse.psm1
    Version: 0.87
    Author: Matt Green (@mgreen27)

.DESCRIPTION
    The current scope of Invoke-LiveResponse is a live response tool for targeted collection.
    There are two main modes of use in Invoke-LiveResponse and both are configured by a variety of command line switches.

    Forensic Collection
    - Reflectively load Powerforensics onto target machine to enable raw disk access.
    - Leverages a scriptblock for each configured function of the script. 
    - Depending on the selected switches, each selected capability is joined at run time to build the scriptblock pushed out to the target machine. 

    Live Response
    - LiveResponse mode will execute any Powershell scripts placed inside a content folder.
    - Results consist of the StdOut from the executed content > redirected from the collection machine to a local Results folder as ScrtipName.txt
    - The benefit of this method is the ability to operationalise new capability easily by dropping in new content with desired StdOut.

    Both Forensic Collection and Liveresponse modes can be run:
    - Over WinRM (original use)
    - Locally by leveraging the -WriteSctiptBlock -LocalOut:$True switches

    Gotchas
    - MaxMemoryPerShellMB settings will need to change on Powershell 2.0 targets for LiveResponse content, up from 150MB.
    - Please set to 0 (off) or 1024 in Powershell 2.0, Powershell 3.0 and above should be appropriately configured for WinRM use.
    - Invoke-MaxMemory is a quick and dirty module to set MaxMemoryPerShell to 0, use -Legacy for Windows 7 machines.

    Todo:
    - Add additional artefacts into ForensicCopyMode
    - Expand scope to enable at scale enterprise wide detection/hunting through Powershell Start-Job capabilities.

.PARAMETER ComputerName
    Mandatory Parameter for Target Machine to Invoke-LiveResponse

.PARAMETER Credential
    Optional Parameter to set PSSession credential. Value should be a string formatted like "domain\username". Must either use this or CredentialObj param. 

.PARAMETER CredentialObj
    Optional Parameter to pass a Powershell credential object instead of a username/password. Must either use this or Credential param.

.PARAMETER Authentication
    Optional parameter for specifying Authentication method

.PARAMETER Port
    Optional parameter for specifying Port. Default standard port is 5985, or 5986 for useSSL.

.PARAMETER useSSL
    Optional parameter for specifying to UseSSL certificates as per PSSession configuration.
    Note WinRM traffic is encrypted even without this flag.

.PARAMETER Map
    Specifies the drive letter to map during Forensic Collection mode Net Use command.
    e.g T:

.PARAMETER UNC
    Specifies the Net use UNC Path and share credentials for Forensic Collection Mode.
    e.g     -UNC "\\<UNC>\<Share>"
    or      -UNC "\\<UNC>\<Share> /user:<domain>\<shareuser> <sharepassword>"
            Quotes required for long command. Input is validated.

.PARAMETER LocalOut
    Two use cases:
    1) Used in combination with -WriteScriptBlock to build a local Invoke-LiveResponse script.
    e.g -LocalOut:$True -WriteSciptBlock will write a ps1 file to run from LiveResponse USB / System management tool.
    
    2) Specifies a local folder on the remote system as a destination for Forensic Collection results.
    Use in place of -Map and -UNC flags.
    Note: Do not use lightly! Writing this data to a local drive *will* overwrite some slack space. 
    Should be used only as a last resort for data collection, such as when shares are unavailable. 
    e.g.	-LocalOut "C:\tmp\collection"
    
.PARAMETER WriteScriptBlock
    Writes a .ps1 file containing the script that would be run on the remote host.
    Note: Does not connect to the remote host.
    Useful for troubleshooting or for creating a script that will be manually run on a host without WinRM configured.
    Script will be located in the current working directory (Get-Location) and will be named: <date>_Invoke-LiveResponse.ps1

.PARAMETER Raw
    Specifies Files to collect for Forensic Collection Mode in comma seperated format.
    File will leverage Powerforensics to raw copy items. Quotes reccomended for long path, required for csv.
    For folders all contents will be copied, however there is no capability to recursively download or root folders - e.g "D:\" currently.
    e.g     -Raw "C:\Users\<user>\AppData\Local\Temp\evil.vbs"
    or      -Raw "C:\Users\<user>\AppData\Local\Temp\evil.vbs,C:\Windows\System32\evil.exe,c:\folder\to\copy"

.PARAMETER Copy
    Specifies Files to collect for Forensic Collection Copy-Item Mode in comma seperated format.
    As the name suggests, Copy-Item Mode copies files using Powershell CopyItem instead of Powerforensics.
    For folders all contents will be copied, however there is no capability to recursively download or root folders - e.g "D:\" currently.
    Quotes reccomended for long path, required for csv
    e.g     -Copy "C:\Users\<user>\AppData\Local\Temp\evil.vbs"
    or      -Copy "C:\Users\<user>\AppData\Local\Temp\evil.vbs,C:\Windows\System32\evil.exe,c:\folder\to\copy"

.PARAMETER All
    Optional parameter to select All collection items for ForensicCopy Mode.

.PARAMETER Mem
    Optional parameter to select Memory collection for ForensicCopy Mode. Default uses Winpmem - winpmem-2.1.post4.exe (latest and greatest) which is requried on UNC path or LocalOut path.

.PARAMETER Disk
    Optional parameter Forensic Copy Mode to select collection of $MFT, UsnJournal:$J and $LogFile.

.PARAMETER Mft
    Optional parameter Forensic Copy Mode to select collection of $MFT.

.PARAMETER Usnj
    Optional Forensic Copy Mode parameter parameter to select collection of UsnJournal:$J. Currently configured to drop sparse (null) clusters and revert back to fsutil collection if required.

.PARAMETER Pf
    Optional Forensic Copy Mode parameter to select collection of prefetch files. Pf uses Copy-Item command-let and does not invoke installation of Powerforensics if run alone.

.PARAMETER Evtx
    Optional ForensicCopy Mode parameter to select collection of Windows event Logs.

.PARAMETER Reg
    Optional Forensic Copy mode parameter to select collection of registry hive files.
    Currently includes SECURITY, SOFTWARE, SAM, SYSTEM and Amcache.hve hives.
   
.PARAMETER User
    Optional Forensic Copy Mode parameter to select collection of User artefacts and registry hive files 
    Currently includes ntuser.dat and UsrClass.dat

.PARAMETER LR
    An optional parameter to select Live Response mode. LiveResponse mode will execute any Powershell scripts placed inside a content folder and output to a Results folder on the collector machine.
    
    Default paths:
    C:\Users\Matt.DFIR\Documents\WindowsPowerShell\Modules\Invoke-LiveResponse\Content
    C:\Users\Matt.DFIR\Documents\WindowsPowerShell\Modules\Invoke-LiveResponse\Results
    
.PARAMETER Content
    An optional Live Response mode parameter that specifies the local Collector path of the script content folder in Live Response mode.
    e.g c:\Cases\scripts

.PARAMETER Results
    An optional Live Response parameter that specifies the local Collector path of the Results folder in Live Response mode. Can be UNC path or share.
    e.g c:\Cases

.PARAMETER csv
    Optional parameter for specifying Live Response Output in CSV

.PARAMETER Shell
    An Optional switch to invoke Shell mode instead of closing PSSession after collection. Shell mode leaves the PSSession open and allows user to Enter-PSSession for manual tasks.

.EXAMPLE
    Invoke-LiveResponse -ComputerName <ComputerName> -Credential <domain>\<user> -all -Map <drive>: -UNC "\\<UNC_path_or_IP>\<folder> /user:<shareuserdomain>\<shareUser> <password>"

    Starts a ForensicCopy collection with all preconfigured artefacts.
    The UNC switch is configuration of scriptblock for a UNC path of a net use command. Credentials are in the same format as net user. i.e /User:<domain>\<user>

.EXAMPLE
    Invoke-LiveResponse -ComputerName <ComputerName> -Credential <domain>\<user> -MFT -reg -Map <drive>: -UNC "\\<UNC_path_or_IP>\<folder> /user:<shareuserdomain>\<shareUser> <password>"

    Starts a ForensicCopy collection with MFT and Registry collection
      
.EXAMPLE
    Invoke-LiveResponse -ComputerName <ComputerName> -Credential <domain>\<user> -all -Map T: -UNC "\\investigator\cases /user:investigator\LiveResponse <password>" -Raw "C:\Users\<user>\AppData\Local\Temp\evil.vbs,C:\Windows\System32\evil.exe" 

    Starts a ForensicCopy collection with all preconfigured artefactsas above. Additional -Raw configures Raw file collections in csv, "" required.
    The UNC switch is configuration of scriptblock for a UNC path of a net use command. Credentials are in the same format as net user. i.e /User:<domain>\<user>

.EXAMPLE
    PS> Invoke-LiveResponse -ComputerName Win7x64 -Credential dfir\matt -Map T: -UNC "\\investigator\cases /user:investigator\LiveResponse <password>" -Copy C:\Windows\System32\winevt\Logs\Security.evtx

    Starts a ForensicCopy mode with a Copy-Item copy of the Security event log.

.EXAMPLE
    Invoke-LiveResponse -ComputerName <ComputerName> -Credential <domain>\<user> -LR

    Starts a LiveResponse collection using default Contents and Results path.
    Content = C:\Users\Matt.DFIR\Documents\WindowsPowerShell\Modules\Invoke-LiveResponse\Content
    Results = C:\Users\Matt.DFIR\Documents\WindowsPowerShell\Modules\Invoke-LiveResponse\Results

.EXAMPLE
    Invoke-LiveResponse -ComputerName <ComputerName> -Credential <domain>\<user> -LR -Content C:\Cases\Scripts -Result c:\Cases

    Starts a LiveResponse collection using a configured Contents and Results path.

.LINK
    https://github.com/Invoke-IR/PowerForensics
    https://github.com/mgreen27/Powershell-IR
    https://github.com/google/rekall/releases/tag/v1.5.1
    
.NOTES
    Assuming WinRM configured appropriately, credential risk is mitigated with Kerberos delegation
     PowerForensics no longer a prerequisite as we have forked/embedded Add-PowerForensicsType
    Currently either open share or hardcoded auth for netuse command in scriptblock.
    Do not turn CredSSP on for IR use cases! Best practice would be to create a local account with access to the share and utilise those credentials in script.
    Powershell 5.0+ allows for "Copy-Item -FromSession" over PSSession to reduce the need for "Net use".
    Winpmem-2.1.post4.exe can be downloaded from https://github.com/google/rekall/releases/tag/v1.5.1 and needs to be placed in UNC path or LocalOut path specified in ForensicCopy mode.

    Thank you to:
        @jaredcatkinson PowerForensics - https://github.com/Invoke-IR/PowerForensics
        Kansa project - https://github.com/davehull/Kansa
        All Powershell contributors.
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)][String]$ComputerName,
        [Parameter(Mandatory = $False)][String]$Credential,
        [Parameter(Mandatory = $False)][ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$CredentialObj,
        [Parameter(Mandatory = $False)][String]$Authentication,
        [Parameter(Mandatory = $False)][String]$Port,
        [Parameter(Mandatory = $False)][Switch]$useSSL,
        [Parameter(Mandatory = $False)][String]$Map,
        [Parameter(Mandatory = $False)][String]$UNC,
        [Parameter(Mandatory = $False)][String]$LocalOut,
        [Parameter(Mandatory = $False)][Switch]$WriteScriptBlock,
        [Parameter(Mandatory = $False)][String]$Raw,
        [Parameter(Mandatory = $False)][String]$Copy,
        [Parameter(Mandatory = $False)][Switch]$All,
        [Parameter(Mandatory = $False)][Switch]$Mem,
        [Parameter(Mandatory = $False)][Switch]$Disk,
        [Parameter(Mandatory = $False)][Switch]$Mft,
        [Parameter(Mandatory = $False)][Switch]$Usnj,
        [Parameter(Mandatory = $False)][Switch]$Pf,
        [Parameter(Mandatory = $False)][Switch]$Reg,
        [Parameter(Mandatory = $False)][Switch]$Evtx,
        [Parameter(Mandatory = $False)][Switch]$User,
        [Parameter(Mandatory = $False)][Switch]$LR,
        [Parameter(Mandatory = $False)][String]$Content,
        [Parameter(Mandatory = $False)][String]$Results,
        [Parameter(Mandatory = $False)][Switch]$Csv,
        [Parameter(Mandatory = $False)][Switch]$Shell
        )

    # Set switches
    $Shell = $PSBoundParameters.ContainsKey('Shell')
    $useSSL = $PSBoundParameters.ContainsKey('useSSL')

    # Forensic Collection
    $All = $PSBoundParameters.ContainsKey('All')
    $Mem = $PSBoundParameters.ContainsKey('Mem')
    $Disk = $PSBoundParameters.ContainsKey('Disk')
    $Evtx = $PSBoundParameters.ContainsKey('Evtx')
    $Mft = $PSBoundParameters.ContainsKey('Mft')
    $Usnj = $PSBoundParameters.ContainsKey('Usnj')
    $Pf = $PSBoundParameters.ContainsKey('Pf')
    $Reg = $PSBoundParameters.ContainsKey('Reg')
    $User = $PSBoundParameters.ContainsKey('User')

    # Live Response
    $LR = $PSBoundParameters.ContainsKey('LR')
    $Csv = $PSBoundParameters.ContainsKey('Csv')

    # Set WinRM Defaults for Auth and Port
    If (!$Authentication){$Authentication = "Kerberos"}
    If ($useSSL -And !$Port){$Port = "5986"}
    If (!$Port){$Port = "5985"}

    # Default Live Response paths are location of module
    $Date = get-date ([DateTime]::UtcNow) -format yyyy-MM-dd
    $ScriptDir = Split-Path (Get-Module Invoke-LiveResponse).Path
    If (!$Results){$Results = "$ScriptDir\Results"}
    If (!$Content){$Content = "$ScriptDir\Content"}

    # Input validation
    If (!$CredentialObj -and !$Credential) {
        $Cred = Invoke-InputValidation -Credential
    } 
	Elseif ($CredentialObj) {
		$Cred = $CredentialObj
    }
	Elseif ($Credential) {
		$Cred = $Credential
    }
    
    If ($Raw -Or $Copy -Or $Mft -Or $Usnj -Or $Pf -Or $Reg -Or $Evtx -Or $User -Or $Disk -Or $Mem -Or $All){
        $ForensicCopy = $True
		If (!$LocalOut) {
			If (!$Map){$Map = $True}
			If (!$UNC){$UNC = $True}
			$Map = Invoke-InputValidation -Map $Map
			$UNC = Invoke-InputValidation -UNC $UNC
		}
		Else {
            $Map = $LocalOut.TrimEnd('\')

            # if LocalOut:True set and no writescriptblock throw notification and break 
            If ($LocalOut -eq $True -and (!$WriteScriptBlock)) {
                    Write-Host -ForegroundColor Yellow "`nPlease configure a folder for Invoke-LiveResponse -LocalOut over WinRM."
                    break   
            }
		}
    }

    If ($LR){
        $Results = Invoke-InputValidation -Results $Results
        $Content = Invoke-InputValidation -Content $Content
    }

    # Other variables
    $Results = "$Results\$date`Z_"
    $PowerForensics = $False

    # Shell mode 
    If (!$ForensicCopy -And !$LR){
        Write-Host -ForegroundColor Yellow "`tNo collections specified - would you like a shell?"
        $Readhost = Read-Host "`ty / n " 

        Switch ($ReadHost) { 
            Y {Write-host "Yes, why not just Enter-PSSEssion next time?"; $Shell=$true} 
            N {Write-Host "No, get me outta here!"; $Shell=$false} 
            Default {Write-Host "No, default is no!"; $Shell=$false} 
        }
         
        If(!$Shell){break}
    }

    
    ### Script block configuration - i.e Stuff to run on remote machine/s
    $Scriptblock = $null
    
    # Start output string
    $ForensicCopyText = "`tForensicCopy Items:`n"

    # CPU Priority - will be included in all Invoke-Liveresponse Scriptblocks
    $sbPriority = [ScriptBlock]::Create("`$Process = Get-Process -Id `$Pid`n`$Process.PriorityClass = 'IDLE'`n")

    # Path configuration  - will be included in all ForensicCopy sessions
    $sbPath = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbPath.ps1" -raw))

    if ($LocalOut -ne $True) {
        $sbPath2 =  [ScriptBlock]::Create("`ncmd /c net use $Map $UNC > null 2>&1`n`n")
        $sbPath3 =  [ScriptBlock]::Create("If (!(Test-Path $Map)) {Write-Host -ForegroundColor Red `"Error: Check UNC path and credentials. Unable to Map $Map`";break}`n")
        $sbPath =  [ScriptBlock]::Create("`n`$Map = '$Map'" + $sbpath2.toString() + $sbpath3.toString() + $sbpath.toString())
    }
    Else {
        $sbPath =  [ScriptBlock]::Create("`n`$Map = `$((Get-Location).Path)`n" + $sbpath.toString())
    }
        
    $Scriptblock = [ScriptBlock]::Create($sbPriority.ToString() + $sbPath.ToString())


    # MemoryDump
    If ($Mem -Or $All) { 
        $sbmemory = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbMemory.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbMemory.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`t`Memory Dump`n"
    }


    # PowerForensics - reflectively loads PF if Raw collection configured

    If ($Raw -Or $Mft -Or $Usnj -Or $Evtx -Or $Reg -Or $User -Or $Disk -Or $All){
        $sbPowerForensics = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbPowerForensics.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbPowerForensics.ToString())
        $PowerForensics = $True
        }


    # Add Invoke-BulkCopy for bulk copy usecases
    If ($ForensicCopy){
        $sbBulkCopy = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbBulkCopy.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbBulkCopy.ToString())
    }

    # $MFT collection
    If ($Mft -Or $Disk -Or $All){
        $sbMft = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbMft.ps1" -raw))       
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbMft.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`t`$MFT`n"
    }

    # $LogFile collection
    If ($Disk -Or $All ){
        $sbLogFile = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbLogfile.ps1" -raw))    
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbLogFile.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`t`$LogFile`n"
    }    

    # Dump of USNJrnl
    If ($Usnj -Or $Disk -Or $All){
        $sbUsnj = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbUsnj.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbUsnj.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tUsnJournal:`$J`n" 
    }

    # Prefetch
    If ($Pf -Or $All){
        $sbPf = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbPrefetch.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbPf.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tPrefetch files`n"
    }

    # Registry Hive collection
    If ($Reg -Or $All){
        $sbReg = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbReg.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbReg.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tRegistry Hives`n"
    }
    
    # Windows EventLog collection    
    If ($Evtx -Or $All){
        $sbEvtx = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbEvtx.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbEvtx.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tWindows Event Logs`n"
    }

    # User artefact collection, currently user hives only
    If ($User -Or $All){
        $sbUser = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbUser.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbUser.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tUser Artefacts`n"
    }

    # Copy-Item scriptblock needs to be generated at build time
    If ($Copy) {
        $sbCopy = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbCopy.ps1" -raw))
        $sbCopy = [ScriptBlock]::Create("`n`$Copy = `"" + $Copy + "`"`n" + $sbCopy.ToString())
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbCopy.ToString())

        $CopyCount = $Copy.Split(",").count
        $ForensicCopyText = $ForensicCopyText + "`t`tCopy-Item $CopyCount Items`n"
    }

    #  RawFile Copy scriptblock needs to be generated at build time
    If ($Raw) {
        $sbRawCopy = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbRawCopy.ps1" -raw))
        $sbRawCopy = [ScriptBlock]::Create("`n`$Raw = `"" + $Raw + "`"`n" + $sbRawCopy.ToString())
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbRawCopy.ToString())

        $CopyCount = $Raw.Split(",").count
        $ForensicCopyText = $ForensicCopyText + "`t`tRawCopy $CopyCount Items`n"
    }

    # View ForensicCopy collected files
    $sbViewCollection = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbViewCollection.ps1" -raw))
    $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbViewCollection.ToString())

    # Unmap share
    if (!$LocalOut) {
		$sbUnMap = [ScriptBlock]::Create("`nnet use " + $Map + " /DELETE /Y | Out-Null`n")	
		$Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbUnMap.ToString())
	}



#### Main ####

    # WriteScriptBlock for local collection and testing
    if ($WriteScriptBlock) {
        $LocalScriptBlock = [ScriptBlock]::Create("Write-Host -ForegroundColor Cyan `"Starting Invoke-LiveResponse.`"`nWrite-Host -ForegroundColor White `"``tLocal Mode.`"`n")

        if ($ForensicCopy) {
            $LocalScriptBlock = [ScriptBlock]::Create($LocalScriptBlock.ToString() + "`nWrite-Host -ForegroundColor Cyan `"Starting ForensicCopy.`"`n" + "`n" + $ScriptBlock.ToString())
        }

        if ($LR) {
            $sbLocalLiveResponse = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Scriptblock\sbLocalLiveResponse.ps1" -raw))
            $LocalScriptblock = [ScriptBlock]::Create($LocalScriptblock.ToString() + "`n" + $sbLocalLiveResponse.ToString())
        }
		$LocalScriptblock | Out-String -Width 4096 | Out-File "$(Get-Location)\$($date)_Invoke-LiveResponse.ps1"
	}
    # WinRM execution
    else {
        Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse"
        
        # Firstly test We can connect
        $Test=$null

        Write-Host "`n`tTesting WinRM is enabled on $ComputerName " -NoNewline
        If(!$useSSL) {
            $Test = [bool](Test-WSMan -ComputerName $ComputerName -Port $Port -ErrorAction SilentlyContinue)
        }
        ElseIf($useSSL) {
            $Test = [bool](Test-WSMan -ComputerName $ComputerName -Port $Port -UseSSL -ErrorAction SilentlyContinue)
        }

        # If test OK continue. Using Test as Results in better error handling.
        If ($Test -eq "True") {
            Write-Host -ForegroundColor DarkCyan "SUCCESS`n"
        }
        Else{
            Write-Host -ForegroundColor Red "FAILED`n"
            Write-Host "Can not connect to $ComputerName over WinRM... check Target exists and WinRM enabled`n"
            break
        }
            
        Try{
            Write-Host "`tStarting PSSession on $ComputerName " -NoNewline
            If(!$useSSL) {
                $Session = New-PSSession -ComputerName $ComputerName -Port $Port -Credential $Cred -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile) -ErrorAction Stop
            }
            ElseIf($useSSL) {
                $Session = New-PSSession -ComputerName $ComputerName -UseSSL -Port $Port -Credential $Cred -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile)  -ErrorAction Stop
            }
            Write-Host -ForegroundColor DarkCyan "SUCCESS`n"
            Write-Host -ForegroundColor Cyan "PSSession with $ComputerName as $Cred"

            #Pulling Target name for LR and notification
            $Target = Invoke-Command -Session $Session -Scriptblock {$env:computername}
        }
        Catch{
            Write-Host -ForegroundColor Red "FAILED`n"
            Write-Host "$_`n"
            Break
        }

        If($ForensicCopy) {
            Write-Host -ForegroundColor Cyan "`nStarting ForensicCopy over WinRM..."
            Write-Host "`tUNC Path: " $UNC.split()[0]
            Write-Host "`tAs $Map\$date`Z_$Target`n"
            Write-Host $ForensicCopyText

            # Execute collated scriptblock
            Invoke-Command -Session $Session -Verbose -Scriptblock $Scriptblock

            Write-Host -ForegroundColor Cyan "ForensicCopy over WinRM complete`n"
        }
        
        If($LR) {
            Write-Host -ForegroundColor Cyan "`nStarting LiveResponse over WinRM..."
            Write-Host "`tFrom Content `n`t$Content"
            Write-Host "`tNote: Error handling during LiveResponse mode is required to be handled in content.`n"
            $Results = $Results + $Target + "_LR"
            Write-Host "`tTo Results `n`t$Results`n"
            $LocalOut = "`$((Get-Location).Path)"

            $Scripts = Get-ChildItem -Path "$Content\*.ps1"

            If (Test-Path $Results) {Remove-Item $Results -Recurse -Force -ErrorAction SilentlyContinue | Out-Null}
            New-Item $Results -type directory -ErrorAction SilentlyContinue | Out-Null

            Foreach ($Script in $Scripts) {
                Write-Host -ForegroundColor Yellow "`tRunning " $Script.Name
                
                Invoke-Command -Session $Session -Scriptblock {[gc]::collect()}

                # depending on Content we can strip properties from Format-List results with | Select-Object below
                try{$ScriptResults = Invoke-Command -Session $Session -FilePath $Script.FullName -ErrorAction Stop} #| Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceID
                catch{
                    Write-Host -ForegroundColor Red "`tError in $script"
                    $ScriptResults = $Null
                }

                If (!$csv) {
                    $ScriptResults | Out-File ($Results + "\" + $Script.BaseName + ".txt")
                }
                ElseIf ($csv) {
                    $delim = ","
                    $ScriptResults | convertto-csv -NoTypeInformation | % { $_ -replace "`"$delim`"", "$delim"} | % { $_ -replace "^`"",""} | % { $_ -replace "`"$",""} | % { $_ -replace "`"$delim","$delim"}
                    $ScriptResults | Out-File ($Results + "\" + $Script.BaseName + ".csv") -Encoding ascii
                }
            }

            # Remove null results for simple analysis
            Foreach ($Item in (Get-ChildItem -Path $Results)) {
                If ($Item.length -eq 0){Remove-Item -Path $Item.FullName -Force}
            }
            
            If (Get-ChildItem -Path $Results -Recurse) {
                Write-Host -ForegroundColor Yellow "`nListing valid results in LiveResponse collection:"
                Get-ChildItem -Path $Results -Recurse | select-object LastWriteTimeUtc, Length, Name | Format-Table -AutoSize
            }
            Else{
                Write-Host -ForegroundColor Yellow "`nNo valid LiveResponse results"
            }

            Write-Host -ForegroundColor Cyan "`nLiveResponse over WinRM complete`n"
        }
                            
        If($Shell) {
            Write-Host -NoNewline "`nTo access PSSession shell on $ComputerName, please run "
            Write-Host -NoNewline -ForegroundColor Yellow "Get-PSSession "
            Write-Host "To view availible Session Ids"
            Write-Host -NoNewline "Run "
            Write-Host -NoNewline -ForegroundColor Yellow "Enter-PSSession -id <id> "
            Write-Host "to enter shell."
            Write-Host -NoNewline "Remember to "
            Write-Host -NoNewline -ForegroundColor Yellow "Remove-PSSession -id <id> "
            Write-Host  "when complete!`n"
            Write-Host -ForegroundColor Cyan "Leaving Invoke-LiveResponse`n"
            break
        }

        Remove-PSSession -Session $Session
    }
}


function Invoke-InputValidation
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)][String]$Map,
        [Parameter( Mandatory = $False)][String]$UNC,
        [Parameter(Mandatory = $False)][String]$Content,
        [Parameter(Mandatory = $False)][String]$Results,
        [Parameter(Mandatory = $False)][Switch]$Credential
        )

    If ($Map) {
        while ($Map -notmatch "^[a-zA-Z]\:$") {
            Clear-Host
            Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
            Write-Host -ForegroundColor Yellow "Input validation ForensicCopy -Map"
            Write-Host "Enter Drive letter to map on $Computername with `":`""
            Write-Host "e.g T:"
            $Map = Read-Host -Prompt "Drive Letter" 
        }
        Clear-Host
        return $Map
    }

    If ($UNC) {
        while ($UNC.split()[0] -notmatch "\\\\(\w+|\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b)\\\w+"`
            -or $UNC.split()[1] -notmatch "(\/user\:[a-zA-Z][a-zA-Z0-9\-\.]{0,61}[a-zA-Z]\\\w[\w\.\- ]*)?"`
            -or $UNC.split()[2] -notmatch "(\w+)?" -or !($Map.split().Length -eq 1 -or 3)){
            Clear-Host
            Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
            Write-Host -ForegroundColor Yellow "Input validation ForensicCopy -UNC"
            Write-Host "Enter UNC path and credentials required to run Net Use command on $ComputerName"
            Write-Host "e.g`t\\<Servername or IP>\Share /user:<domain>\<username> <password>"
            Write-Host "or `t\\<Servername or IP>\Share"
            $UNC = Read-Host -Prompt "Net Use UNC Path"
        }
        Clear-Host
        return $UNC            
    }

    If ($Content) {
        while ($Content -notmatch "^[a-zA-Z]:\\(((?![<>:\`"\/\\|?*]).)+((?<![ .])\\)?)*$") {
            Clear-Host
            Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
            Write-Host -ForegroundColor Yellow "Input validation LiveResponse -Content"
            Write-Host "Local folder containing Powershell content"
            Write-Host "e.g C:\scripts\dfir"
            $Content = Read-Host -Prompt "Enter content folder" 
        }
        $Content = $Content.Trim()
        $Content = $Content.TrimEnd("\")
        $Content = $Content.Trim()
        Clear-Host
        return $Content
    }
    
    If ($Results) {
        while ($Results -notmatch "^[a-zA-Z]:\\(((?![<>:\`"\/\\|?*]).)+((?<![ .])\\)?)*$"){
            Clear-Host
            Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
            Write-Host -ForegroundColor Yellow "Input validation LiveResponse -Content"
            Write-Host "Local folder to write collection results"
            Write-Host "e.g C:\cases"
            $Results = Read-Host -Prompt "Enter results folder"
        }
        $Results = $Results.Trim()
        $Results = $Results.TrimEnd("\")
        $Results = $Results.Trim()
        Clear-Host
        return $Results
    }
    
    If ($Credential){
        Clear-Host
        Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
        Write-Host -ForegroundColor Yellow "Input validation LiveResponse -Credential - no parameter entered"
        Write-Host "Enter <domain>\<username> to use to map to $Computername"
        Write-Host "e.g example.local\dfir"
        $Cred = Read-Host -Prompt "Enter <domain>\<username>"
        Clear-Host
        return $Cred
    }
}



function Invoke-StartWinRm
{
    <# 
    .SYNOPSIS 
        Starts WinRM on target system
    .DESCRIPTION
        Start WinRM and leave system as previous state
        Switches for Computername (mandatory), Cretential and PsExec
    .NOTES./win
        Author - Matt Green (@mgreen27)
    .EXAMPLE 
        PS> Invoke-StartWinRm -ComputerName Win081x64 -Credential dfir\matt
    #>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$True)]
            [String]$ComputerName,
        [Parameter(Mandatory=$True)]
            [String]$Credential
    )

    # We only need Enable-PSRemoting to setup WinRM but would like to tweak features 
    # to minimise credential risk and remove maxmemory limitations
    $installWinRM = "Enable-PSRemoting -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\Basic -Value false -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\Negotiate -Value true -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\kerberos -value true -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\CredSSP -Value false -Force;"`
        + "Restart-Service winrm -Force"

    # Execute via WMI
    $installWinRM = "cmd.exe /c powershell -command `"&{"+ $installWinRM + "}`""
    try{
        invoke-wmimethod -ComputerName $ComputerName -Credential $Credential -path win32_process -name create -argumentlist $installWinRM -ErrorAction stop
        
        Write-Host -ForegroundColor Cyan "`nInstalling WinRM over WMI. Process may take a few minutes.`n"
        Write-Host "`nTo test WinRM was installed please run: "
        Write-Host -ForegroundColor Yellow "`tTest-WSMan -Computername $ComputerName [-Credential $Credential -Authentication Kerberos|Negotiate]"
    }
    Catch{
        Write-Host -ForegroundColor Red -NoNewline "`nInvoke-StartWinRM Error: "
        Write-host "$_`n"
        Break
    }
}



function Invoke-StopWinRm
{
    <# 
    .SYNOPSIS 
        Stops WinRM on target system
    .DESCRIPTION
        Stop WinRM and leave system as previous state
    .NOTES
        Author - Matt Green (@mgreen27)
    .EXAMPLE 
        PS > Invoke-StopWinRm -ComputerName Win081x64 -Credential dfir\matt
    #>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $True)]
            [String]$ComputerName,
        [Parameter(Mandatory = $True)]
            [String]$Credential
    )

    # Running Disable-PSRemoting as well as the other components
    $removeWinRM = 'cmd.exe /c powershell -command "&{'`
        + 'Disable-PSRemoting -Force;'`
        + 'Stop-Service Winrm;Set-Service -Name WinRM -StartupType Disabled;'`
        + 'Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name LocalAccountTokenFilterPolicy -Value 0 -Type DWord;'`
        + "netsh advfirewall firewall set rule name='Windows Remote Management (HTTP-In)' new enable=no"`
        + '}"'
    
    try{
        invoke-wmimethod -ComputerName $ComputerName -Credential $Credential -path win32_process -name create -argumentlist $removeWinRM
        
        Write-Host -ForegroundColor Cyan "`nRemoving WinRM over WMI. Process may take a few minutes.`n"
        Write-Host -NoNewline "`nTo test WinRM was removed please run: "
        Write-Host -ForegroundColor Yellow  "Test-WSMan -Computername $ComputerName"
    }
    Catch{
        Write-Host -ForegroundColor Red -NoNewline "`nInvoke-StopWinRM Error: "
        Write-host "$_`n"
        Break
    }
}



function Invoke-MaxMemory
{
    <# 
    .SYNOPSIS 
       Removes WSMan MaxMemory setting on target system
    .DESCRIPTION
        Invoke-MaxMemory removes MaxMemory settings for Powershell
        The Script will setup a PSSession and set MaxMemory settings before restarting the WinRM service.
        Please use "-Legacy" switch for Powershell 2.0 support
    .NOTES
        Author - Matt Green (@mgreen27)
    .EXAMPLE 
        PS> Invoke-MaxMemory -ComputerName Win081x64 -Credential dfir\matt
    #>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $True)][String]$ComputerName,
        [Parameter(Mandatory = $True)][String]$Credential,
        [Parameter(Mandatory = $False)][String]$Authentication,
        [Parameter(Mandatory = $False)][String]$Port,
        [Parameter(Mandatory = $False)][Switch]$useSSL,
        [Parameter(ParameterSetName = "Legacy", Mandatory = $False)][Switch]$Legacy
        #Todo:[Parameter(ParameterSetName = "Enumerate", Mandatory = $False)][Switch]$Enumerate
    )

    $useSSL = $PSBoundParameters.ContainsKey('useSSL')
    $Legacy = $PSBoundParameters.ContainsKey('Legacy')
    $Enumerate = $PSBoundParameters.ContainsKey('Enumerate')

    # Set WinRM Defaults for Auth and Port    
    If (!$Authentication) {$Authentication = "Kerberos"}
    If ($useSSL -And !$Port) {$Port = "5986"}
    If (!$Port) {$Port = "5985"}

    Write-Host -ForegroundColor Yellow "`nRunning Invoke-MaxMemoryMB`n"

    If (!$Legacy){
        # Connect-WSman seems to be most reliable method of setting MaxMemoryMB
        $Scriptblock = {
            Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 0 -Force
            Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxMemoryPerShellMB 0 -Force
            Restart-Service winrm -Force
        }   
    }
    Elseif ($Legacy){
        # SCHTASKS seems to be most reliable method of setting MaxMemoryMB for legacy machines
        $Scriptblock = {
            $SetMaxMemoryMB = "cmd.exe /c powershell -command '&{Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 0 -Force;Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxMemoryPerShellMB -Value 0 -Force}'"
            $Start = (get-date).AddMinutes(2).ToString("HH:mm")
            SCHTASKS /Create /F /SC ONCE /ST $Start /TN Remove-MaxMemoryLegacy /TR $SetMaxMemoryMB
            SCHTASKS /Run /I /TN Remove-MaxMemoryLegacy
            SCHTASKS /Delete /TN Remove-MaxMemoryLegacy /F
            Restart-Service winrm -force
        }
    }
    
    If (!$useSSL){
        $Test = [bool](Test-WSMan -ComputerName $ComputerName -Port $Port -ErrorAction SilentlyContinue)
    }
    ElseIf($useSSL){
        $Test = [bool](Test-WSMan -ComputerName $ComputerName -Port $Port -UseSSL -ErrorAction SilentlyContinue)
    }

    if ($Test -eq "True"){
        Try{
            Write-Host "`tStarting PSSession on $ComputerName " -NoNewline
            If(!$useSSL){
                $Session = New-PSSession -ComputerName $ComputerName -Port $Port -Credential $Credential -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile) -ErrorAction Stop
            }
            ElseIf($useSSL){
                $Session = New-PSSession -ComputerName $ComputerName -UseSSL -Port $Port -Credential $Credential -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile)  -ErrorAction Stop
            }

            Write-Host -ForegroundColor DarkCyan "SUCCESS`n"
        }
        Catch{
            Write-Host -ForegroundColor Red "FAILED"
            Write-Host "$_`n"
            Break
        }

        Write-Host -ForegroundColor Cyan "PSSession with $ComputerName as $Credential"

        Try{
            Invoke-Command -Session $Session -Scriptblock $scriptblock -ErrorAction stop
            Write-Host -ForegroundColor Yellow  "`nInvoke-MaxMemory completed`n"
        }
        Catch{
            Write-Host "This error is thrown if there are issues running the SetMaxMemory command. Typical occurance is on legacy Powershell 2.0 machines. Currently for legacy machines local, GPO, or startup script will be required.`n";Break
        }
        Finally{
            Remove-PSSession -Session $Session
        }
    }
    Else{
        Write-Host -ForegroundColor Red "`nUnsuccessful WinRM test to $ComputerName... is WinRM installed?`n"
    }
}
