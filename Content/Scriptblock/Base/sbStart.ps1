
# Set CPU prioirty
$Process = Get-Process -Id $Pid
$Process.PriorityClass = 'IDLE'

# Check for Administrator privilages
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")

if (!$isAdmin) {
    Write-Host -ForegroundColor Cyan "`nInvoke-LiveResponse`n"
    Write-Host -ForegroundColor Red "`tInsufficent Privilage: " -NoNewline
    Write-Host -ForegroundColor White "Invoke-LiveResponse requires run as Administrator`n"
    break
}
