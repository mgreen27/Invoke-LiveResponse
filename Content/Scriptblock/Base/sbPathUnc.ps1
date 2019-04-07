
Function Mount-NetworkPath
{
<#
    .SYNOPSIS
        Mounts UNC share through the use of 
        Author: @mgreen27
        Requirements: PSReflect
#>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    Param(
        [Parameter( Mandatory = $True)][ValidatePattern('\\\\.*\\.*')][String[]]$UncPath,
        [Parameter(Mandatory = $True)][String] $Username,
        [Parameter(Mandatory = $True)][String] $Password
    )

    function Get-NextFreeDrive {
        68..90 | ForEach-Object { "$([char]$_):" } | 
        Where-Object { 'd:','e:','f:','h:', 'k:', 'z:' -notcontains $_  } | 
        Where-Object { 
            (new-object System.IO.DriveInfo $_).DriveType -eq 'noRootdirectory' 
        }
    }
    $Drive = (Get-NextFreeDrive)[-1]

    $Module = New-InMemoryModule -ModuleName WNetAddConnection2W

    # defining Structs
    $NETRESOURCEW = struct $Module NETRESOURCEW @{
        dwScope       = field 0 UInt32
        dwType        = field 1 UInt32
        dwDisplayType = field 2 UInt32
        dwUsage       = field 3 UInt32
        lpLocalName   = field 4 String -MarshalAs @('LPWStr')
        lpRemoteName  = field 5 String -MarshalAs @('LPWStr')
        lpComment     = field 6 String -MarshalAs @('LPWStr')
        lpProvider    = field 7 String -MarshalAs @('LPWStr')
    }

    $FunctionDefinitions = func Mpr WNetAddConnection2W ([bool]) @($NETRESOURCEW,[String],[String],[Int32]) -EntryPoint WNetAddConnection2W -SetLastError

    $Types = $FunctionDefinitions | Add-Win32Type -Module $Module -Namespace InvokeLiveResponse
    $Mpr = $Types['Mpr']

    $mountInfo = [Activator]::CreateInstance($NETRESOURCEW)
    $mountInfo.dwType = 1
    $mountInfo.lpRemoteName = $UncPath #Path
    $mountInfo.lpLocalName = $Drive

    $Result = $Mpr::WNetAddConnection2W($mountInfo, $Password, $UserName,4)

    If ($Result -ne 0) {
        Write-Host -ForegroundColor Red "ERROR:`tUNC path unable to be mounted successfully. Please check credentials and path availible."
        Write-Host -ForegroundColor Red "`tUNC path:  $UncPath`n"
        Unmount-NetworkPath -MapPath $Drive
        break
    }
    Elseif (-Not (Test-path $Drive)) { 
        Write-Host -ForegroundColor Red "ERROR:`tUnable to mount $Drive. Please check UNC path permissions.`n"
        Unmount-NetworkPath -MapPath $Drive
        break
    }

    return $Drive
}

Function Unmount-NetworkPath
{
<#
    .SYNOPSIS
        UnMounts WNetAddConnection2 share through the use of WNetCancelConnection2
        Author: @mgreen27
        Requirements: PSReflect
#>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    Param(
        [Parameter( Mandatory = $True)][String]$MapPath
    )
    $Module = New-InMemoryModule -ModuleName WNetAddConnection2

    $FunctionDefinitions = (func Mpr WNetCancelConnection2 ([Int32]) @([String],[Int32],[Bool]) -EntryPoint WNetCancelConnection2)

    $Types = $FunctionDefinitions | Add-Win32Type -Module $Module -Namespace InvokeLiveResponse
    $Mpr = $Types['Mpr']

    $Result = $Mpr::WNetCancelConnection2($MapPath, 0, $True)
}


# set variables
$Unc = $Unc.split(',')
$Date = $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)

$Map = Mount-NetworkPath -UncPath $Unc[0] -Username $Unc[1] -Password $Unc[2]

$Output = $Map + "\" + $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd) + "Z_" + $env:computername 

# if previous collection found. Remove.
If (Test-Path $Output -ErrorAction SilentlyContinue){
    Remove-Item $Output -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

Try{
    New-Item $Output -type directory -ErrorAction SilentlyContinue | Out-Null
}
Catch{
    Write-Host "INFO:`tUnable to create $Output."
}

# Setting log location as Global and creating log
$Global:CollectionLog = "$Output\$(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)_collection.csv"
Try{ 
    Add-Content -Path $CollectionLog "TimeUTC,Action,Source,Destination,Sha256(Source)" -Encoding Ascii -ErrorAction Stop
}
Catch{
    Write-Host -ForegroundColor Red "ERROR:`tUnable to write to $Output. Please check share permissions.`n"
    Unmount-NetworkPath -MapPath $Map
    break
}
