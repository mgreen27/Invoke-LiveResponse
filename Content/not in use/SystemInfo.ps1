<#
.SYNOPSIS
Get Complete details of any machine

.DESCRIPTION
This function uses WMI class to grab relevant details

Code adapted from http://sqlpowershell.wordpress.com

.EXAMPLE 
Get-SystemInfo

.NOTES

.LINK

#>
 
# Adding CPU priority to IDLE
$Process = Get-Process -Id $Pid
$Process.PriorityClass = 'IDLE'


# Declare main data hash to be populated later
$data = @{}

$data."ComputerName"=$env:COMPUTERNAME



# Do a DNS lookup supress errors
$ErrorActionPreference = "SilentlyContinue"
if ( $ips = [System.Net.Dns]::GetHostAddresses($env:COMPUTERNAME) | foreach { $_.IPAddressToString } ) {
    $data."IP Address(es) from DNS" = ($ips -join ", ")
}
else {
    $data."IP Address from DNS" = "Could not resolve"
}

# normal errors
$ErrorActionPreference = 'Continue'

# Get various info from the ComputerSystem WMI class
if ($wmi = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue) {
        
    $data."Computer Hardware Manufacturer" = $wmi.Manufacturer
    $data."Computer Hardware Model"        = $wmi.Model
    $data."Memory - Physical MB"          = ($wmi.TotalPhysicalMemory/1MB).ToString("N")
    $data."Logged On User"                 = $wmi.Username
        
}
    
$wmi = $null
    
# Get the free/total disk space from local disks (DriveType 3)
if ($wmi = Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue) {
    $wmi | Select-Object DeviceID,Size,FreeSpace | Foreach {
        $data."Local disk $($_.DeviceID)" = ('' + ($_.FreeSpace/1MB).ToString('N') + ' MB free of ' + ($_.Size/1MB).ToString('N') + ' MB total space with ' + ($_.Size/1MB - $_.FreeSpace/1MB).ToString('N') +' MB Used Space')
    }
}

$wmi = $null
    
# Get IP addresses from all local network adapters through WMI
if ($wmi = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue) {
    $Ips = @{}
    $wmi | Where { $_.IPAddress -match '\S+' } | Foreach { $Ips.$($_.IPAddress -join ", ") = $_.MACAddress }
    $counter = 0
        
    $Ips.GetEnumerator() | Foreach {
        $counter++; $data."IP Address $counter" = "" + $_.Name + " (MAC: " + $_.Value + ')'
    }
}
    
$wmi = $null
    
# CPU Information
if ($wmi = Get-WmiObject -Class Win32_Processor -ErrorAction SilentlyContinue) {    
    $wmi | Foreach {
            
        $maxClockSpeed     =  $_.MaxClockSpeed
        $numberOfCores     += $_.NumberOfCores
        $description       =  $_.Description
        $numberOfLogProc   += $_.NumberOfLogicalProcessors
        $socketDesignation =  $_.SocketDesignation
        $status            =  $_.Status
        $manufacturer      =  $_.Manufacturer
        $name              =  $_.Name    
    }
        
    $data."CPU Clock Speed"        = $maxClockSpeed
    $data."CPU Cores"              = $numberOfCores
    $data."CPU Description"        = $description
    $data."CPU Logical Processors" = $numberOfLogProc
    $data."CPU Socket"             = $socketDesignation
    $data."CPU Status"             = $status
    $data."CPU Manufacturer"       = $manufacturer
    $data."CPU Name"               = $name -replace "\s+", " "
}
    
$wmi = $null

# Get BIOS info from WMI
if ($wmi = Get-WmiObject -Class Win32_Bios -ErrorAction SilentlyContinue) {
        
    $data."BIOS Manufacturer" = $wmi.Manufacturer
    $data."BIOS Name"         = $wmi.Name
    $data."BIOS Version"      = $wmi.Version
}
    
$wmi = $null
    
# Get operating system and memory info from WMI
if ($wmi = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction SilentlyContinue) {
        
    $data."OS Boot Time"     = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
    $data."OS System Drive"  = $wmi.SystemDrive
    $data."OS System Device" = $wmi.SystemDevice
    $data."OS Language"      = $wmi.OSLanguage
    $data."OS Version"       = $wmi.Version
    $data."OS Windows dir"   = $wmi.WindowsDirectory
    $data."OS Name"          = $wmi.Caption
    $data."OS Install Date"  = $wmi.ConvertToDateTime($wmi.InstallDate)
    $data."OS Service Pack"  = [string]$wmi.ServicePackMajorVersion + "." + $wmi.ServicePackMinorVersion
    
    $wmi | Foreach {
        $TotalRAM                =  $_.TotalVisibleMemorySize/1MB
        $FreeRAM                 = $_.FreePhysicalMemory/1MB
        $UsedRAM                 =  $_.TotalVisibleMemorySize/1MB - $_.FreePhysicalMemory/1MB
        $TotalRAM                = [Math]::Round($TotalRAM, 2)
        $FreeRAM                 = [Math]::Round($FreeRAM, 2)
        $UsedRAM                 = [Math]::Round($UsedRAM, 2)
        $RAMPercentFree          = ($FreeRAM / $TotalRAM) * 100
        $RAMPercentFree          = [Math]::Round($RAMPercentFree, 2)
        $TotalVirtualMemorySize  = [Math]::Round($_.TotalVirtualMemorySize/1MB, 3)
        $FreeVirtualMemory       =  [Math]::Round($_.FreeVirtualMemory/1MB, 3)
        $FreeSpaceInPagingFiles  =  [Math]::Round($_.FreeSpaceInPagingFiles/1MB, 3)
        $NumberofProcesses       =  $_.NumberofProcesses
        $NumberOfUsers           =  $_.NumberOfUsers
            
    }
    $data."Memory Total GB"               = $TotalRAM
    $data."Memory Free GB"                = $FreeRAM
    $data."Memory Used GB"                = $UsedRAM
    $data."Memory Percentage Free"        = $RAMPercentFree
    $data."Memory TotalVirtualMemorySize" = $TotalVirtualMemorySize
    $data."Memory FreeVirtualMemory"      = $FreeVirtualMemory
    $data."Memory FreeSpaceInPagingFiles" = $FreeSpaceInPagingFiles
    $data."NumberofProcesses"               = $NumberofProcesses
    $data."NumberOfUsers"                   = $NumberOfUsers -replace "\s+", " "
    
           
}
    
$wmi = $null

# Heading
"#"*80
"System Information"
"Generated $(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZ` HH:mm:ss)"
"Generated from $env:computername"
"#"*80
$data.GetEnumerator() | Sort-Object 'Name'  | format-table -AutoSize -wrap
