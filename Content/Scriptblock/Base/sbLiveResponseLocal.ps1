
Write-Host -ForegroundColor Cyan "`nStarting LiveResponse."

$Results = $Output + "\LiveResponse"

Write-Host "`tFrom Content `n`t$Content"
Write-Host "`tNote: Error handling during LiveResponse mode is required to be handled in content.`n"
Write-Host "`tTo Results `n`t$Results`n"

$Scripts = Get-ChildItem -Path "$Content\*.ps1"

If (Test-Path $Results) { Remove-Item $Results -Recurse -Force -ErrorAction SilentlyContinue | Out-Null }
New-Item $Results -type directory -ErrorAction SilentlyContinue | Out-Null

Foreach ($Script in $Scripts){
    Write-Host -ForegroundColor Yellow "`tRunning " $Script.Name
    [gc]::collect()
    try { 
        $SctiptBasename = $Script.BaseName
        $ScriptResults = Invoke-Expression $Script.FullName -ErrorAction SilentlyContinue 
        $ScriptResults | Out-File ($Results + "\" + $Script.BaseName + ".txt")
        Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),LiveResponse,$SctiptBasename,$Results\$ScriptBaseName.txt," -Encoding Ascii
        $ScriptResults = $null
    }
    catch { 
        Write-Host -ForegroundColor Red "`tError in $Script" 
        Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),LiveResponse,ERROR: $SctiptBasename,," -Encoding Ascii
        $ScriptResults = $null
    }
}

# Remove null results for simple analysis
Foreach ($Item in (Get-ChildItem -Path $Results -Force)){
    If ($Item.length -eq 0){Remove-Item -Path $Item.FullName -Force}
}

If (Get-ChildItem -Path $Results -Force){
    Write-Host -ForegroundColor Yellow "`nListing valid results in LiveResponse collection:"
    Get-ChildItem -Path $Results -Force | select-object LastWriteTimeUtc, Length, Name | Format-Table -AutoSize
}
Else {
    Write-Host -ForegroundColor Yellow "`nNo valid LiveResponse results"
}

Write-Host -ForegroundColor Cyan "`nLiveResponse script collection complete`n"
