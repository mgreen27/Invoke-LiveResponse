
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
        $LogAction = "MemoryDump"
    }
    Catch{
        Write-Host -ForegroundColor Red "`tError: dMemoryDump."
        $LogAction = "Error: WinPMem not found"
    }
}
Else{
    Write-Host -ForegroundColor Red "`tError: WinPMem not found at path. See help for download details."
    $LogAction = "Error: WinPMem not found"
}

# Adding logging for custom items that do not use Copy-LiveResponse
If(Test-Path "$Output\memory.zip") { $ItemOut = "$Output\memory.zip" }
Add-Content -Path $CollectionLog "$(get-date ([DateTime]::UtcNow) -format yyyy-MM-ddZhh:mm:ss.ffff),$LogAction,Memory,$ItemOut," -Encoding Ascii
