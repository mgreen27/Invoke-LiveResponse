
# $Logfile collection
Write-Host -ForegroundColor Yellow "`tCollecting `$LogFile"

$Out = "$Output\" + $env:systemdrive.TrimEnd(':')

If (! (Test-Path $Out)){
     New-Item ($Out) -type directory | Out-Null
}

try{Invoke-ForensicCopy -InFile "$env:systemdrive\`$LogFile" -OutFile ("$Out\`$LogFile")}
Catch{Write-Host "`tError: `$LogFile raw copy."} 
