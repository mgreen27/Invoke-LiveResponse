
function Invoke-BulkCopy{
<#.
.SYNOPSIS 
    BulkCopy tool to enable forensic raw copy and Copy-Item use cases.

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
        PS> Invoke-BulkCopy -path "$profile\AppData\Local\Microsoft\Windows\Explorer" -dest "$out\AppData\Local\Microsoft\Windows\Explorer" -filter "thumbcache*.db"
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
        if(test-path -path $path){
            if ($recurse) {
                if ($filter) {
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 1 - Invoke-BulkCopy -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -Include $Include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force | Where-Object { $where }"
                            }
                            else {
                                # 2 - Invoke-BulkCopy -path $path -dest $dest -Recurse -filter $filter -Exclude $exclude -Include $Include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force"
                            }
                        }
                        else {
                            if ($where) {
                                # 3 - Invoke-BulkCopy -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Force | Where-Object { $where }"
                            }
                            else {
                                # 4 - Invoke-BulkCopy -path $path -dest $dest -recurse -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) {
                                # 5 - Invoke-BulkCopy -path $path -dest $dest -recurse -filter $filter -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Include $include -Force | Where-Object { $where }"
                            }
                            else {
                                # 6 - Invoke-BulkCopy -path $path -dest $dest -recurse -filter $filter -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 7 - Invoke-BulkCopy -path $path -dest $dest -recurse -filter $filter -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Force | Where-Object { $where }"
                            }
                            else {
                                # 8 - Invoke-BulkCopy -path $path -dest $dest -recurse -filter $filter
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Filter $filter -Force" 
                            }
                        }
                    }
                }
                else{
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 9 - Invoke-BulkCopy -path $path -dest $dest -Recurse -Exclude $Exlude -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else {
                                # 10 - Invoke-BulkCopy -path $path -dest $dest -Recurse -Exclude $Exlude -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 11 - Invoke-BulkCopy -path $path -dest $dest -Recurse -Exclude $Exlude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else {
                                # 12 - Invoke-BulkCopy -path $path -dest $dest -Recurse -Exclude $Exlude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) { 
                                # 13 - Invoke-BulkCopy -path $path -dest $dest -Recurse -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Include $include -Recurse -Force | Where-Object { $where }"
                            }
                            else { 
                                # 14 - Invoke-BulkCopy -path $path -dest $dest -Recurse -Include $includee
                                $items = Invoke-Expression "Get-ChildItem -path $path -Include $include -Recurse -Force"
                            }
                        }
                        Else { 
                            if ($where) { 
                                # 15 - Invoke-BulkCopy -path $path -dest $dest -Recurse -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Recurse -Force | Where-Object { $where }"
                            }
                            else { 
                                # 16 - Invoke-BulkCopy -path $path -dest $dest -Recurse
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
                                # 17 - Invoke-BulkCopy -path $path -dest $dest -filter $filter -Exclude $exclude -Include $Include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 18 - Invoke-BulkCopy -path $path -dest $dest -filter $filter -Exclude $exclude -Include $Include 
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 19 - Invoke-BulkCopy -path $path -dest $dest -filter $filter -Exclude $exclude -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else { 
                                # 20 - Invoke-BulkCopy -path $path -dest $dest -filter $filter -Exclude $exclude
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) {
                                # 21 - Invoke-BulkCopy -path $path -dest $dest -filter $filter -Include $include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 22 - Invoke-BulkCopy -path $path -dest $dest -filter $filter -Include $include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Include "$include" -Force"
                            }
                        }
                        Else {
                            if ($where) {
                                # 23 - Invoke-BulkCopy -path $path -dest $dest -filter $filter -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Force | Where-Object { $where }"
                            }
                            else {
                                # 24 - Invoke-BulkCopy -path $path -dest $dest -filter $filter
                                $items = Invoke-Expression "Get-ChildItem -path $path -Filter $filter -Force"
                            }
                        }
                    }
                }
                else{
                    if ($exclude) {
                        if ($include) {
                            if ($where) {
                                # 25 - Invoke-BulkCopy -path $path -dest $dest -exclude $exclude -Include $include
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude best used with -recurse}"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 26 - Invoke-BulkCopy -path $path -dest $dest -exclude $exclude -Include $include
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude best used with -recurse}"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) { 
                                # 27 - Invoke-BulkCopy -path $path -dest $dest -exclude $exclude -where $where
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude -Force | Where-Object { $where } best used with -recurse"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Force | Where-Object { $where }"
                            }
                            else {
                                # 28 - Invoke-BulkCopy -path $path -dest $dest -exclude $exclude (not reccomended without recurse)
                                Write-host "`t`tPlease review logic: Get-ChildItem -path $path -exclude $exclude -Force best used with -recurse"
                                $items = Invoke-Expression "Get-ChildItem -path $path -exclude $exclude -Force"
                            }
                        }
                    }
                    else {
                        if ($include) {
                            if ($where) { 
                                # 29 - Invoke-BulkCopy -path $path -dest $dest -include -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path  -Include $include -Force | Where-Object { $where }"
                            }
                            else { 
                                # 30 - Invoke-BulkCopy -path $path -dest $dest -include
                                $items = Invoke-Expression "Get-ChildItem -path $path -Include $include -Force"
                            }
                        }
                        Else {
                            if ($where) { 
                                # 31 - Invoke-BulkCopy -path $path -dest $dest -where $where
                                $items = Invoke-Expression "Get-ChildItem -path $path -Force | Where-Object { $where }"
                            }
                            else { 
                                # 32 - Invoke-BulkCopy -path $path -dest $dest
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

                if ($recurse -and $_.PSIsContainer) {
                    $CopyTargets[$CopyTargets.count] = @($_.FullName,$out,"FOLDER")
                }
                elseif (-not $_.PSIsContainer) {
                    $CopyTargets[$CopyTargets.count] = @($_.FullName,$out,"FILE") 
                }
            }


            # Copy items in hashtable or cover folder use case
            foreach ($item in $CopyTargets.getEnumerator() | Sort Key) {

                if ($item.value[2] -eq "FOLDER" -And $item.value[1]) {
                    New-Item -Path $item.value[1] -ItemType directory -Force | out-null
                }
                Elseif ($item.value[2] -eq "FILE" -And $item.value[1]) {

                    If (!(Test-Path (Split-Path -Path $item.value[1]))) {
                        New-Item (Split-Path -Path $item.value[1]) -type directory -Force | Out-Null
                    }

                    # Forensic copy falling back (likley redundant to Copy-Item)
                    if ($forensic -and !$VssFlag) {

                        try {
                            Invoke-ForensicCopy -InFile $item.value[0] -OutFile $item.value[1]
                        }
                        Catch {
                            try { 
                                Copy-Item -Path $item.value[0] -Destination $item.value[1] -Force 
                                Write-Host "Info:"$item.value[0]"fell back to Copy-Item."
                            }
                            Catch { Write-Host "Error:"$item.value[0]"raw copy." }   
                        }
                    }
                    # standard Copy-Item falling back to Forensic Copy
                    Else {
                        try {
                            Copy-Item -Path $item.value[0] -Destination $item.value[1] -Force
                        }
                        Catch { 
                            try { 
                                Invoke-ForensicCopy -InFile $item.value[0] -OutFile $item.value[1]
                                Write-Host "Info:"$item.value[0]"fell back to Raw copy."
                            }
                            Catch {
                                Write-Host "Error:"$item.value[0]"copy."
                            } 
                        }
                    }
                }
            }
        }
    }
}
