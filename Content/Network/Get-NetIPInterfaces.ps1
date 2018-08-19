# Get-NetIPInterface 
# PS2+ check for command prior to attempting to run

If (get-command Get-NetIPInterface -erroraction silentlycontinue){
    Get-NetIPInterface | format-table -AutoSize -wrap
}