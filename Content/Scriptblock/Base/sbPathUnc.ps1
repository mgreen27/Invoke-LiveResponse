
# Function to obtain next free drive. Add excluded drives per organisation in line 5
function Get-NextFreeDrive {
  68..90 | ForEach-Object { "$([char]$_):" } | 
  Where-Object { 'd:','e:','f:','h:', 'k:', 'z:' -notcontains $_  } | 
  Where-Object { 
    (new-object System.IO.DriveInfo $_).DriveType -eq 'noRootdirectory' 
  }
}

# set variables
$Map = (Get-NextFreeDrive)[-1]
$Unc = $Unc.split(',')
$Date = $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)
$net = (new-object -ComObject WScript.Network)


Try {
    if (test-path $Map) {
        If ($net.EnumNetworkDrives($Map)) { $net.RemoveNetworkDrive($Map,$true,$true) }
    }

    if ($Unc.count -eq 3) { $net.MapNetworkDrive($Map, $UNC[0],'FALSE',$UNC[1], $UNC[2]) }
    Elseif ($Unc.count -eq 1) { $net.MapNetworkDrive($Map, $UNC[0],'FALSE') }

    If (!(Test-Path $Map)) {
        Write-Host -ForegroundColor Red "`tError: Check UNC path and credentials. Unable to Map $Map"
        break
    }
}
Catch {
    if (test-path $Map) {
        If ($net.EnumNetworkDrives($Map)) { $net.RemoveNetworkDrive($Map,$true,$true) }
    }
    Write-Host -ForegroundColor Red "`tError: Check UNC path and credentials. Unable to Map $Map"
    break
}


$Output = $Map + "\" + $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd) + "Z_" + $env:computername 

# if previous collection found. Remove.
If (Test-Path $Output -ErrorAction SilentlyContinue){
    Remove-Item $Output -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

Try{
    New-Item $Output -type directory -ErrorAction SilentlyContinue | Out-Null
}
Catch{
    If(Test-Path $Output -ErrorAction SilentlyContinue){
        Write-Host "Error: $Output already exists. Previously open on removal."
    }
}

# Setting log location as Global and creating log
$Global:CollectionLog = "$Output\$(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)_collection.log"
Add-Content -Path $CollectionLog "TimeUTC,Action,Source,Destination,FileSize,Sha256(Source)" -Encoding Ascii
