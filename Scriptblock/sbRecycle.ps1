
# RecycleBin
Write-Host -ForegroundColor Yellow "`tCollecting RecycleBin Artefacts"

$Drives = [System.IO.DriveInfo]::getdrives() | Where-Object {$_.DriveType -eq 'Fixed'} | Select-Object -Property Name

foreach ( $Drive in $Drives ) {
    $target = $Drive.Name.trimend(":\")

    Invoke-BulkCopy -folder "$Drive\`$Recycle.Bin" -target "$Output\RecycleBin\$Target" -recurse -Forensic -Exclude desktop.ini
}
