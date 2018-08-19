# Get-SmbSession
# PS2+ check for command prior to attempting to run
if (Get-Command Get-SmbSession -ErrorAction SilentlyContinue){
    Get-SmbSession | format-table -AutoSize -wrap
}