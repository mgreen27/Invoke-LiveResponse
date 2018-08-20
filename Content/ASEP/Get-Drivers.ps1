# Driver enumeration
$drivers = driverquery /v /FO csv | ConvertFrom-Csv

#"Test for dodgy looking drivers"
#$drivers | where-Object {$_.Path -match "^.*(user|temp).*?\\.*?\.(sys|exe)$"}

$drivers | select "Module Name",Path,Description | format-table -Wrap -Force

#output twice for analysis and detailed view
$drivers