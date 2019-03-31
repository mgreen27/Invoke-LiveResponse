
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


    Foreach ($Entry in $PathTable.getEnumerator() | Sort Key) {

        $Path = $Entry.Value[0]
        $Dest = $Entry.Value[1]
        $VssFlag = $Entry.Value[2]

        # Test for path and Get applicable files and folders for copy
        if(test-path -path $path) {
            if ($recurse) {
                if ($filter) {
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 1 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -Include $Include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force -ErrorAction SilentlyContinue | Where-Object { $where }"
                            }
                            else {
                                # 2 - Copy-LiveResponse -path $path -dest $dest -Recurse -filter $filter -Exclude $exclude -Include $Include
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force -ErrorAction SilentlyContinue"
                            }
                        }
                        else {
                            if ($where) {
                                # 3 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Exclude $exclude -Force -ErrorAction SilentlyContinue | Where-Object { $where }"
                            }
                            else {
                                # 4 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Exclude $exclude -Force -ErrorAction SilentlyContinue"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) {
                                # 5 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Include $include -Force -ErrorAction SilentlyContinue | Where-Object { $where }"
                            }
                            else {
                                # 6 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Include $include -Force -ErrorAction SilentlyContinue"
                            }
                        }
                        Else {
                            if ($where) {
                                # 7 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Force -ErrorAction SilentlyContinue | Where-Object { $where }"
                            }
                            else {
                                # 8 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Filter $filter -Force -ErrorAction SilentlyContinue" -ErrorAction SilentlyContinue
                            }
                        }
                    }
                }
                else {
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 9 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -exclude $exclude -Include $include -Force -ErrorAction SilentlyContinue | Where-Object { $where }"
                            }
                            else {
                                # 10 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -exclude $exclude -Include $include -Force -ErrorAction SilentlyContinue"
                            }
                        }
                        Else {
                            if ($where) {
                                # 11 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -exclude $exclude -Force -ErrorAction SilentlyContinue | Where-Object { $where }"
                            }
                            else {
                                # 12 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -exclude $exclude -Force -ErrorAction SilentlyContinue"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) { 
                                # 13 - Copy-LiveResponse -path $path -dest $dest -Recurse -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Include $include -Recurse -Force | Where-Object { $where }"
                            }
                            else { 
                                # 14 - Copy-LiveResponse -path $path -dest $dest -Recurse -Include $includee
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Include $include -Recurse -Force"
                            }
                        }
                        Else { 
                            if ($where) { 
                                # 15 - Copy-LiveResponse -path $path -dest $dest -Recurse -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Force | Where-Object { $where }"
                            }
                            else { 
                                # 16 - Copy-LiveResponse -path $path -dest $dest -Recurse
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Recurse -Force"
                            }
                        }
                    }
                }
            }
            else {
                if ($filter) {
                    if ($exclude) {
                        if ($include) {
                            if ($where) { 
                                # 17 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Exclude $exclude -Include $Include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 18 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Exclude $exclude -Include $Include 
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 19 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else { 
                                # 20 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Exclude $exclude
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) {
                                # 21 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 22 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 23 - Copy-LiveResponse -path $path -dest $dest -filter $filter -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -Force | Where-Object { $where }"
                            }
                            else {
                                # 24 - Copy-LiveResponse -path $path -dest $dest -filter $filter
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Filter $filter -Force"
                            }
                        }
                    }
                }
                else{
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 25 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude -Include $include
                                Write-host "`t`tPlease review logic: Get-ChildItem -path '$path' -exclude $exclude best used with -recurse}"
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 26 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude -Include $include
                                Write-host "`t`tPlease review logic: Get-ChildItem -path '$path' -exclude $exclude best used with -recurse}"
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) { 
                                # 27 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude -where $where
                                Write-host "`t`tPlease review logic: Get-ChildItem -path '$path' -exclude $exclude -Force | Where-Object { $where } best used with -recurse"
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else {
                                # 28 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude (not reccomended without recurse)
                                Write-host "`t`tPlease review logic: Get-ChildItem -path '$path' -exclude $exclude -Force best used with -recurse"
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) { 
                                # 29 - Copy-LiveResponse -path $path -dest $dest -include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path'  -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 30 - Copy-LiveResponse -path $path -dest $dest -include
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) { 
                                # 31 - Copy-LiveResponse -path $path -dest $dest -where $where
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Force | Where-Object { $where }"
                            }
                            else { 
                                # 32 - Copy-LiveResponse -path $path -dest $dest
                                $items = Invoke-Expression "Get-ChildItem -path '$path' -Force"
                            }
                        }
                    }
                }
            }

            # Build hashtable of targets
            $CopyTargets = @{} 
            $hashList = @{'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' = $true} # $Null hash

            # If results of search bulid Target table
            $items | Where-Object { !$_.PSIsContainer -And $_.FullName } | ForEach-Object {
                $out = $_.FullName -replace [regex]::escape($path), $dest
                $fileSize = (Get-Item $_.FullName -Force).length
                # kernel locked files may fail silentlycontinue in hash function
                $FileHash = Get-FileHash $_.FullName -Algorithm SHA256 | Select-Object sha256
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
                                Copy-Item -Path $ItemIn -Destination $ItemOut -Force 
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
                            $sha256 = (Get-FileHash -Path $ItemIn -Algorithm SHA256).sha256
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
                                Copy-Item -Path $ItemIn -Destination $ItemOut -Force
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
}
# Making runspace scope
$Global:hashList = @{'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'= $True} # $Null hash
