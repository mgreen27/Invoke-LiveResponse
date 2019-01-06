
# RecycleBin
Write-Host -ForegroundColor Yellow "`tCollecting RecycleBin Artefacts"

$Drives = [System.IO.DriveInfo]::getdrives() | Where-Object {$_.DriveType -eq 'Fixed'} | Select-Object -Property Name

foreach ( $Drive in $Drives ) {
    Invoke-BulkCopy -folder "$Drive\`$Recycle.Bin" -target "$Output\RecycleBin\$($Drives.Name.trimend("\").trimend(":"))" -recurse -Forensic -Exclude desktop.ini
}
