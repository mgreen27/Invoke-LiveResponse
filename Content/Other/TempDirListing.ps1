# Temp Directory Listing
foreach($userpath in (Get-WmiObject win32_userprofile | Select-Object -ExpandProperty localpath)) {
    if (Test-Path(($userpath + "\AppData\Local\Temp\"))) {
        Get-ChildItem -Force ($userpath + "\AppData\Local\Temp\*") | Select FullName, CreationTimeUtc, LastAccessTimeUtc, LastWriteTimeUtc
    }
}