
Write-Host -ForegroundColor Yellow "`tCollecting Test"
                    

Invoke-BulkCopy -folder "$env:systemdrive\test" -target "$Output\test" -recurse -where "$_.Name -like '*.ps1'"

Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\winevt\Logs" -target "$Output\Evtx" -filter "Security.evtx"


Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\CONfig" -target "$Output\Reg" -filter "SOFTWARE"

Invoke-BulkCopy -folder "$env:systemdrive\Windows\System32\CONfig" -target "$Output\Reg" -filter "SAM"