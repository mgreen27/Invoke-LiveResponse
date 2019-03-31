
$Date = $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)

if ([System.IO.path]::GetPathRoot($Map) -eq $Map ) { 
    $Output = $Map + $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd) + "Z_" + $env:computername 
}
Else { 
    $Output = $Map + "\" + $(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd) + "Z_" + $env:computername 
}

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

# Setting log location as Global and creating log
$Global:CollectionLog = "$Output\$(get-date ([DateTime]::UtcNow) -format yyyy-MM-dd)_collection.log"
Add-Content -Path $CollectionLog "TimeUTC,Action,Source,Destination,Sha256(Source)" -Encoding Ascii
