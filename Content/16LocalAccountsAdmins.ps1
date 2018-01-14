# Local Account enumeration
"Local Accounts on $ENV:ComputerName"
Get-WmiObject -Class Win32_UserAccount -Namespace "root\cimv2" -ErrorAction SilentlyContinue | select Name,Domain,SID,Disabled,Status,LockOut | format-table -AutoSize -Wrap

& net localgroup administrators | Select-Object -Skip 6 | ? {$_ -and $_ -notmatch "The command completed successfully" 
} | % {
    $o = "" | Select-Object Account
    $o.Account = $_
    $o
} | Format-Table @{Expression={$_.Account};Label="Local admins"}