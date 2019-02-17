
function Get-StartupInfo {
<#
.SYNOPSIS
    Get-StartupInfor parses StartupInfo entries.
    
    Name: Get-StartupInfo
    Version: 0.1
    Author: Matt Green (@mgreen27)

.DESCRIPTION
    StartupInfo has been included from Windows 10 <???> and is an altenate evidence source for ASEPs.

.EXAMPLE
	Get-StartupInfo

    DiskUsage       : 18711552
    ParentStartTime : 2018/07/29:08:26:45.0319383
    PPID            : 5536
    StartedInSec    : 152.080
    ProcessName     : C:\Devic
    ParentProcess   : explorer.exe
    CommandLine     : "C:\Program Files\VMware\VMware Tools\vmtoolsd.exe" -n vmusr
    StartTime       : 2018/07/29:08:27:04.3440881
    PID             : 7980
    CpuUsage        : 4820232


.EXAMPLE
	Get-StartupInfo -ReturnHashtables

    Name                           Value                                                                                                                                                                                                                                                                                                                                                                  
    ----                           -----                                                                                                                                                                                                                                                                                                                                                                  
    DiskUsage                      18711552                                                                                                                                                                                                                                                                                                                                                               
    ParentStartTime                2018/07/29:08:26:45.0319383                                                                                                                                                                                                                                                                                                                                            
    PPID                           5536                                                                                                                                                                                                                                                                                                                                                                   
    StartedInSec                   152.080                                                                                                                                                                                                                                                                                                                                                                
    ProcessName                    C:\Devic                                                                                                                                                                                                                                                                                                                                                               
    ParentProcess                  explorer.exe                                                                                                                                                                                                                                                                                                                                                           
    CommandLine                    "C:\Program Files\VMware\VMware Tools\vmtoolsd.exe" -n vmusr                                                                                                                                                                                                                                                                                                           
    StartTime                      2018/07/29:08:27:04.3440881                                                                                                                                                                                                                                                                                                                                            
    PID                            7980                                                                                                                                                                                                                                                                                                                                                                   
    CpuUsage                       4820232             


.EXAMPLE
	Get-StartupInfo -path c:\cases\StartupInfo

    DiskUsage       : 18711552
    ParentStartTime : 2018/07/29:08:26:45.0319383
    PPID            : 5536
    StartedInSec    : 152.080
    ProcessName     : C:\Devic
    ParentProcess   : explorer.exe
    CommandLine     : "C:\Program Files\VMware\VMware Tools\vmtoolsd.exe" -n vmusr
    StartTime       : 2018/07/29:08:27:04.3440881
    PID             : 7980
    CpuUsage        : 4820232


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
        "Error Parsing StartupInfo. Check path or Windows Version"
        exit
    }

    Foreach ($File in $StartupInfo){
        $File = [xml] @(Get-Content -Path $File)
        $Entries = $File.StartupData.Process
    
        Foreach ($Entry in $Entries) { 
        
            $Output = @{
                StartTime = $Entry.StartTime
                ProcessName = $Entry.Name
                CommandLine = $Entry.CommandLine.'#cdata-section'
                PID = $Entry.PID
                ParentStartTime = $Entry.ParentStartTime
                ParentProcess = $Entry.ParentName
                PPID = $Entry.ParentPID
                CpuUsage = $Entry.CpuUsage.'#text'
                DiskUsage = $Entry.DiskUsage.'#text'
                StartedInSec = $Entry.StartedInTraceSec
            }
        
            if($ReturnHashtables) { $Output }
            else { New-Object PSObject -Property $Output }

        }
    

    }
}

Get-StartupInfo
