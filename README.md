# Invoke-LiveResponse
A Module for Live Response and Forensic collections over WinRM. 

Get-Powerforensics.ps1 - Installs Powerforensics to user profile

Get-Forensicating.ps1 - Installs Invoke-LiveResponse and Powerforensics to user profile.

Invoke-ForensicCopy.ps1 - Powershell function to leverage Powerforensics API for raw copy with best performance.

Content - Contains some nice content from around the place, mainly from Kansa and SpectreOps ACE project. Ill add more as I remember / find new things.

# Installation
PS> $url="https://raw.githubusercontent.com/mgreen27/Powershell-IR/master/Get-Forensicating.ps1";$WebClient=(New-Object System.Net.WebClient);$WebClient.Proxy=[System.Net.WebRequest]::GetSystemWebProxy();$WebClient.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;Invoke-Expression $WebClient.DownloadString($url)




To run: Import-Module Invoke-LiveResponse

Help: Get-Help Invoke-LiveResponse -detailed
