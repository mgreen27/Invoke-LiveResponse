
# $MFT collection
Write-Host -ForegroundColor Yellow "`tCollecting `$MFT"
$Out = "$Output\" + $env:systemdrive.TrimEnd(':')
If (! (Test-Path $Out)){
     New-Item ($Out) -type directory | Out-Null
}

try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$MFT" -OutFile ("$Out\`$MFT")}
Catch{Write-Host "`tError: `$MFT raw copy."}
