
function Invoke-ForensicCopy {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)][String]$InFile,
        [Parameter( Mandatory = $True)][String]$OutFile,
        [Parameter(Mandatory = $False)][String]$DataStream,
        [Parameter(Mandatory = $False)][Switch]$Log
        )

    If ($InFile -eq $OutFile){ Break }
    $LogAction = "ForensicCopy"

    # test for previous version and remove if exists
    If (Test-Path $OutFile){
        Remove-Item $OutFile -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
    # create folder structure if not exis
    Elseif (-Not (Test-Path (Split-Path $OutFile))) {
        New-Item ($Out) -type directory | Out-Null
    }

    If (!$DataStream){ $DataStream="DATA" }

    $Drive = Split-Path -Path $InFile -Qualifier
    $Vbr = [PowerForensics.FileSystems.Ntfs.NtfsVolumeBootRecord]::Get("\\.\$Drive")
    $Record = [PowerForensics.FileSystems.Ntfs.Filerecord]::Get("$Infile")


    If ($DataStream -ne "DATA") {
        $Data = $Record.Attribute |  Where-Object {$_.NameString -eq $DataStream}

        If($DataStream -eq "`$J") {
            $Datarun = $Data.DataRun | Where-Object {!$_.Sparse}

            # If No $J Datarun from parsing issue, dump USN via fsutil
            If (!$Datarun) {
                Write-Host "Parsing ERROR: reverting to fsutil Usn dump"
                $OutFile = $OutFile + "_dump.txt"
                $LogAction = "Fsutil UnsnDump rollback"

                If (Test-Path $OutFile) {
                    Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
                }

                # Choose command based on OS
                If ([Environment]::OSVersion.Version -ge (new-object 'Version' 6,2)) {
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

    # If data resident then use raw byte data. Else use datarun
    If ($Data.Rawdata) {
        $Data.Rawdata | Set-Content $OutFile -Encoding Byte
    }
    Else{
        Foreach ($Part in $Datarun) {
            $Offset = $Part.StartCluster*$vbr.BytesPerCluster
            $Blocksize = (($Part.ClusterLength*$vbr.BytesPerCluster)/$vbr.BytesPerSector)

            If (($Blocksize % $vbr.BytesPerSector) -ne 0) {
                    $Count = (($Part.ClusterLength*$vbr.BytesPerCluster)/$vbr.BytesPerSector)
                    $Blocksize = $vbr.BytesPerSector
            }
            Else{
                $Count = $vbr.BytesPerSector
            }

            [PowerForensics.Utilities.DD]::Get("\\.\$Drive",$OutFile,$Offset,$Blocksize,$Count)
            [gc]::Collect()
        }
    }
    If ($Log) { 
        Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),$LogAction,$InFile,$OutFile," -Encoding Ascii
    }
}
