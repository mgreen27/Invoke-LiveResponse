
# View collected files
Write-Host -ForegroundColor Yellow "`n`nListing first 10 items in collection:"
Get-ChildItem -Path $Output -Recurse -Force | select-object LastWriteTimeUtc, Length, FullName -First 10 | Format-Table -AutoSize
