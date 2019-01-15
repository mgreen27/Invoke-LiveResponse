
$Map = $((Get-Location).Path)
$Date = $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)
$Output = $Map + "\" + $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd) + "Z_" + $env:computername

If (Test-Path $Output -ErrorAction SilentlyContinue){
    Remove-Item $Output -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
}

Try{
    New-Item $Output -type directory -ErrorAction SilentlyContinue | Out-Null
}
Catch{
    If(Test-Path $Output -ErrorAction SilentlyContinue){
        Write-Host "Error: $Output already exists. Previously open on removal."
    }
}
