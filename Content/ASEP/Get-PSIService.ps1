function Get-PSIService 
{
<#
    .SYNOPSIS

        Returns detailed service information.

        Author: Jared Atkinson
        License: BSD 3-Clause
        Required Dependencies: None
        Optional Dependencies: None

#>
    [CmdletBinding()]
    Param (
        [switch]
        $ReturnHashtables
    )

    Begin
    {
        function Get-PathFromCommandLine
        {
            Param
            (
                [Parameter(Mandatory = $true)]
                [string]
                $CommandLine
            )

            if(Test-Path -Path $CommandLine -ErrorAction SilentlyContinue)
            {
                $CommandLine
            }
            else
            {
                switch -Regex ($CommandLine)
                {
                    '"\s'{ $CommandLine.Split('"')[1]; break}
                    '\s-'{ $CommandLine.Split(' ')[0]; break}
                    '\s/'{ $CommandLine.Split(' ')[0]; break}
                    '"'{ $CommandLine.Split('"')[1]; break}
                    default{ $CommandLine}    
                }
            }
        }

        # Thanks to https://p0w3rsh3ll.wordpress.com/2015/02/05/backporting-the-get-filehash-function/
        function Get-DIGSFileHash
        {
            [CmdletBinding(DefaultParameterSetName = "Path")]
            param(
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
            param(
                [System.IO.Stream]
                $InputStream,

                [System.String]
                $RelatedPath,

                [System.Security.Cryptography.HashAlgorithm]
                $Hasher)

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
    
        $hashcache = @{}
        $objList = New-Object -TypeName "System.Collections.Generic.List[Object]"
    }

    Process
    {
        foreach($service in (Get-WmiObject win32_service))
        {
            if($service.PathName -ne $null)
            {
                $path = Get-PathFromCommandLine -CommandLine $service.PathName
            }
            else
            {
                $path = $null
            }

            try
            {
                if($hashcache.ContainsKey($path))
                {
                    $md5 = $hashcache[$path].MD5
                    $sha256 = $hashcache[$path].SHA256
                }
                else
                {
                    $md5 = Get-DIGSFileHash -Path $path -Algorithm MD5 -ErrorAction Stop
                    $sha256 = Get-DIGSFileHash -Path $path -Algorithm SHA256 -ErrorAction Stop
                    $obj = @{
                        MD5 = $md5
                        SHA256 = $sha256
                    }
                    $hashcache.Add($path, $obj)
                }
            }
            catch
            {
                $md5 = $null
                $sha256 = $null
            }
        
            $Props = @{
                Name = $service.Name
                CommandLine = $service.PathName
                ExecutablePath = $path
                ServiceType = $service.ServiceType
                StartMode = $service.StartMode
                Caption = $service.Caption
                Description = $service.Description
                DisplayName = $service.DisplayName
                ProcessId = $service.ProcessId
                Started = $service.Started
                User = $service.StartName
                MD5Hash = $md5.Hash
                SHA256Hash = $sha256.Hash
            }

            if($ReturnHashtables) {
                $Props
            } else {
                New-Object -TypeName psobject -Property $Props
            }
        }
    }

    End
    {

    }
}

Get-PSIService | Format-List