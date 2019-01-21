
# Memory dump winpmem find latest version in folder
$ToolFolder = ((get-item $Output).parent).fullname.trimEnd("\")
$MemDumpTool = $(Get-ChildItem -Path $ToolFolder -Filter "winpmem*"| Sort-Object PSChildName -Descending)

If ($MemDumpTool.count -gt 1) { $MemDumpTool = $ToolFolder + "\" + $MemDumpTool[0] }
Else { $MemDumpTool = $ToolFolder + "\" + $MemDumpTool }

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
    Write-Host -ForegroundColor Red "`tError: $MemDumpTool not found at path. See help for download details."
}
