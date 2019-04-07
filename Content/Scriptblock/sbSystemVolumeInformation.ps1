
# System Volume Information folder
Write-Host -ForegroundColor Yellow "`tCollecting System Volume Information"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

Copy-LiveResponse -path "$env:systemdrive\System Volume Information" -dest "$Out\System Volume Information"
