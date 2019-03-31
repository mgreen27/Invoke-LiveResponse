
function Get-System
{
    <#
    .SYNOPSIS
        Elevates with SYSTEM privilages to current Powershell session through impersonation.
        
        Author: @mgreen27
        Requirements: PSReflect

        Adapted from: https://github.com/jaredcatkinson/PSReflect-Functions
        OriginalAuthor: @jaredcatkinson
    #>

    Write-Host -ForegroundColor Yellow "`tElevating to SYSTEM"

    $Module = New-InMemoryModule -ModuleName Get-System

    $FunctionDefinitions = @( 
        (func kernel32 CloseHandle ([bool]) @([IntPtr]) -EntryPoint CloseHandle -SetLastError),
        (func advapi32 DuplicateToken ([bool]) @([IntPtr],[UInt32],[IntPtr].MakeByRefType()) -EntryPoint DuplicateToken -SetLastError),
        (func advapi32 ImpersonateLoggedOnUser ([bool]) @([IntPtr]) -EntryPoint ImpersonateLoggedOnUser -SetLastError),
        (func advapi32 OpenProcessToken ([bool]) @([IntPtr],[UInt32],[IntPtr].MakeByRefType()) -EntryPoint OpenProcessToken -SetLastError)
    )

    $Types = $FunctionDefinitions | Add-Win32Type -Module $Module -Namespace InvokeLiveResponse
    $advapi32 = $Types['advapi32']
    $kernel32 = $Types['kernel32']

    # Winlogon runs a SYSTEM
    $systemProcess = @(Get-Process -Name winlogon)[0]

    # Open handle to Winlogon SYSTEM Token with TOKEN_DUPLICATE access.
    $hToken = [IntPtr]::Zero
    try { $OpenProcessTOken = $advapi32::OpenProcessToken($systemProcess.Handle, 2, [ref]$hToken) }
    catch { Write-Host -ForegroundColor Red "ERROR: Get-System OpenProcessToken" }

    # Make a copy of the Winlogon SYSTEM Token
    $hDupToken = [IntPtr]::Zero
    try { $DuplicateToken = $Advapi32::DuplicateToken($hToken, 3, [ref]$hDupToken) }
    catch { Write-Host -ForegroundColor Red "ERROR: Get-System DuplicateToken" }


    # Apply Impersonation System Token
    try { $Impersonate = $Advapi32::ImpersonateLoggedOnUser($hDupToken) }
    catch { Write-Host -ForegroundColor Red "ERROR: Get-System ImpersonateSystemToken" }

    # Clean up the handles we created
    try { $CloseHandle = $Kernel32::CloseHandle($hToken) }
    catch { Write-Host "INFO: Get-System nonCritical CloseHandle(hToken) error" }
    try { $CloseHandle = $Kernel32::CloseHandle($hDupToken) }
    catch {Write-Host "INFO: Get-System nonCritical CloseHandle(hDupToken) error"c}

    if (! [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
        Write-Host -ForegroundColor Red "ERROR: Get-System Unable to Impersonate SYSTEM Token"
    }
}

Get-System
