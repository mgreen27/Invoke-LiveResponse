<#
.SYNOPSIS
    A script to download and install PowerForensics in users Powershell profile

    Name: Get-Powerforensics.ps1
    Version: 1.11

.DESCRIPTION
    Remove old versions of Powerforensics if exist.
    Proxy aware download of the latest version of Powerforensics.
    Install in user profile
    Show installed modules.
.EXAMPLE
    # download
    $url="<https://raw.githubusercontent.com/mgreen27/Powershell-IR/master/Get-Powerforensics.ps1>"
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    $WebClient=(New-Object System.Net.WebClient)
    $WebClient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
    $WebClient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
    Invoke-Expression $WebClient.DownloadString($url) 

    # local
    Set-ExecutionPolicy -ExecutionPolicy Bypass; .\Get-Powerforensics.ps1
.LINK
    https://github.com/Invoke-IR/PowerForensics
    https://powerforensics.readthedocs.io/en/latest/
    http://www.invoke-ir.com/
.NOTES
    For repetative installs, please restart Powershell session if required to unlock Powerforenscis.dll
#>

function Expand-ZIPFile($file, $destination)
{
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items()){
        $shell.Namespace($destination).copyhere($item)
    }
}

Set-ExecutionPolicy -ExecutionPolicy bypass -Force

# Remove Powerforensics
Remove-Module Powerforensics -ErrorAction SilentlyContinue

$target = $env:PSModulePath.split(";")[0]
#Cover usecase of environment variable set but no folder
If (!(test-path $target)){New-Item $target -type Directory -Force |Out-Null}

If (Test-Path ($target + "\Powerforensics") -ErrorAction SilentlyContinue) {
        Remove-Item ($target + "\Powerforensics") -Recurse -Force -ErrorAction Stop
}

# Download Powerforensics
Try{
    Write-Host -ForegroundColor Yellow "`nDownloading Powerforensics... " -NoNewline
    if (Test-Path "$target\powerforensics.zip" -ErrorAction SilentlyContinue) {
        Remove-Item "$target\powerforensics.zip" -Force -ErrorAction SilentlyContinue
    }

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    $webclient=(New-Object System.Net.WebClient)
    $webclient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
    $webclient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
    $webclient.DownloadFile("https://github.com/Invoke-IR/PowerForensics/archive/master.zip","$target\powerforensics.zip")
    Write-Host -ForegroundColor Red "DONE"
}
Catch{
    Write-Host -ForegroundColor Red "Download Failed!"
    Break
}

# Extract Powerforensics
Try{
    Write-Host -ForegroundColor Yellow "`nExtracting Powerforensics... " -NoNewline
    unblock-file -Path "$target\powerforensics.zip"
    #New-Item -ItemType Directory -Force -Path $target | out-null

    Expand-ZIPFile –File "$target\powerforensics.zip" –Destination $target
    Write-Host -ForegroundColor Red "DONE`n"

    Move-Item ($target + "\Powerforensics-master\Modules\Powerforensics") ($target + "\Powerforensics") -Force
    Remove-Item -Path ($target + "\Powerforensics-master") -Recurse -Force
    Remove-Item -Path "$target\powerforensics.zip" -Force
}
Catch{
    Write-Host -ForegroundColor Red "Extraction Failed!"
    Break
}

# Install Powerforensics
Try{
    Write-Host -ForegroundColor Yellow "`nAvailible Powerforensics functions:"
    Import-Module -Name Powerforensics
    Get-Command -Module Powerforensics
}
Catch{
    Write-Host -ForegroundColor Red "Powerforensics Import Failed!`n"
    Break
}
