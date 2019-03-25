
function Copy-LiveResponse{
<#.
.SYNOPSIS 
   Copy-LiveResponse tool to enable forensic raw copy and Copy-Item use cases.

    Author - Matt Green (@mgreen27)

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

.NOTES
    

.EXAMPLE 
        PS> Copy-LiveResponse -path "$profile\AppData\Local\Microsoft\Windows\Explorer" -dest "$out\AppData\Local\Microsoft\Windows\Explorer" -filter "thumbcache*.db"
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


    $ErrorActionPreference = "Silentlycontinue"

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
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force | Where-Object { $where }"
                            }
                            else {
                                # 2 - Copy-LiveResponse -path $path -dest $dest -Recurse -filter $filter -Exclude $exclude -Include $Include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force"
                            }
                        }
                        else {
                            if ($where) {
                                # 3 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Force | Where-Object { $where }"
                            }
                            else {
                                # 4 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) {
                                # 5 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Include $include -Force | Where-Object { $where }"
                            }
                            else {
                                # 6 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 7 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Force | Where-Object { $where }"
                            }
                            else {
                                # 8 - Copy-LiveResponse -path $path -dest $dest -recurse -filter $filter
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Force" 
                            }
                        }
                    }
                }
                else {
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 9 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else {
                                # 10 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 11 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else {
                                # 12 - Copy-LiveResponse -path $path -dest $dest -Recurse -Exclude $Exlude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) { 
                                # 13 - Copy-LiveResponse -path $path -dest $dest -Recurse -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Include $include -Recurse -Force | Where-Object { $where }"
                            }
                            else { 
                                # 14 - Copy-LiveResponse -path $path -dest $dest -Recurse -Include $includee
                                $items = Invoke-Expression "Get-ChildItem -path $path -Include $include -Recurse -Force"
                            }
                        }
                        Else { 
                            if ($where) { 
                                # 15 - Copy-LiveResponse -path $path -dest $dest -Recurse -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Force | Where-Object { $where }"
                            }
                            else { 
                                # 16 - Copy-LiveResponse -path $path -dest $dest -Recurse
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Force"
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
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 18 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Exclude $exclude -Include $Include 
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 19 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else { 
                                # 20 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Exclude $exclude
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) {
                                # 21 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 22 - Copy-LiveResponse -path $path -dest $dest -filter $filter -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Include "$include" -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 23 - Copy-LiveResponse -path $path -dest $dest -filter $filter -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Force | Where-Object { $where }"
                            }
                            else {
                                # 24 - Copy-LiveResponse -path $path -dest $dest -filter $filter
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Force"
                            }
                        }
                    }
                }
                else{
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 25 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude -Include $include
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude best used with -recurse}"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 26 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude -Include $include
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude best used with -recurse}"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) { 
                                # 27 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude -where $where
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude -Force | Where-Object { $where } best used with -recurse"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else {
                                # 28 - Copy-LiveResponse -path $path -dest $dest -exclude $exclude (not reccomended without recurse)
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude -Force best used with -recurse"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) { 
                                # 29 - Copy-LiveResponse -path $path -dest $dest -include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path  -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 30 - Copy-LiveResponse -path $path -dest $dest -include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) { 
                                # 31 - Copy-LiveResponse -path $path -dest $dest -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Force | Where-Object { $where }"
                            }
                            else { 
                                # 32 - Copy-LiveResponse -path $path -dest $dest
                                $items = Invoke-Expression "Get-ChildItem -path $path -Force"
                            }
                        }
                    }
                }
            }

            # Build hashtable of targets
            $CopyTargets = @{}

            $items | ForEach-Object { 
                $out = $_.FullName -replace [regex]::escape($path), $dest
                If (-not $_.PSIsContainer) { 
                    $FileHash = Get-FileHash $_.FullName -Algorithm sha256 | Select-Object sha256
                    $CopyTargets[$CopyTargets.count] = @($_.FullName,$out,$FileHash.sha256)
                }
            }

            # Copy items in hashtable or cover folder use case
            foreach ($item in $CopyTargets.getEnumerator() | Sort Key) {
                
                $ItemIn = $item.value[0]
                $ItemOut = $item.value[1]
                $sha256 = $item.value[2]

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
                                Write-Host "Info: $itemIn fell back to Copy-Item."
                                $LogAction = "Copy-Item fallback"
                            }
                            Catch { 
                                Write-Host "Error: $ItemIn raw copy."
                                $LogAction = "Error: ForensicCopy"
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
                                If ($sha256 -eq $item[2] -and $item[0] -ne $ItemIn) { 
                                    $Dedup = $True
                                }
                            }
                            $ItemIn = "VolumeShadowCopy" + $($ItemIn -split "\\vss")[1]
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
                                    Write-Host "Info: $ItemIn fell back to Raw copy."
                                    $LogAction = "ForensicCopy fallback"
                                }
                                Catch {
                                    if ( $ItemIn -match "\\vss[0-9]\\" ) { Write-Host "Error:"$ItemIn.TrimStart($env:temp) "copy." }
                                    Else { Write-Host "Error: $ItemIn copy." }
                                    $LogAction = "Error: Copy-Item"
                                } 
                            }
                        }
                        Else { 
                            $LogAction = "VSS Dedup"
                            $ItemOut = $Null
                            Write-Host "Info: VSS Dedup $ItemIn"
                        }
                    }
                    # Write line to CollectionLog
                    Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),$LogAction,$ItemIn,$ItemOut,$sha256" -Encoding Ascii
                }
            }
        }
    }
}
