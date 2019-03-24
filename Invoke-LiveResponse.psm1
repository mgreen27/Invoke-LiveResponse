function Invoke-LiveResponse
{
<#
.SYNOPSIS
    A Module for Live Response and Forensic collections. 

    Name: Invoke-LiveResponse.psm1
    Version: 0.94
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
    - Results consist of the StdOut from the executed content to a Results folder as ScrtipName.txt
    - The benefit of this method is the ability to operationalise new capability easily by dropping in new content with desired StdOut.

    Both Forensic Collection and Liveresponse modes can be run:
    - Over WinRM (original use)
    - Locally by leveraging the -WriteSctiptBlock -LocalOut:$True switches
    - Invoke-LiveResponse supports Powershell 2.0 targets and above (excluding custom content)


.PARAMETER ComputerName
    Optional Parameter for Target Machine to Invoke-LiveResponse. 
    Required if accessing a remote machine over the network.

.PARAMETER Credential
    Optional Parameter to set PSSession credential. Value should be a string formatted like "domain\username". 
    A credential (this or CredentialObj param) is required if accessing a remote machine over the network.

.PARAMETER CredentialObj
    Optional Parameter to pass a Powershell credential object instead of a username/password.
    A credential (this or Credential param) is required if accessing a remote machine over the network.

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
    Specifies the UNC Path and share credentials for Forensic Collection Mode.
    e.g     -UNC "\\<UNC>\<Share>"
    or      -UNC "\\<UNC>\<Share>,<domain>\<shareuser>,<sharepassword>"
            Quotes required and input is validated. For no password or bad format, input validation will rerequest details.

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

.PARAMETER NoBase64
    Do not use base64 encoding for ForensicCopy mode Powerfrensics reflection..
    Some Prevention tools block base64 encoded content from running. This switch switches to a byte array but makes a larger script.

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
    Optional parameter to select All base collection items for ForensicCopy Mode.

.PARAMETER Custom
    Optional parameter to build collection via ..\ScriptBlock\Custom folder

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

.PARAMETER Execution
    Optional Forensic Copy Mode parameter to select collection of Evidence of Execution.

.PARAMETER Evtx
    Optional ForensicCopy Mode parameter to select collection of Windows event Logs.

.PARAMETER Reg
    Optional Forensic Copy mode parameter to select collection of registry hive files.
    Currently includes SECURITY, SOFTWARE, SAM, SYSTEM and Amcache.hve hives.
   
.PARAMETER User
    Optional Forensic Copy Mode parameter to select collection of User artefacts and registry hive files 
    Currently includes ntuser.dat and UsrClass.dat

.PARAMETER Vss
    Optional parameter to select collection of Volume ShadowCopy Service artefacts for selected collections. 
    Currently mounts via symlink so some small forensic cost to consider. 

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
        [Parameter(Mandatory = $False)][String]$ComputerName,
        [Parameter(Mandatory = $False)][String]$Credential,
        [Parameter(Mandatory = $False)][ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$CredentialObj,
        [Parameter(Mandatory = $False)][String]$Authentication,
        [Parameter(Mandatory = $False)][String]$Port,
        [Parameter(Mandatory = $False)][Switch]$useSSL,
        [Parameter(Mandatory = $False)][String]$Map,
        [Parameter(Mandatory = $False)][String]$UNC,
        [Parameter(Mandatory = $False)][String]$LocalOut,
        [Parameter(Mandatory = $False)][Switch]$WriteScriptBlock,
        [Parameter(Mandatory = $False)][Switch]$NoBase64,
        [Parameter(Mandatory = $False)][String]$Raw,
        [Parameter(Mandatory = $False)][String]$Copy,
        [Parameter(Mandatory = $False)][Switch]$All,
        [Parameter(Mandatory = $False)][Switch]$Custom,
        [Parameter(Mandatory = $False)][Switch]$Mem,
        [Parameter(Mandatory = $False)][Switch]$Disk,
        [Parameter(Mandatory = $False)][Switch]$Mft,
        [Parameter(Mandatory = $False)][Switch]$Usnj,
        [Parameter(Mandatory = $False)][Switch]$Pf,
        [Parameter(Mandatory = $False)][Switch]$Execution,
        [Parameter(Mandatory = $False)][Switch]$Reg,
        [Parameter(Mandatory = $False)][Switch]$Evtx,
        [Parameter(Mandatory = $False)][Switch]$User,
        [Parameter(Mandatory = $False)][Switch]$Vss,
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
    $Execution = $PSBoundParameters.ContainsKey('Execution')
    $Mft = $PSBoundParameters.ContainsKey('Mft')
    $Usnj = $PSBoundParameters.ContainsKey('Usnj')
    $Pf = $PSBoundParameters.ContainsKey('Pf')
    $Reg = $PSBoundParameters.ContainsKey('Reg')
    $User = $PSBoundParameters.ContainsKey('User')
    $Custom = $PSBoundParameters.ContainsKey('Custom')
    $NoBase64 = $PSBoundParameters.ContainsKey('NoBase64')

    $Vss = $PSBoundParameters.ContainsKey('Vss')

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
    If (!$WriteScriptBlock) {
        If (!$ComputerName) {
            $ComputerName = Invoke-InputValidation -ComputerName
        }
        
        If (!$CredentialObj -and !$Credential) {
            $Cred = Invoke-InputValidation -Credential
        } 
        Elseif ($CredentialObj) {
            $Cred = $CredentialObj
        }
        Elseif ($Credential) {
            $Cred = $Credential
        }
    }
    
    If ($Raw -Or $Copy -Or $Mft -Or $Usnj -Or $Pf -Or $Execution -Or $Reg -Or $Evtx -Or $User -Or $Disk -Or $Mem -Or $All -Or $Custom){
        $ForensicCopy = $True
		If (!$LocalOut) {
			If (!$UNC){$UNC = $True}
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
    $sbStart = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbStart.ps1" -raw))


    # Path configuration  - will be included in all ForensicCopy and -LocalOut:$true sessions
    if ($LocalOut) {
        $sbPath = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbPathLocal.ps1" -raw))

        # adding in some logic to cover netowrk localout usecases
        If ($LocalOut -ne $True) {
            $sbPath = [ScriptBlock]::Create("`n`$Map = `"$LocalOut`"" + $sbPath.ToString())
        }
        Else { 
            $sbPath = [ScriptBlock]::Create("`n`$Map = `$((Get-Location).Path)" + $sbPath.ToString())
        }
        
    }
    Else {
        $sbPath = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbPathUnc.ps1" -raw))
        $sbPath = [ScriptBlock]::Create("`n`$Unc = `"$Unc`"`n" + $sbPath.ToString())
    }

    $Scriptblock = [ScriptBlock]::Create($sbStart.ToString() + $sbPath.ToString())

    # MemoryDump
    If ($Mem -Or $All) { 
        $sbmemory = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbMemory.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbMemory.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`t`Memory Dump`n"
    }


    # PowerForensics - reflectively loads PF if Raw collection configured
    If ($Raw -Or $Mft -Or $Usnj -Or $Evtx -Or $Execution -Or $Reg -Or $User -Or $Disk -Or $All -Or $Custom){
        # Some EDR will prevent base64 reflection if -NoBase64 switch set, use byte array only. Byte array is larger size so giving option to configure both
        If ($NoBase64) { $sbPowerForensics = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbPowerForensicsNoBase64.ps1" -raw)) }
        Else { $sbPowerForensics = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbPowerForensics.ps1" -raw)) }

        $sbForensicCopy = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbForensicCopy.ps1" -raw))

        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbPowerForensics.ToString() + $sbForensicCopy.ToString())
        $PowerForensics = $True


        }

    # Add Copy-LiveResponse for ForensicCopy mode copy usecases
    If ($ForensicCopy -Or $Pf -Or $Copy){
        $sbCopyLiveResponse = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbCopyLiveResponse.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbCopyLiveResponse.ToString())
    }

    # Add Volume Shadow Copy for VSC collection usecases
    If ($Vss){
        $sbVssMount = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbVssMount.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbVssMount.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`t`Volume Shadow Copy`n"
    }

    # $MFT collection
    If ($Mft -Or $Disk -Or $All){
        $sbMft = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbMft.ps1" -raw))       
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbMft.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`t`$MFT`n"
    }

    # $LogFile collection
    If ($Disk -Or $All ){
        $sbLogFile = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbLogfile.ps1" -raw))    
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbLogFile.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`t`$LogFile`n"
    }    

    # Dump of USNJrnl
    If ($Usnj -Or $Disk -Or $All){
        $sbUsnj = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbUsnj.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbUsnj.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tUsnJournal:`$J`n" 
    }

    # Prefetch
    If ($Pf -And !$All -And !$Execution){
        $sbPf = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbPrefetch.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbPf.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tPrefetch files`n"
    }

    # Execution
    If ($Execution -Or $All){
        $sbExecution = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbExecution.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbExecution.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tEvidence of Execution`n"
    }

    # Registry Hive collection
    If ($Reg -Or $All){
        $sbReg = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbReg.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbReg.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tRegistry Hives`n"
    }
    
    # Windows EventLog collection    
    If ($Evtx -Or $All){
        $sbEvtx = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbEvtx.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbEvtx.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tWindows Event Logs`n"
    }

    # User artefact collection
    If ($User -Or $All){
        $sbUser = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\sbUser.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbUser.ToString())
        $ForensicCopyText = $ForensicCopyText + "`t`tUser Artefacts`n"
    }

    # Copy-Item scriptblock needs to be generated at build time
    If ($Copy) {
        $sbCopy = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbCopy.ps1" -raw))
        $sbCopy = [ScriptBlock]::Create("`n`$Copy = `"" + $Copy + "`"`n" + $sbCopy.ToString())
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbCopy.ToString())

        $CopyCount = $Copy.Split(",").count
        $ForensicCopyText = $ForensicCopyText + "`t`tCopy-Item $CopyCount Items`n"
    }

    #  RawFile Copy scriptblock needs to be generated at build time
    If ($Raw) {
        $sbRawCopy = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbRawCopy.ps1" -raw))
        $sbRawCopy = [ScriptBlock]::Create("`n`$Raw = `"" + $Raw + "`"`n" + $sbRawCopy.ToString())
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbRawCopy.ToString())

        $CopyCount = $Raw.Split(",").count
        $ForensicCopyText = $ForensicCopyText + "`t`tRawCopy $CopyCount Items`n"
    }


    #  Custom collection of scriptblocks added to ..\scriptblock\custom folder
    If ($Custom) {
        $CustomContent = (Get-ChildItem -Path "$PSScriptRoot\Content\Scriptblock\Custom" -Filter "*.ps1").FullName
        if ($CustomContent) {
            Foreach ($script in $CustomContent) {
                $sbCustom = [System.Management.Automation.ScriptBlock]::Create((get-content $script -raw))
                $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbCustom.ToString())

                $ForensicCopyText = $ForensicCopyText + "`t`tCustom " + (split-path $script -Leaf) + "`n"
            }
        }
        Else {
            Write-Host -ForegroundColor White "`nInvoke-LiveResponse: -Custom content not found."
            Write-Host "Check $PSScriptRoot\Content\Scriptblock\Custom`n"
            break
        }

    }

    # Unmount Volume Shadow Copy
    if ($Vss) {
        $sbVssUnmount = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbVssUnmount.ps1" -raw))
        $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbVssUnmount.ToString())
    }

    # View ForensicCopy collected files
    $sbViewCollection = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbViewCollection.ps1" -raw))
    $Scriptblock = [ScriptBlock]::Create($Scriptblock.ToString() + $sbViewCollection.ToString())

    # Unmap share
    if (!$LocalOut) {
        $ScriptBlock = [ScriptBlock]::Create($Scriptblock.ToString() + "`n`n`$net.RemoveNetworkDrive(`$Map,`$true,`$true)`n")
	}



#### Main ####

    # WriteScriptBlock for local collection and testing
    if ($WriteScriptBlock) {
        $LocalScriptBlock = [ScriptBlock]::Create("Write-Host -ForegroundColor Cyan `"Starting Invoke-LiveResponse.`"`nWrite-Host -ForegroundColor White `"``tLocal Mode.`"`n")

        if ($ForensicCopy) {
            $LocalScriptBlock = [ScriptBlock]::Create($LocalScriptBlock.ToString() + "Write-Host -ForegroundColor Cyan `"Starting ForensicCopy.`"`n" + "`n" + $ScriptBlock.ToString())
        }

        if ($LR) {
            $sbLocalLiveResponse = [System.Management.Automation.ScriptBlock]::Create((get-content "$PSScriptRoot\Content\Scriptblock\base\sbLocalLiveResponse.ps1" -raw))
            $LocalScriptblock = [ScriptBlock]::Create($LocalScriptblock.ToString() + "`n" + $sbLocalLiveResponse.ToString())
        }
		$LocalScriptblock | Out-String -Width 4096 | Out-File "$(Get-Location)\$($date)_Invoke-LiveResponse.ps1"
        
        Clear-Host
        Write-host -ForegroundColor Cyan "`nInvoke-LiveResponse"
        Write-Host -ForegroundColor White "`n`tWriteScriptblock"
        Write-Host -ForegroundColor White "`tScript:`t`t$(Get-Location)\$($date)_Invoke-LiveResponse.ps1"

        If ($LocalOut){ Write-Host -ForegroundColor White "`tLocalOut:`t$LocalOut" }
        Else { Write-Host -ForegroundColor White "`tUnc config:`t$Unc" }
        Write-Host -ForegroundColor White "`nTo view script: Get-Content $(Get-Location)\$($date)_Invoke-LiveResponse.ps1`n"
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
            If ($LocalOut) { Write-Host "`tLocalOut Path: " $LocalOut }
            Else { Write-Host "`tUNC Path: " $UNC.split(',')[0] }

            Write-Host "`tTo .\$date`Z_$Target`n"
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
        [Parameter(Mandatory = $False)][Switch]$ComputerName,
        [Parameter(Mandatory = $False)][Switch]$Credential
        )

    If ($UNC) {
        while ($UNC.split(',')[0] -notmatch "\\\\([\w\-\.]+|\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b)\\[\w\-\.]+"`
            -or $UNC.split(',')[1] -notmatch "([a-zA-Z][a-zA-Z0-9\-\.]{0,61}[a-zA-Z]\\\w[\w\.\- ]*)?"`
            -or $UNC.split(',')[2] -notmatch "(\w+)?" -or !($Map.split(',').Length -eq 1 -or 3)){
            Clear-Host
            Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
            Write-Host -ForegroundColor Yellow "Input validation ForensicCopy -UNC"
            Write-Host "Enter UNC path and credentials required to run Net Use command on $ComputerName"
            Write-Host "e.g`t\\<Servername or IP>\Share,<domain>\<username>,<password>"
            Write-Host "or `t\\<Servername or IP>\Share"
            $UNC = Read-Host -Prompt "UNC path and credentials"
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
    
    If ($ComputerName){
        Clear-Host
        Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
        Write-Host -ForegroundColor Yellow "Input validation LiveResponse -ComputerName - no parameter entered for remote connection"
        Write-Host "Enter fully qualified computer name as the remote target for Invoke-LiveResponse"
        Write-Host "e.g workstation.example.local"
        $ComputerNameAdded = Read-Host -Prompt "Enter remote computer name"
        Clear-Host
        return $ComputerNameAdded
    }

    If ($Credential){
        Clear-Host
        Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
        Write-Host -ForegroundColor Yellow "Input validation LiveResponse -Credential - no parameter entered for remote connection"
        Write-Host "Enter <domain>\<username> to use to map to $Computername"
        Write-Host "e.g example.local\dfir"
        $Cred = Get-Credential
        Clear-Host
        return $Cred
    }
}

