
# Unmount VSS
Get-childItem $env:temp | Where-Object { $_.Attributes -match "ReparsePoint" -and $_.Name -like "vss*" } | % { [System.IO.Directory]::Delete($_.FullName, $true) } | Out-Null
