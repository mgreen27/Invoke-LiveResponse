# Windows startup configuration

If (Get-Content $env:SystemDrive\autoexec.bat){
    "$env:SystemDrive\autoexec.bat"
    Get-Content $env:SystemDrive\autoexec.bat
    "`n`n`n"
}

If (Get-Content $env:SystemDrive\config.sys){
    "$env:SystemDrive\config.sys"
    Get-Content $env:SystemDrive\config.sys
    "`n`n`n"
} 

if (Get-Content $env:windir\win.ini){
    "$env:windir\win.ini"
    Get-Content $env:windir\win.ini
    "`n`n`n"
}

If (Get-Content $env:windir\system.ini){
    "$env:windir\system.ini"
    Get-Content $env:windir\system.ini
    "`n`n`n"
} 
