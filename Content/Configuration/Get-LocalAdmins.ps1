# Enumerate local Administrators and add to table

& net localgroup administrators | Select-Object -Skip 6 | ? {$_ -and $_ -notmatch "The command completed successfully" 
} | % {
    $o = "" | Select-Object Account
    $o.Account = $_
    $o
} | Format-Table @{Expression={$_.Account};Label="$ENV:ComputerName local administrators"}