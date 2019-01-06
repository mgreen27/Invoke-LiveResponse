function Get-PSIProcess {
<#
    .SYNOPSIS

        Returns detailed information about the current running processes.

        Author: Lee Christensen (@tifkin_)
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: None

#>
    [CmdletBinding()]
    Param (
        [switch]
        $ReturnHashtables
    )

    # TODO: Optimize this cmdlet...

    begin
    {
        # Thanks to https://p0w3rsh3ll.wordpress.com/2015/02/05/backporting-the-get-filehash-function/
        function Get-DIGSFileHash
        {
            [CmdletBinding(DefaultParameterSetName = "Path")]
            param
            (
                [Parameter(Mandatory=$true, ParameterSetName="Path", Position = 0)]
                [System.String[]]
                $Path,

                [Parameter(Mandatory=$true, ParameterSetName="LiteralPath", ValueFromPipelineByPropertyName = $true)]
                [Alias("PSPath")]
                [System.String[]]
                $LiteralPath,
        
                [Parameter(Mandatory=$true, ParameterSetName="Stream")]
                [System.IO.Stream]
                $InputStream,

                [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MACTripleDES", "MD5", "RIPEMD160")]
                [System.String]
                $Algorithm="SHA256"
            )
    
            begin
            {
                # Construct the strongly-typed crypto object
                $hasher = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
            }
    
            process
            {
                if($PSCmdlet.ParameterSetName -eq "Stream")
                {
                    Get-DIGSStreamHash -InputStream $InputStream -RelatedPath $null -Hasher $hasher
                }
                else
                {
                    $pathsToProcess = @()
                    if($PSCmdlet.ParameterSetName  -eq "LiteralPath")
                    {
                        $pathsToProcess += Resolve-Path -LiteralPath $LiteralPath | Foreach-Object { $_.ProviderPath }
                    }
                    if($PSCmdlet.ParameterSetName -eq "Path")
                    {
                        $pathsToProcess += Resolve-Path $Path | Foreach-Object { $_.ProviderPath }
                    }

                    foreach($filePath in $pathsToProcess)
                    {
                        if(Test-Path -LiteralPath $filePath -PathType Container)
                        {
                            continue
                        }

                        try
                        {
                            # Read the file specified in $FilePath as a Byte array
                            [system.io.stream]$stream = [system.io.file]::OpenRead($filePath)
                            Get-DIGSStreamHash -InputStream $stream  -RelatedPath $filePath -Hasher $hasher
                        }
                        catch [Exception]
                        {
                            $errorMessage = 'FileReadError {0}:{1}' -f $FilePath, $_
                            Write-Error -Message $errorMessage -Category ReadError -ErrorId "FileReadError" -TargetObject $FilePath
                            return
                        }
                        finally
                        {
                            if($stream)
                            {
                                $stream.Close()
                            }
                        }                            
                    }
                }
            }
        }

        function Get-DIGSStreamHash
        {
            param
            (
                [System.IO.Stream]
                $InputStream,

                [System.String]
                $RelatedPath,

                [System.Security.Cryptography.HashAlgorithm]
                $Hasher
            )

            # Compute file-hash using the crypto object
            [Byte[]] $computedHash = $Hasher.ComputeHash($InputStream)
            [string] $hash = [BitConverter]::ToString($computedHash) -replace '-',''

            if ($RelatedPath -eq $null)
            {
                $retVal = [PSCustomObject] @{
                    Algorithm = $Algorithm.ToUpperInvariant()
                    Hash = $hash
                }
                $retVal.psobject.TypeNames.Insert(0, "Microsoft.Powershell.Utility.FileHash")
                $retVal
            }
            else
            {
                $retVal = [PSCustomObject] @{
                    Algorithm = $Algorithm.ToUpperInvariant()
                    Hash = $hash
                    Path = $RelatedPath
                }
                $retVal.psobject.TypeNames.Insert(0, "Microsoft.Powershell.Utility.FileHash")
                $retVal

            }
        }
 
        $FileHashCache = @{}
        $Processes = Get-WmiObject -Class Win32_Process

        function Get-DIGSCachedFileHash
        {
            param
            (
                [string]
                $File
            )

            if($FileHashCache[$File])
            {
                $FileHashCache[$File]
            }
            else
            {
                if($File -and (Test-Path $File))
                {
                    $ModuleMD5 = (Get-DIGSFileHash -Path $File -Algorithm MD5).Hash
                    $ModuleSHA256 = (Get-DIGSFileHash -Path $File -Algorithm SHA256).Hash

                    $FileHashCache[$File] = New-Object PSObject -Property @{
                        MD5 = $ModuleMD5
                        SHA256 = $ModuleSHA256
                    }

                    $FileHashCache[$File]
                }
            }
        }
    }

    process
    {
        foreach($Process in $Processes)
        {
            $Proc = Get-Process -Id $Process.ProcessId -ErrorAction SilentlyContinue
            $Path = $Proc.Path
            $LoadedModules = $null
            $Owner = $null
            $OwnerStr = $null

            if($Proc)
            {
                #$PE = Get-PE -ModuleBaseAddress $Proc.MainModule.BaseAddress -ProcessID $Process.ProcessId
                $Proc.Modules | ForEach-Object {
                    if($_) 
                    {
                        $ModuleHash = Get-DIGSCachedFileHash -File $_.FileName

                        $_ | Add-Member NoteProperty -Name "MD5Hash" -Value $ModuleHash.MD5
                        $_ | Add-Member NoteProperty -Name "SHA256Hash" -Value $ModuleHash.SHA256
                    }
                }
                $LoadedModules = $Proc.Modules
            }

            # Get file information
            $FileHash = $null
            if($Path -ne $null -and (Test-Path $Path)) {
                # TODO: Add error handling here in case we can't read the file (wonky exe permissions)

                $FileHash = Get-DIGSCachedFileHash -File $Path

                $File = (Get-ChildItem $Path)
                $FileSize = $File.Length
                $FileCreationTime = $File.CreationTimeUtc
                $FileLastAccessTime = $File.LastAccessTimeUtc
                $FileLastWriteTime = $File.LastWriteTimeUtc
                $FileExtension = $File.Extension
                $ProcessId = $Process.ProcessId
            } else {
                if($Proc.Id -ne 0 -and $Proc.Id -ne 4)
                {
                    #Write-Warning "Could not find executable path. PSProcessName: $($Proc.Name) PSPid: $($Proc.Id) WMIProcName: $($Process.Name) WMIPid: $($Process.ProcessId)"
                }
                $Path = ''
            }
        
            # Get the process owner
            $NTVersion = [System.Environment]::OSVersion.Version
            try {
                if($NTVersion.Major -ge 6)
                {
                    $Owner = $Process.GetOwner()
                    if($Owner -and ($Owner.Domain -or $Owner.User)) {
                        $OwnerStr = "$($Owner.Domain)\$($Owner.User)"
                    }
        
                    $OwnerObj = $Process.GetOwnerSid()
                    if($OwnerObj)
                    {
                        $OwnerSid = $OwnerObj.Sid
                    }
                }
            } catch {}

            $LoadedModuleList = $LoadedModules | sort ModuleName | select -ExpandProperty ModuleName
            $ParentProcess = Get-Process -Id $Process.ProcessId -ErrorAction SilentlyContinue
        
            $ErrorActionPreference = 'Stop'
            $Output = @{
                Name = $Process.Name
                Path = [string]$Process.Path
                CommandLine = $Process.CommandLine
                MD5Hash = $FileHash.MD5
                SHA256Hash = $FileHash.SHA256
                FileSize = $FileSize
                FileCreationTime = $FileCreationTime
                FileLastAccessTime = $FileLastAccessTime
                FileLastWriteTime = $FileLastWriteTime
                FileExtension = $FileExtension
                Owner = $OwnerStr
                OwnerSid = $OwnerSid
                ParentProcessId = $Process.ParentProcessID
                ParentProcessName = $ParentProcess.Name
                ProcessId = $ProcessId
                ## PE = $PE
                #LoadedModules = $LoadedModules | select *
                LoadedModulesList = ($LoadedModuleList -join ";").ToLower()
            }

            try {
                $null = $Output
            } catch {
                Write-Error $_
            }

            if($ReturnHashtables) {
                $Output
            } else {
                 New-Object PSObject -Property $Output
            }
        }
    }

    end
    {

    }
}


Get-PSIProcess | Format-List