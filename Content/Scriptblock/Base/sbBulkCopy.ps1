
function Invoke-BulkCopy{
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

    if(test-path -path $path){
        if ($recurse) {
            if ($filter) {
                if ($exclude) {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Recurse -Filter $filter -Exclude $exclude -Include $Include -Force }
                    }
                    else {
                        if ($where) { $items = get-childitem -path $path -Recurse -Filter $filter -Exclude $exclude -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Recurse -Filter $filter -Exclude $exclude -Force }
                    }
                }
                else {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -Recurse -Filter $filter -Include $include -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Recurse -Filter $filter -Include $include -Force }
                    }
                    Else {
                        if ($where) { $items = get-childitem -path $path -Recurse -Filter $filter -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Recurse -Filter $filter -Force }
                    }
                }
            }
            else{
                if ($exclude) {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -Recurse -exclude $exclude -Include $include -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Recurse -exclude $exclude -Include $include -Force }
                    }
                    Else {
                        if ($where) { $items = get-childitem -path $path -Recurse -exclude $exclude -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Recurse -exclude $exclude -Force }
                    }
                }
                else {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -Include $include -Recurse -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Include $include -Recurse -Force }
                    }
                    Else {
                        if ($where) { $items = get-childitem -path $path -Recurse -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Recurse -Force }
                    }
                }
            }
        }
        else {
            if ($filter) {
                if ($exclude) {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -Filter $filter -exclude $exclude -Include $include -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Filter $filter -exclude $exclude -Include $include -Force }
                    }
                    Else {
                        if ($where) { $items = get-childitem -path $path -Filter $filter -exclude $exclude -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Filter $filter -exclude $exclude -Force }
                    }
                }
                else {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -Filter $filter -Include $include -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Filter $filter -Include "$include" -Force }
                    }
                    Else {
                        if ($where) { $items = get-childitem -path $path -Filter $filter -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -Filter $filter -Force }
                    }
                }
            }
            else{
                if ($exclude) {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -exclude $exclude -Include $include -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -exclude $exclude -Include $include -Force }
                    }
                    Else {
                        if ($where) { $items = get-childitem -path $path -exclude $exclude -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -exclude $exclude -Force }
                    }
                }
                else {
                    if ($include) {
                        if ($where) { $items = get-childitem -path $path -exclude $exclude -Include $include -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -exclude $exclude -Include $include -Force }
                    }
                    Else {
                        if ($where) { $items = get-childitem -path $path -exclude $exclude -Force | Where-Object { $where } }
                        else { $items = get-childitem -path $path -exclude $exclude -Force }
                    }
                }
            }
        }

        $CopyTargets = @{} # build hashtable of targets

        $items | ForEach-Object { 
            $out = $_.FullName -replace [regex]::escape($path), $dest

            if ($_.PSIsContainer) {
                $CopyTargets[$CopyTargets.count] = @($_.FullName,$out,"FOLDER")
            }
            else { $CopyTargets[$CopyTargets.count] = @($_.FullName,$out,"FILE") }
        }

        foreach ($item in $CopyTargets.getEnumerator() | Sort Key) {
            if ($item.value[2] -eq "FOLDER" -And $item.value[1]) {
                New-Item -Path $item.value[1] -ItemType directory -Force | out-null
            }
            Elseif ($item.value[2] -eq "FILE" -And $item.value[1]) {
                If (!(Test-Path (Split-Path -Path $item.value[1]))) {
                    New-Item (Split-Path -Path $item.value[1]) -type directory -Force | Out-Null
                }

                if ($forensic) {        
                    try { Invoke-ForensicCopy -InFile $item.value[0] -OutFile $item.value[1] }
                    Catch { Write-Host "`tError:"$item.value[0]"raw copy." }
                }
                Else {
                    try { Copy-Item -Path $item.value[0] -Destination $item.value[1] -Force }
                    Catch { 
                        try { 
                            Invoke-ForensicCopy -InFile $item.value[0] -OutFile $item.value[1]
                            Write-Host "`t`tInfo:"$item.value[0]"fell back to Raw copy."
                        }
                        Catch { Write-Host "`t`tError:"$item.value[0]"copy." } 
                    }
                }
            }
        }
    }
}
