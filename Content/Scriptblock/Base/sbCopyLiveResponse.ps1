
function Copy-LiveResponse{
<#.
.SYNOPSIS 
   Copy-LiveResponse tool to enable forensic raw copy and Copy-Item use cases.

.DESCRIPTION
    Checks for existence of items and uses Get-ChildItem and builds a hash table of files and folders to copy.
    Uses Copy-Item or Invoke-ForensicCopy to copy 
    Runspace variable $Global:Vss used to collect Volume Shadow Copy artefacts. If exists path and dest fields rebuilt to include VSC.

    $path = Get-ChildItem path of target, can be folder or file
    $dest = Destination to copy to
    $filter = Get-ChildItem -filter
    $exclude = Get-ChildItem -exclude
    $include = Get-ChildItem -include
    $where = GetChildItem | Where-Object { $where }
    $recurse = Get-ChildItem -recurse switch
    $forensic = use Invoke-ForensicCopy    

.EXAMPLE 
    Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows\Explorer" -dest "$out\AppData\Local\Microsoft\Windows\Explorer" -filter "thumbcache*.db"
#>
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory = $True)][String]$path,
        [Parameter( Mandatory = $True)][String]$dest,
        [Parameter( Mandatory = $False)][String]$filter,
        [Parameter( Mandatory = $False)][String]$exclude,
        [Parameter( Mandatory = $False)][String]$include,
        [Parameter( Mandatory = $False)][String]$where,
        [Parameter( Mandatory = $False)][Switch]$recurse,
        [Parameter( Mandatory = $False)][Switch]$forensic
    ) 

    # Create small hash table of path:dest:vssFlag to accomodate VSS usecase
    $PathTable = @{}

    if ($Vss) { 
        Foreach ($Drive in $Vss) {
            If ($Drive -match 'vss') {    
                $dPath = $Drive + (Split-Path $Path -NoQualifier)
                $stringFind = "$env:computername\" + $env:systemdrive.TrimEnd(':')
                $stringReplace = "$env:computername\" + $(split-path $Drive -leaf)
                $dDest = $Dest.Replace($stringFind,$stringReplace)

                $PathTable[$PathTable.count] = @($dPath,$dDest,$True) 
            }
            Else { $PathTable[$PathTable.count] = @($Path,$Dest,$False) }
        }
    }
    Else { $PathTable[$PathTable.count] = @($Path,$Dest,$False) }

    Foreach ($Entry in $PathTable.getEnumerator() | Where-Object { $_.Value[0] } | Sort Key) {
        
        # setup copy variables
        $Path = $Entry.Value[0].trimend("\") + "\"
        $Dest = $Entry.Value[1]
        $VssFlag = $Entry.Value[2]
        
        # Setup search for items to copy
        $searchCommand = "Get-ChildItem -Force -Path `"$Path`" -ErrorAction SilentlyContinue"
        If ($Recurse) { $searchCommand = "$searchCommand -Recurse " }
        If ($Filter)  { $searchCommand = "$searchCommand -Filter `"$Filter`"" }
        If ($Exclude) { $searchCommand = "$searchCommand -Exclude `"$Exclude`"" }
        If ($Include) { $searchCommand = "$searchCommand -Include `"$Include`"" }
        If ($Where)   { $searchCommand = "$searchCommand | Where-Object { `"$Where`" }" }

        # Run search
        $items = Invoke-Expression $searchCommand
              
        # Build hashtable of targets
        $CopyTargets = @{} 
        $hashList = @{'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' = $true} # $Null hash

        # If results of search bulid Target table
        $items | Where-Object { !$_.PSIsContainer -And $_.FullName } | ForEach-Object {
            $out = $_.FullName -replace [regex]::escape($path.trim("\")), $dest

            # This line is to exclude VSS mounts from loose recursive queries the VSS will be covered
            # during -vss search
            If ($_.FullName -like "C:\Windows\Temp\VSS*" -and $out -like "$dest\Windows\Temp\vss*") {
                return
            }
               
            # kernel locked files may fail silentlycontinue in filesize ad hash function
            $fileSize = (Get-Item $($_.FullName) -Force -ErrorAction SilentlyContinue).length
            $FileHash = Get-Hash -path $($_.FullName) -Algorithm SHA256 | Select-Object sha256

            $CopyTargets[$CopyTargets.count] = @($_.FullName,$out,$fileSize,$FileHash.sha256)
        }

        # Copy items in hashtable or cover folder use case
        foreach ($item in $CopyTargets.getEnumerator() | Sort Key) {
            $ItemIn = $item.value[0]
            $ItemOut = $item.value[1]
            $fileSize = $Item.value[2]
            $sha256 = $Item.value[3]
            
            If ($ItemIn) {

                # Forensic copy falling back (likley redundant to Copy-Item)
                if ($forensic -and !$VssFlag) {
                    If (-Not (Test-Path (Split-Path -Path $ItemOut))) {
                        New-Item (Split-Path -Path $ItemOut) -type directory -Force | Out-Null
                    }
                    try {
                        Invoke-ForensicCopy -InFile $ItemIn -OutFile $ItemOut
                        $LogAction = "ForensicCopy"
                    }
                    Catch {
                        try {
                            Copy-Item -Path $ItemIn -Destination $ItemOut -Force -ErrorAction stop
                            if ($Verbose) { Write-Host "INFO: $itemIn fell back to Copy-Item." }
                            $LogAction = "Copy-Item fallback"
                        }
                        Catch { 
                            Write-Host "ERROR: $ItemIn raw copy."
                            $LogAction = "ERROR: ForensicCopy"
                        }   
                    }
                }
                # standard Copy-Item falling back to Forensic Copy
                Else {
                    # using dedup flag to determine if skipping collection.
                    $Dedup = $Null
                    If ($VssFlag) {
                        # Checking ItemIn sha256 and comparing hashes in array that are not the same ItemIn
                        $sha256 = (Get-Hash -Path ($ItemIn) -Algorithm SHA256).sha256
                        foreach ($item in $copyTargets.Values){
                            # Chack previous collections to cover previous collections
                            If ($Global:hashlist["$sha256"]) { $Dedup = $True}
                            # check current item hash in vss for items not current path
                            elseif ($sha256 -eq $item[2] -and $item[0] -ne $ItemIn) { $Dedup = $True}
                        }
                        $ItemInVss = "VolumeShadowCopy" + $($ItemIn -split "\\vss")[1]
                    }

                    If ( !$Dedup) {
                        # create Out folder structure if not exist
                        If (-Not (Test-Path (Split-Path -Path $ItemOut))) {
                            New-Item (Split-Path -Path $ItemOut) -type directory -Force | Out-Null
                        }
                        try {
                            Copy-Item -Path $ItemIn -Destination $ItemOut -Force -ErrorAction Stop
                            $LogAction = "Copy-Item"
                        }
                        Catch { 
                            try { 
                                Invoke-ForensicCopy -InFile $ItemIn -OutFile $ItemOut
                                if ($Verbose) { 
                                    if ($VssFlag) { Write-Host "INFO: $ItemInVss fell back to Raw copy." }
                                    else { Write-Host "INFO: $ItemIn fell back to Raw copy." }
                                }
                                $LogAction = "ForensicCopy fallback"
                            }
                            Catch {
                                if ($VssFlag) { Write-Host "ERROR:"$ItemInVss "copy." }
                                Else { Write-Host "ERROR: $ItemIn copy." }
                                $LogAction = "ERROR: Copy-Item"
                            } 
                        }
                    }
                    Else { 
                        $LogAction = "VSS Dedup"
                        $ItemOut = $Null
                        if ($Verbose) { Write-Host "INFO: VSS Dedup $ItemInVss" }
                    }
                }
                # Write line to CollectionLog
                If ($VssFlag) { $ItemIn = $ItemInVss }
                # setting to skip
                If ($ItemOut) {
                    If ($sha256) { 
                        # adding hashtables will error if duplicate keys which occurs on broad collections
                        if (!$GLobal:hashList["$sha256"]) { $Global:hashList.add($sha256,$True) | out-null}
                    }
                }
                Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),$LogAction,$ItemIn,$ItemOut,$sha256" -Encoding Ascii
            }
        }

    }
}
# Making runspace scope
$Global:hashList = @{'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'= $True} # $Null hash
