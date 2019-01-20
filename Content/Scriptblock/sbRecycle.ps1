
# RecycleBin
Write-Host -ForegroundColor Yellow "`tCollecting RecycleBin Artefacts"

$Drives = [System.IO.DriveInfo]::getdrives() | Where-Object {$_.DriveType -eq 'Fixed'} | Select-Object -Property Name

foreach ( $Drive in $Drives ) {
    $target = $Drive.Name.trimend(":\")

    Invoke-BulkCopy -path "$Drive\`$Recycle.Bin" -dest "$Output\$Target\Recycle.Bin" -recurse -Exclude desktop.ini
}
