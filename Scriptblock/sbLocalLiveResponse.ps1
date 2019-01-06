
Write-Host -ForegroundColor Cyan "`nStarting LiveResponse."

$Content = $((Get-Location).Path + '\Content')
$Date = $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)

$Output = $((Get-Location).Path) + "\" + $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd) + "Z_" + $env:computername
$Results = $Output + "\LR"

Write-Host "`tFrom Content `n`t$Content"
Write-Host "`tNote: Error handling during LiveResponse mode is required to be handled in content.`n"
Write-Host "`tTo Results `n`t$Results`n"

$Scripts = Get-ChildItem -Path "$Content\*.ps1"

If (Test-Path $Results) {Remove-Item $Results -Recurse -Force -ErrorAction SilentlyContinue | Out-Null}
New-Item $Results -type directory -ErrorAction SilentlyContinue | Out-Null

Foreach ($Script in $Scripts){
    Write-Host -ForegroundColor Yellow "`tRunning " $Script.Name
    [gc]::collect()
    try {$ScriptResults = Invoke-Expression $Script.FullName -ErrorAction SilentlyContinue}
    catch {Write-Host -ForegroundColor Red "`tError in $Script"}

    # depending on Content we can strip properties from Format-List results with | Select-Object above
    If (!$csv){
        $ScriptResults | Out-File ($Results + "\" + $Script.BaseName + ".txt")
    }
    ElseIf ($csv){
        $delim = ","
        $ScriptResults | convertto-csv -NoTypeInformation | % { $_ -replace "`"$delim`"", "$delim"} | % { $_ -replace "^`"",""} | % { $_ -replace "`"$",""} | % { $_ -replace "`"$delim","$delim"}
        $ScriptResults | Out-File ($Results + "\" + $Script.BaseName + ".csv") -Encoding ascii
    }
}

# Remove null results for simple analysis
Foreach ($Item in (Get-ChildItem -Path $Results)){
    If ($Item.length -eq 0){Remove-Item -Path $Item.FullName -Force}
}

If (Get-ChildItem -Path $Results){
    Write-Host -ForegroundColor Yellow "`nListing valid results in LiveResponse collection:"
    Get-ChildItem -Path $Results | select-object LastWriteTimeUtc, Length, Name | Format-Table -AutoSize
}
Else {
    Write-Host -ForegroundColor Yellow "`nNo valid LiveResponse results"
}

Write-Host -ForegroundColor Cyan "`nLiveResponse script collection complete`n"
