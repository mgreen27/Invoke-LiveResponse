# Get-NetRoute 
# PS2+ check for command prior to attempting to run

If (get-command Get-NetRoute -erroraction silentlycontinue){Get-NetRoute | format-table -AutoSize -wrap}