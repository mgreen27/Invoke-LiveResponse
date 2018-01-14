function Invoke-ForensicCopy
{
<#
.SYNOPSIS
    Function a ForensicCopy with Powerforensics ForensicDD 

    Name: Invoke-ForensicCopy.ps1
    Version: 1.0
    Author: Matt Green (@mgreen27)

.DESCRIPTION
    When using Powerforensics FileCopy modules Powerforensics takes a byte array of the whole file.
    This is the cause of a maxium file size of [Int32]::MaxValue bytes and uses excessive memory for large file copies.
    Invoke-ForensicCopy uses ForensicDD method and splits the copy into smaller chunks using BytesPerCluster as a factor.

.PARAMETER InFile
    File to ForensicCopy - eg c:\folder\file.ext

.PARAMETER OutFile
    Target file - eg T:\copied\file.ext

.PARAMETER DataStream
    An optional paramater for target Datastream. e.g non $DATA attributes like the UsnJournal $J

.EXAMPLE
    Invoke-ForensicCopy -InFile "C:\`$MFT" -OutFile "T:\disk\`$MFT"
    Copies $MFT to T:\$MFT

.EXAMPLE
    -InFile "C:\`$Extend\`$UsnJrnl" -OutFile "T:\Disk\`$J" -DataStream "`$J""
    Copies UsnJournal $J to T:\disk\$J (non sparse only)

.EXAMPLE
    Invoke-ForensicCopy -InFile "C:\folder\file.ext" -OutFile "T:\disk\file.ext" -DataStream "DATA"
    Copies file.ext specifying "DATA" data stream (optional switch)
    
.NOTES
    Both the max file and memory issue is resolved using Invoke-ForensicCopy
    One special case for the UsnJournal $J where sparse data is dropped to improve collection performance (sparse data is null value)
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)][String]$InFile,
        [Parameter( Mandatory = $True)][String]$OutFile,
        [Parameter(Mandatory = $False)][String]$DataStream
        )

    If ($InFile -eq $OutFile){Break}#redundant

    If (Test-Path $OutFile){Remove-Item $OutFile -Recurse -Force -ErrorAction SilentlyContinue | Out-Null}

    If (!$DataStream){$DataStream="DATA"}
  
    $Drive = Split-Path -Path $InFile -Qualifier
    $Vbr = [PowerForensics.FileSystems.Ntfs.NtfsVolumeBootRecord]::Get("\\.\$Drive")
    $Record = [PowerForensics.FileSystems.Ntfs.Filerecord]::Get("$Infile")


    If ($DataStream -ne "DATA"){
        $Data = $Record.Attribute |  Where-Object {$_.NameString -eq $DataStream}
        
        If($DataStream -eq "`$J"){
            $Datarun = $Data.DataRun | Where-Object {!$_.Sparse}
            
            # If No $J Datarun, dump USN via fsutil
            If (!$Datarun){
                Write-Host "No `$J Datarun found: reverting to fsutil Usn dump"
                $OutFile = $OutFile + "_dump.txt"
                If (Test-Path $OutFile){Remove-Item $OutFile -Force -ErrorAction SilentlyContinue}
 
                # If OS equal or greater than Windows 8/2012, else
                If ([Environment]::OSVersion.Version -ge (new-object 'Version' 6,2)){
                    cmd.exe /s /c "fsutil usn readjournal $Drive csv > $OutFile"
                }
                Else{
                    cmd.exe /s /c "fsutil.exe usn enumdata 1 0 1 $Drive > $OutFile"
                }
            }
        }
        Else{
            $Datarun = $Data.DataRun
        }
    }
    Else{
        $Data = $Record.Attribute |  Where-object {$_.Name -eq $DataStream -and $_.NameString -eq ""}
        $Datarun = $Data.DataRun
    }

    # If data resident then use raw byte data. Else use datarun pointer
    If ($Data.Rawdata){
        $Data.Rawdata | Set-Content $OutFile -Encoding Byte
    }
    Else{
        Foreach ($Part in $Datarun){
            #$TotalClusters = $TotalClusters + $Part.ClusterLength
            $Offset = $Part.StartCluster*$vbr.BytesPerCluster
            $Blocksize = (($Part.ClusterLength*$vbr.BytesPerCluster)/$vbr.BytesPerSector)

            If (($Blocksize % $vbr.BytesPerSector) -ne 0){
                    $Count = (($Part.ClusterLength*$vbr.BytesPerCluster)/$vbr.BytesPerSector)
                    $Blocksize = $vbr.BytesPerSector
            }
            Else{$Count = $vbr.BytesPerSector}

            [PowerForensics.Utilities.DD]::Get("\\.\$Drive",$OutFile,$Offset,$Blocksize,$Count)
            [gc]::Collect()
        }
    }
    #$TotalClusters
}


<# Test commands
Import-Module Powerforensics

Invoke-ForensicCopy -InFile "C:\`$MFT" -OutFile "C:\testMFT"
Invoke-ForensicCopy -InFile "C:\`$Extend\`$UsnJrnl" -OutFile "C:\testJ" -DataStream "`$J"
Invoke-ForensicCopy -InFile "C:\4G.vmem" -OutFile "4G.vmem"

#>
