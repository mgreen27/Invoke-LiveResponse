# Environment Variables
Get-ChildItem ENV: | format-table @{Expression={$_.Name};Label="$ENV:ComputerName ENV:Variable"}, Value -AutoSize -Wrap