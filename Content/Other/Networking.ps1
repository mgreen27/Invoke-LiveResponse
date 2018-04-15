# Config hosts and networks file content
"#"*80
"#`n# Network Configuration - ipconfig, hosts and networks `n"
"#"*80
"`n"
"ipconfig /all"
ipconfig /all
"#"*80
"`n"

If (Get-Content $env:windir\system32\drivers\etc\hosts){
    "Get-Content $env:windir\system32\drivers\etc\hosts"
    "`n"
    Get-Content $env:windir\system32\drivers\etc\hosts
    "`n"
    "#"*80
}

If (Get-Content $env:windir\system32\drivers\etc\networks){
"`n"
    "Get-Content $env:windir\system32\drivers\etc\networks"
    "`n"
    Get-Content $env:windir\system32\drivers\etc\networks
    "#"*80
}

