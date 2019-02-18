
function Get-StartupInfo {
<#
.SYNOPSIS
    Invoke-StartupInfor.ps1 parses StartupInfo entries.
    
    Name: Invoke-StartupInfo.ps1
    Version: 0.11
    Author: Matt Green (@mgreen27)

.DESCRIPTION
    StartupInfo has been included in modern Windows and is an altenate evidence source for ASEPs.
    StartupInfo is generated on successful startup execution.

.EXAMPLE
	Get-StartupInfo

    DiskUsage         : 432128
    ParentStartUtc    : 2019/02/18:01:20:30.8228799
    Process           : C:\ProgramData\update\update.exe
    PPID              : 2696
    ParentProcess     : explorer.exe
    CommandLine       : "C:\ProgramData\update\update.exe" /s /u /i:update.log scrob
    CpuUsage          : 19686
    PID               : 3548
    StartedInTraceSec : 37.977
    StartTimeUtc      : 2019/02/18:01:20:49.6184502


.EXAMPLE
	Get-StartupInfo -ReturnHashtables

    Name                           Value                                                                                                                                                                                                                                                                                                                                                                  
    ----                           -----                                                                                                                                                                                                                                                                                                                                                                  
    DiskUsage                      432128                                                                                                                                                                                                           
    ParentStartUtc                 2019/02/18:01:20:30.8228799                                                                                                                                                                                      
    Process                        C:\ProgramData\update\update.exe                                                                                                                                                                                 
    PPID                           2696                                                                                                                                                                                                             
    ParentProcess                  explorer.exe                                                                                                                                                                                                     
    CommandLine                    "C:\ProgramData\update\update.exe" /s /u /i:update.log scrob                                                                                                                                                     
    CpuUsage                       19686                                                                                                                                                                                                            
    PID                            3548                                                                                                                                                                                                             
    StartedInTraceSec              37.977                                                                                                                                                                                                           
    StartTimeUtc                   2019/02/18:01:20:49.6184502


.EXAMPLE
	Get-StartupInfo -path c:\cases\StartupInfo


.NOTES
    https://medium.com/dfir-dudes/startupinfo-autoruns-served-up-on-a-plate-ba2da0c753c5
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $False)][Switch]$ReturnHashtables,
    [Parameter(Mandatory = $False)][String]$Path = "$env:SystemDrive\Windows\System32\WDI\LogFiles\StartupInfo"
)

    Try { $StartupInfo = Get-ChildItem -Path $Path -Filter "*StartupInfo*.xml" -ErrorAction Stop | Select-Object -ExpandProperty FullName }
    Catch{
        "Error Parsing StartupInfo: Check path or Windows Version"
        exit
    }

    Foreach ($File in $StartupInfo){
        $File = [xml] @(Get-Content -Path $File)
        $Entries = $File.StartupData.Process
    
        Foreach ($Entry in $Entries) { 
        
            $Output = @{
                StartTimeUtc = $Entry.StartTime
                Process = $Entry.Name
                CommandLine = $Entry.CommandLine.'#cdata-section'
                PID = $Entry.PID
                ParentStartUtc = $Entry.ParentStartTime
                ParentProcess = $Entry.ParentName
                PPID = $Entry.ParentPID
                CpuUsage = $Entry.CpuUsage.'#text'
                DiskUsage = $Entry.DiskUsage.'#text'
                StartedInTraceSec = $Entry.StartedInTraceSec
            }
        
            if($ReturnHashtables) { $Output }
            else { New-Object PSObject -Property $Output }

        }
    

    }
}

Get-StartupInfo -ReturnHashtables
