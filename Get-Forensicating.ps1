<#
.SYNOPSIS
    A script to download and install Powerforensics and Invoke-LiveResponse in users Powershell profile

    Name: Get-Forensicating.ps1
    Version: 1.1

.DESCRIPTION
    Remove old versions of Invoke-LiveResponse if exist.
    Proxy aware download of the latest version of Invoke-LiveResponse.
    Install in user profile
    Show installed modules.
.EXAMPLE
    # download
    $url="https://raw.githubusercontent.com/mgreen27/Powershell-IR/master/Get-Forensicating.ps1"
    $WebClient=(New-Object System.Net.WebClient)
    $WebClient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
    $WebClient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
    Invoke-Expression $WebClient.DownloadString($url) 

    # local
    Set-ExecutionPolicy -ExecutionPolicy Bypass; .\Get-Forensicating.ps1
.LINK
    https://github.com/Invoke-IR/PowerForensics
    https://github.com/mgreen27/Powershell-IR

.NOTES
    
#>
<#
.SYNOPSIS
    A script to download and install Powerforensics and Invoke-LiveResponse in users Powershell profile

    Name: Get-Forensicating.ps1
    Version: 1.0

.DESCRIPTION
    Remove old versions of Invoke-LiveResponse if exist.
    Proxy aware download of the latest version of Invoke-LiveResponse.
    Install in user profile
    Show installed modules.
.EXAMPLE
    # download
    $url="https://raw.githubusercontent.com/mgreen27/Powershell-IR/master/Get-Forensicating.ps1"
    $WebClient=(New-Object System.Net.WebClient)
    $WebClient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
    $WebClient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
    Invoke-Expression $WebClient.DownloadString($url) 

    # local
    Set-ExecutionPolicy -ExecutionPolicy Bypass; .\Get-Forensicating.ps1
.LINK
    https://github.com/Invoke-IR/PowerForensics
    https://github.com/mgreen27/Powershell-IR

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

# Import Powerforenics
Try{
    Write-Host -ForegroundColor Yellow "`nAvailible Powerforensics functions:"
    Import-Module -Name Powerforensics
    Get-Command -Module Powerforensics
}
Catch{
    Write-Host -ForegroundColor Red "Powerforensics Import Failed!`n"
    Break
}

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

    $WebClient=(New-Object System.Net.WebClient)
    $WebClient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy()
    $WebClient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
    $WebClient.DownloadFile("https://github.com/mgreen27/Powershell-IR/archive/master.zip","$Target\invoke-ir.zip")
    Write-Host -ForegroundColor Red "DONE"
}
Catch{
    Write-Host -ForegroundColor Red "Download Failed!"
    Break
}

# Extract Invoke-Live Response
Try{
    Write-Host -ForegroundColor Yellow "`nExtracting Invoke-LiveResponse... " -NoNewline
    unblock-file -Path "$Target\invoke-ir.zip"

    Expand-ZIPFile –File "$target\invoke-ir.zip" –Destination $target
    Write-Host -ForegroundColor Red "DONE`n"

    Move-Item ($Target + "\Powershell-IR-master") ($Target + "\Invoke-LiveResponse") -Force
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
    Write-Host -ForegroundColor Red "Powerforensics Import Failed!`n"
    Break
}

