
Function Mount-VolumeShadowCopy
{
<#
    .SYNOPSIS
        Mounts Volume Shadow Copy through the use of symlinks.
        Author: @mgreen27
        Requirements: PSReflect
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidatePattern('\\\\\?\\GLOBALROOT\\Device\\HarddiskVolumeShadowCopy\d{1,}')]
        [Alias("DeviceObject")][String[]]$ShadowPath,
        
        [Parameter(Mandatory = $True)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [String] $Destination
    )

    $Module = New-InMemoryModule -ModuleName Mount-VolumeShadowCopy

    $FunctionDefinitions = func kernel32 CreateSymbolicLink ([bool]) @([String], [String], [Int32]) -EntryPoint CreateSymbolicLink -SetLastError

    $Types = $FunctionDefinitions | Add-Win32Type -Module $Module -Namespace InvokeLiveResponse
    $kernel32 = $Types['kernel32']
    

    # Definitioons setup - Mount-Vss
    If (!$Destination.EndsWith('\')) { $Destination = $Destination + '\' }

    Foreach ($Path in $ShadowPath) {
        If (!$Path.EndsWith('\')) { $Path = $Path + '\' }

        $vss = 'vss' + $(split-path $Path -Leaf).TrimStart('HarddiskVolumeShadowCopy')
        $Dest = $Destination + "$vss\"

        # Create the Symbolic Link
        try { $CreateSymbolicLinkResult = $Kernel32::CreateSymbolicLink($Dest, $Path, 1) }
        catch {Write-Host -ForegroundColor Red "ERROR:`tMount-VolumeShadowCopy CreateSymbolicLink" }
    }
}

# Set drives in scope
Write-Host -ForegroundColor Yellow "`tMounting Volume Shadow Copy"

$Vss = New-Object System.Collections.ArrayList
$Vss += $env:SystemDrive

# Mount all availible VSS - add logic here to target VSS below
Get-WmiObject Win32_ShadowCopy | % { Mount-VolumeShadowCopy -ShadowPath $_.DeviceObject -Destination "$env:windir\temp" }

# Build array of Drives / Vss to collect
$Vss += Get-childItem "$env:windir\temp" | Where-Object { $_.Attributes -match "ReparsePoint" -and $_.Name -like "vss*" } | Select-Object -ExpandProperty FullName

$Vss = $Vss | Where-Object ({ $_.length -ne 0 })

Foreach ($Drive in $Vss) { 
    If ($drive -match 'vss') { Write-Host -ForegroundColor White "`t`t"$($(split-path $Drive -Leaf) -replace 'vss','VolumeShadowCopy').trim('') }
}

# Making runspace scope
$Global:Vss = $Vss
