# Grabs local Group members
# Powershell 5.1+

$Groups = Get-LocalGroup | Select Name

Foreach ($Group in $Groups){
    
    $Members = Get-LocalGroupMember -Group $Group.Name
    If($Members){
        "Members of `"" + $Group.Name + "`" localgroup"
        $Members | Select Name,SID,ObjectClass | Format-Table
        "`n`n`n"
        }
}