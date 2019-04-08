
Write-Host -ForegroundColor Cyan "`nStarting LiveResponse."

$Results = $Output + "\LiveResponse"

# Test for root of drive
if ([System.IO.path]::GetPathRoot($(Split-Path $MyInvocation.MyCommand.Path -Parent)) -eq $(Split-Path $MyInvocation.MyCommand.Path -Parent)) {
    $Content = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)Content"
}
Else { 
    $Content = "$(Split-Path $MyInvocation.MyCommand.Path -Parent)\Content"
}

Write-Host "`tFrom Content `n`t$Content"
Write-Host "`tNote: Error handling during LiveResponse mode is required to be handled in content.`n"
Write-Host "`tTo Results `n`t$Results`n"

$Scripts = Get-ChildItem -Path "$Content\*.ps1" -ErrorAction SilentlyContinue
If (!$scripts) { "INFO:`tNo LiveResponse content found" }

If (Test-Path $Results) { Remove-Item $Results -Recurse -Force -ErrorAction SilentlyContinue | Out-Null }
New-Item $Results -type directory -ErrorAction SilentlyContinue | Out-Null

Foreach ($Script in $Scripts){
    Write-Host -ForegroundColor Yellow "`tRunning " $Script.Name
    [gc]::collect()
    try { 
        $ScriptBasename = $Script.BaseName
        $ScriptResults = Invoke-Expression $Script.FullName -ErrorAction SilentlyContinue 
        $ScriptResults | Out-File ("$Results\$ScriptBaseName.txt")
        Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),LiveResponse,$ScriptBasename,$Results\$ScriptBaseName.txt," -Encoding Ascii
        $ScriptResults = $null
    }
    catch { 
        Write-Host -ForegroundColor Red "`tError in $Script" 
        Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),LiveResponse,ERROR: $ScriptBasename,,"
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
