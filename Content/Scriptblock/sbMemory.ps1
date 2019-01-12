
# Memory dump winpmem
$MemDumpTool = ((get-item $Output).parent.fullname).trimEnd("\") + "\winpmem-2.1.post4.exe"

If (Test-Path $MemDumpTool) {
    try{
        If(Test-Path $Output\memory.zip) {
            Remove-Item "$Output\memory.zip" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Host -ForegroundColor Yellow "`tCollecting Memory"
        cmd /c "$MemDumpTool --format raw -o $Output\memory.zip > null 2>&1"
    }
    Catch{
        Write-Host -ForegroundColor Red "`tError: dMemoryDump."
    }
}
Else{
    Write-Host -ForegroundColor Red "`tError: $MemDumpTool not found at UNC path. See help for download details."
}
