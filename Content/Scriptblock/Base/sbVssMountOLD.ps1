
Function Mount-VolumeShadowCopy
{
<#
    .SYNOPSIS
        Mount a volume shadow copy through the use of symlinks.

        Author: @mgreen27
     
    .DESCRIPTION
        Mount-VolumeShadowCopy will mount all shadow copies piped to the function through the use of the CreateStymLink method.
        Default example aboive will mount all Volume Shadow Copy but the user can manipulate filters to pipe only desired VSC.
        Reflection was chosen to minimised forenisc footprint and bypass Add-Type or running the legacy mklink binanry from cmd.
        Note: There is some Forensic cose running a VSS collection in live mode as there will be stymlinks created on target drive.
        
    .PARAMETER ShadowPath
        Path of volume shadow copies submitted as an array of strings
      
    .PARAMETER Destination
        Target folder that will contain stmlinks mounted volume shadow copies
              
    .EXAMPLE
        Get-WmiObject Win32_ShadowCopy | Mount-VolumeShadowCopy -Destination C:\Windows\Temp
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

    $DynAssembly = New-Object System.Reflection.AssemblyName('Win32Lib')
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($DynAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('Win32Lib', $False)
    $TypeBuilder = $ModuleBuilder.DefineType('Kernel32', 'Public, Class')

    $PInvokeMethod = $TypeBuilder.DefineMethod('CreateSymbolicLink',
                                               [Reflection.MethodAttributes] 'Public, Static',
                                               [Bool],
                                               [Type[]] @([String], [String], [Int32]))

    $DllImportConstructor = [Runtime.InteropServices.DllImportAttribute].GetConstructor(@([String]))

    $FieldArray = [Reflection.FieldInfo[]] @(
        [Runtime.InteropServices.DllImportAttribute].GetField('EntryPoint'),
        [Runtime.InteropServices.DllImportAttribute].GetField('PreserveSig'),
        [Runtime.InteropServices.DllImportAttribute].GetField('SetLastError'),
        [Runtime.InteropServices.DllImportAttribute].GetField('CallingConvention'),
        [Runtime.InteropServices.DllImportAttribute].GetField('CharSet')
    )

    $FieldValueArray = [Object[]] @(
       'CreateSymbolicLink',
        $True,
        $True,
        [Runtime.InteropServices.CallingConvention]::Winapi,
        [Runtime.InteropServices.CharSet]::Unicode
    )

    $SetLastErrorCustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder($DllImportConstructor,
                                                                                     @('kernel32.dll'),
                                                                                     $FieldArray,
                                                                                     $FieldValueArray)
    $PInvokeMethod.SetCustomAttribute($SetLastErrorCustomAttribute)

    # Create Kernel32::Type
    $Kernel32 = $TypeBuilder.CreateType()
    

    # Definitioons setup - Mount-Vss
    If (!$Destination.EndsWith('\')) { $Destination = $Destination + '\' }

    Foreach ($Path in $ShadowPath) {
        If (!$Path.EndsWith('\')) { $Path = $Path + '\' }

        $vss = 'vss' + $(split-path $Path -Leaf).TrimStart('HarddiskVolumeShadowCopy')
        $Dest = $Destination + "$vss\"

        # Create the Symbolic Link
        $CreateSymbolicLinkResult = $Kernel32::CreateSymbolicLink($Dest, $Path, 1)
    }
}

# Set drives in scope
Write-Host -ForegroundColor Yellow "`tMounting Volume Shadow Copy"

$Vss = New-Object System.Collections.ArrayList
$Vss += $env:SystemDrive

# Mount all availible VSS - add logic here to target VSS below
Get-WmiObject Win32_ShadowCopy | % { Mount-VolumeShadowCopy -ShadowPath $_.DeviceObject -Destination $env:temp }

# Build array of Drives / Vss to collect
$Vss += Get-childItem $env:temp | Where-Object { $_.Attributes -match "ReparsePoint" -and $_.Name -like "vss*" } | Select-Object -ExpandProperty FullName

$Vss = $Vss | Where-Object ({ $_.length -ne 0 })

Foreach ($Drive in $Vss) { 
    If ($drive -match 'vss') { Write-Host -ForegroundColor White "`t`t"$($(split-path $Drive -Leaf) -replace 'vss','VolumeShadowCopy').trim('') }
}

# Making runspace scope
$Global:Vss = $Vss
