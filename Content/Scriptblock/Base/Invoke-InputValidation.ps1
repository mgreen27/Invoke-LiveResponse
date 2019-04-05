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
