
function Invoke-BulkCopy{
    [CmdletBinding()]
    Param(
        [Parameter( Mandatory = $True)][String]$folder,
        [Parameter( Mandatory = $True)][String]$target,
        [Parameter( Mandatory = $False)][String]$filter,
        [Parameter( Mandatory = $False)][String]$exclude,
        [Parameter( Mandatory = $False)][String]$where,
        [Parameter( Mandatory = $False)][Switch]$recurse,
        [Parameter( Mandatory = $False)][Switch]$forensic
    )

    if(test-path $folder){
        if ($recurse) {
            if ($filter) {
                if ($exclude) {
                    if ($where) { $items = get-childitem $folder -Recurse -Filter $filter -Exclude $exclude -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -Recurse -Filter $filter -Exclude $exclude -Force }
                }
                else {
                    if ($where) { $items = get-childitem $folder -Recurse -Filter $filter -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -Recurse -Filter $filter -Force }
                }
            }
            else{
                if ($exclude) {
                    if ($where) { $items = get-childitem $folder -Recurse -exclude $exclude -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -Recurse -exclude $exclude -Force }
                }
                else {
                    if ($where) { $items = get-childitem $folder -Recurse -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -Recurse -Force }
                }
            }
        }
        else {
            if ($filter) {
                if ($exclude) {
                    if ($where) { $items = get-childitem $folder -Filter $filter -exclude $exclude -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -Filter $filter -exclude $exclude -Force }
                }
                else {
                    if ($where) { $items = get-childitem $folder -Filter $filter -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -Filter $filter -Force }
                }
            }
            else{
                if ($exclude) {
                    if ($where) { $items = get-childitem $folder -exclude $exclude -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -exclude $exclude -Force }
                }
                else {
                    if ($where) { $items = get-childitem $folder -exclude $exclude -Force | Where-Object { $where } }
                    else { $items = get-childitem $folder -exclude $exclude -Force }
                }
            }
        }

        $CopyTargets = @{} # build hashtable of targets

        $items | ForEach-Object { 
            $out = $_.FullName -replace [regex]::escape($folder), $target

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
