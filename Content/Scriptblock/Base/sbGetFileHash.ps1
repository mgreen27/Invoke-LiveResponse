
function Get-FileHash { 
    <#
        .SYNOPSIS
            Calculates the hash on a given file based on the seleced hash algorithm.
            Original Author: Boe Prox (some mods)
    #>
    [CmdletBinding()]
    Param(
       [Parameter(Position=0,Mandatory=$true, ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$True)]
       [Alias("PSPath","FullName")]
       [string[]]$Path, 

       [Parameter(Position=1)]
       [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
       [string[]]$Algorithm = "SHA256"
    )
    Process {  
        $ErrorActionPreference = "SilentlyContinue"

        ForEach ($item in $Path) { 
            $item = (Resolve-Path $item).ProviderPath
            If (-Not ([uri]$item).IsAbsoluteUri) {
                Write-Verbose ("{0} is not a full path, using current directory: {1}" -f $item,$pwd)
                $item = (Join-Path $pwd ($item -replace "\.\\",""))
            }
           If(Test-Path $item -Type Container) {
              Write-Warning ("Cannot calculate hash for directory: {0}" -f $item)
              Return
           }
           $object = New-Object PSObject -Property @{ 
                Path = $item
            }
            #Open the Stream
            $stream = ([IO.StreamReader]$item).BaseStream
            foreach($Type in $Algorithm) {                
                [string]$hash = -join ([Security.Cryptography.HashAlgorithm]::Create( $Type ).ComputeHash( $stream ) | 
                ForEach { "{0:x2}" -f $_ })
                $null = $stream.Seek(0,0)
                #If multiple algorithms are used, then they will be added to existing object                
                $object = Add-Member -InputObject $Object -MemberType NoteProperty -Name $Type -Value $Hash -PassThru
            }
            $object.pstypenames.insert(0,'System.IO.FileInfo.Hash')
            #Output an object with the hash, algorithm and path
            Write-Output $object

            #Close the stream
            $stream.Close()
        }
    }
}
