<#
.SYNOPSIS
    A script to download and install Invoke-LiveResponse in users Powershell profile

    Name: Get-Forensicating.ps1
    Version: 1.3

.DESCRIPTION
    Remove old versions of Invoke-LiveResponse if exist.
    Proxy aware download of the latest version of Invoke-LiveResponse.
    Install in user profile
    Show installed modules.
.EXAMPLE
    # download
    $url="https://raw.githubusercontent.com/mgreen27/Powershell-IR/master/Get-Forensicating.ps1"
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    $WebClient=(New-Object System.Net.WebClient)
    $WebClient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
    $WebClient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
    Invoke-Expression $WebClient.DownloadString($url) 

    # local
    Set-ExecutionPolicy -ExecutionPolicy Bypass; .\Get-Forensicating.ps1
.LINK
    https://github.com/Invoke-IR/PowerForensics
    https://github.com/mgreen27/Invoke-LiveResponse

.NOTES
    
#>

Set-ExecutionPolicy -ExecutionPolicy bypass -Force

function Expand-ZIPFile($file, $destination)
{
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items()){
        $shell.Namespace($destination).copyhere($item)
    }
}

$target = $env:PSModulePath.split(";")[0]

#Cover usecase of environment variable set but no folder
If (!(test-path $target)){New-Item $target -type Directory -Force |Out-Null}

# Remove Invoke-LiveResponse
Remove-Module Invoke-LiveResponse -ErrorAction SilentlyContinue
If (Test-Path ($Target + "\Invoke-LiveResponse") -ErrorAction SilentlyContinue) {
        Remove-Item ($Target + "\Invoke-LiveResponse") -Recurse -Force -ErrorAction Stop
}

# Download Invoke-LiveResponse
Try{
    Write-Host -ForegroundColor Yellow "`nDownloading Invoke-LiveResponse... " -NoNewline
    if (Test-Path "$Target\master.zip" -ErrorAction SilentlyContinue) {
        Remove-Item "$Target\master.zip" -Force -ErrorAction SilentlyContinue
    }

    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    $WebClient=(New-Object System.Net.WebClient)
    $WebClient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
    $WebClient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
    $WebClient.DownloadFile("https://github.com/mgreen27/Invoke-LiveResponse/archive/master.zip","$Target\Invoke-LiveResponse.zip")
    Write-Host -ForegroundColor Red "DONE"
}
Catch{
    Write-Host -ForegroundColor Red "Download Failed!"
    Break
}

# Extract Invoke-Live Response
Try{
    Write-Host -ForegroundColor Yellow "`nExtracting Invoke-LiveResponse... " -NoNewline
    unblock-file -Path "$Target\Invoke-LiveResponse.zip"

    Expand-ZIPFile –File "$target\Invoke-LiveResponse.zip" –Destination $target
    Write-Host -ForegroundColor Red "DONE`n"

    Move-Item ($Target + "\Invoke-LiveResponse-master") ($Target + "\Invoke-LiveResponse") -Force
    Remove-Item -Path "$Target\invoke-ir.zip" -Force
}
Catch{
    Write-Host -ForegroundColor Red "Extraction Failed!"
    Break
}

# Import Invoke-LiveResponse
Try{
    Write-Host -ForegroundColor Yellow "`nAvailible Invoke-LiveResponse functions:"
    Import-Module -Name Invoke-LiveResponse -WarningAction SilentlyContinue
    Get-Command -Module Invoke-LiveResponse
}
Catch{
    Write-Host -ForegroundColor Red "Invoke-LiveResponse Import Failed!`n"
    Break
}

