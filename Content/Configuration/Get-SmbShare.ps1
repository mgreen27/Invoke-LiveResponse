# Get-SmbShare
# PS2+ check for command prior to attempting to run
If (Get-Command Get-SmbShare -ErrorAction SilentlyContinue) {
    Get-SmbShare | format-table -AutoSize -wrap
}