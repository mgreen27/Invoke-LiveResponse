function Invoke-StartWinRm
{
    <# 
    .SYNOPSIS 
        Starts WinRM on target system
    .DESCRIPTION
        Start WinRM and leave system as previous state
        Switches for Computername (mandatory), Credential and PsExec
    .NOTES./win
        Author - Matt Green (@mgreen27)
    .EXAMPLE 
        PS> Invoke-StartWinRm -ComputerName Win081x64 -Credential dfir\matt
    #>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory=$True)]
            [String]$ComputerName,
        [Parameter(Mandatory=$True)]
            [String]$Credential
    )

    # We only need Enable-PSRemoting to setup WinRM but would like to tweak features 
    # to minimise credential risk and remove maxmemory limitations
    $installWinRM = "Enable-PSRemoting -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\Basic -Value false -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\Negotiate -Value true -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\kerberos -value true -Force;"`
        + "Set-Item WSMan:\localhost\Service\Auth\CredSSP -Value false -Force;"`
        + "Restart-Service winrm -Force"

    # Execute via WMI
    $installWinRM = "cmd.exe /c powershell -command `"&{"+ $installWinRM + "}`""
    try{
        invoke-wmimethod -ComputerName $ComputerName -Credential $Credential -path win32_process -name create -argumentlist $installWinRM -ErrorAction stop
        
        Write-Host -ForegroundColor Cyan "`nInstalling WinRM over WMI. Process may take a few minutes.`n"
        Write-Host "`nTo test WinRM was installed please run: "
        Write-Host -ForegroundColor Yellow "`tTest-WSMan -Computername $ComputerName [-Credential $Credential -Authentication Kerberos|Negotiate]"
    }
    Catch{
        Write-Host -ForegroundColor Red -NoNewline "`nInvoke-StartWinRM Error: "
        Write-host "$_`n"
        Break
    }
}



function Invoke-StopWinRm
{
    <# 
    .SYNOPSIS 
        Stops WinRM on target system
    .DESCRIPTION
        Stop WinRM and leave system as previous state
    .NOTES
        Author - Matt Green (@mgreen27)
    .EXAMPLE 
        PS > Invoke-StopWinRm -ComputerName Win081x64 -Credential dfir\matt
    #>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $True)]
            [String]$ComputerName,
        [Parameter(Mandatory = $True)]
            [String]$Credential
    )

    # Running Disable-PSRemoting as well as the other components
    $removeWinRM = 'cmd.exe /c powershell -command "&{'`
        + 'Disable-PSRemoting -Force;'`
        + 'Stop-Service Winrm;Set-Service -Name WinRM -StartupType Disabled;'`
        + 'Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name LocalAccountTokenFilterPolicy -Value 0 -Type DWord;'`
        + "netsh advfirewall firewall set rule name='Windows Remote Management (HTTP-In)' new enable=no"`
        + '}"'
    
    try{
        invoke-wmimethod -ComputerName $ComputerName -Credential $Credential -path win32_process -name create -argumentlist $removeWinRM
        
        Write-Host -ForegroundColor Cyan "`nRemoving WinRM over WMI. Process may take a few minutes.`n"
        Write-Host -NoNewline "`nTo test WinRM was removed please run: "
        Write-Host -ForegroundColor Yellow  "Test-WSMan -Computername $ComputerName"
    }
    Catch{
        Write-Host -ForegroundColor Red -NoNewline "`nInvoke-StopWinRM Error: "
        Write-host "$_`n"
        Break
    }
}



function Invoke-MaxMemory
{
    <# 
    .SYNOPSIS 
       Removes WSMan MaxMemory setting on target system
    .DESCRIPTION
        Invoke-MaxMemory removes MaxMemory settings for Powershell
        The Script will setup a PSSession and set MaxMemory settings before restarting the WinRM service.
        Please use "-Legacy" switch for Powershell 2.0 support
    .NOTES
        Author - Matt Green (@mgreen27)
    .EXAMPLE 
        PS> Invoke-MaxMemory -ComputerName Win081x64 -Credential dfir\matt
    #>
    [CmdletBinding()]

    Param(
        [Parameter(Mandatory = $True)][String]$ComputerName,
        [Parameter(Mandatory = $True)][String]$Credential,
        [Parameter(Mandatory = $False)][String]$Authentication,
        [Parameter(Mandatory = $False)][String]$Port,
        [Parameter(Mandatory = $False)][Switch]$useSSL,
        [Parameter(ParameterSetName = "Legacy", Mandatory = $False)][Switch]$Legacy
        #Todo:[Parameter(ParameterSetName = "Enumerate", Mandatory = $False)][Switch]$Enumerate
    )

    $useSSL = $PSBoundParameters.ContainsKey('useSSL')
    $Legacy = $PSBoundParameters.ContainsKey('Legacy')
    $Enumerate = $PSBoundParameters.ContainsKey('Enumerate')

    # Set WinRM Defaults for Auth and Port    
    If (!$Authentication) {$Authentication = "Kerberos"}
    If ($useSSL -And !$Port) {$Port = "5986"}
    If (!$Port) {$Port = "5985"}

    Write-Host -ForegroundColor Yellow "`nRunning Invoke-MaxMemoryMB`n"

    If (!$Legacy){
        # Connect-WSman seems to be most reliable method of setting MaxMemoryMB
        $Scriptblock = {
            Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 0 -Force
            Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxMemoryPerShellMB 0 -Force
            Restart-Service winrm -Force
        }   
    }
    Elseif ($Legacy){
        # SCHTASKS seems to be most reliable method of setting MaxMemoryMB for legacy machines
        $Scriptblock = {
            $SetMaxMemoryMB = "cmd.exe /c powershell -command '&{Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 0 -Force;Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxMemoryPerShellMB -Value 0 -Force}'"
            $Start = (get-date).AddMinutes(2).ToString("HH:mm")
            SCHTASKS /Create /F /SC ONCE /ST $Start /TN Remove-MaxMemoryLegacy /TR $SetMaxMemoryMB
            SCHTASKS /Run /I /TN Remove-MaxMemoryLegacy
            SCHTASKS /Delete /TN Remove-MaxMemoryLegacy /F
            Restart-Service winrm -force
        }
    }
    
    If (!$useSSL){
        $Test = [bool](Test-WSMan -ComputerName $ComputerName -Port $Port -ErrorAction SilentlyContinue)
    }
    ElseIf($useSSL){
        $Test = [bool](Test-WSMan -ComputerName $ComputerName -Port $Port -UseSSL -ErrorAction SilentlyContinue)
    }

    if ($Test -eq "True"){
        Try{
            Write-Host "`tStarting PSSession on $ComputerName " -NoNewline
            If(!$useSSL){
                $Session = New-PSSession -ComputerName $ComputerName -Port $Port -Credential $Credential -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile) -ErrorAction Stop
            }
            ElseIf($useSSL){
                $Session = New-PSSession -ComputerName $ComputerName -UseSSL -Port $Port -Credential $Credential -Authentication $Authentication -SessionOption (New-PSSessionOption -NoMachineProfile)  -ErrorAction Stop
            }

            Write-Host -ForegroundColor DarkCyan "SUCCESS`n"
        }
        Catch{
            Write-Host -ForegroundColor Red "FAILED"
            Write-Host "$_`n"
            Break
        }

        Write-Host -ForegroundColor Cyan "PSSession with $ComputerName as $Credential"

        Try{
            Invoke-Command -Session $Session -Scriptblock $scriptblock -ErrorAction stop
            Write-Host -ForegroundColor Yellow  "`nInvoke-MaxMemory completed`n"
        }
        Catch{
            Write-Host "This error is thrown if there are issues running the SetMaxMemory command. Typical occurance is on legacy Powershell 2.0 machines. Currently for legacy machines local, GPO, or startup script will be required.`n";Break
        }
        Finally{
            Remove-PSSession -Session $Session
        }
    }
    Else{
        Write-Host -ForegroundColor Red "`nUnsuccessful WinRM test to $ComputerName... is WinRM installed?`n"
    }
}
