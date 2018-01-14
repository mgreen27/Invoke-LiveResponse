function Get-SimpleNamedPipe { 
<#
    .SYNOPSIS

        Gets a list of open named pipes.

        Author: Greg Zakharov
        License: 
        Required Dependencies: None
        Optional Dependencies: None

    .DESCRIPTION

        When defining custom enums, structs, and unmanaged functions, it is
        necessary to associate to an assembly module. This helper function
        creates an in-memory module that can be passed to the 'enum',
        'struct', and Add-Win32Type functions.
#>
    [CmdletBinding()]
    Param (
        [switch]
        $ReturnHashtables
    )

    Begin 
    {
        $Mscorlib = [AppDomain]::CurrentDomain.GetAssemblies() | ? { 
            $_.ManifestModule.ScopeName.Equals('CommonLanguageRuntimeLibrary') 
        } 
     
        $SafeFindHandle = $Mscorlib.GetType('Microsoft.Win32.SafeHandles.SafeFindHandle') 
        $Win32Native = $Mscorlib.GetType('Microsoft.Win32.Win32Native') 
     
        $WIN32_FIND_DATA = $Win32Native.GetNestedType( 
            'WIN32_FIND_DATA', [Reflection.BindingFlags]32 
        ) 
        $FindFirstFile = $Win32Native.GetMethod( 
            'FindFirstFile', [Reflection.BindingFlags]40, 
            $null, @([String], $WIN32_FIND_DATA), $null 
        ) 
        $FindNextFile = $Win32Native.GetMethod('FindNextFile', [Reflection.BindingFlags]40, $null, @($SafeFindHandle, $WIN32_FIND_DATA), $null) 
     
        $Obj = $WIN32_FIND_DATA.GetConstructors()[0].Invoke($null)
        function Read-Field([String]$Field) { 
            return $WIN32_FIND_DATA.GetField($Field, [Reflection.BindingFlags]36).GetValue($Obj)
        } 
    } 

    Process 
    { 
        $Handle = $FindFirstFile.Invoke($null, @('\\.\pipe\*', $obj))

        
        $Output = @{
            Name = [string](Read-Field cFileName)
            Instances = [UInt32](Read-Field nFileSizeLow)
        }

        do {
            $Output = @{
                Name = [string](Read-Field cFileName)
                Instances = [UInt32](Read-Field nFileSizeLow)
            }

            if($ReturnHashtables) {
                $Output
            } else {
                New-Object PSObject -Property $Output
            }
        } while($FindNextFile.Invoke($null, @($Handle, $obj)))
     
        $Handle.Close() 
    } 

    End 
    {
    
    } 
}

Get-SimpleNamedPipe | Format-Table -AutoSize -Wrap