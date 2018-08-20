# scheduled tasks along with some formatting to remove bad entries after conversion to csv
schtasks /query /FO CSV /v | Get-Unique | ConvertFrom-Csv | Where-Object {$_.HostName -ne "HostName" -And $_.TaskName -ne "TaskName" -And $_.Author -ne "Author" -And $_.Comment -ne "Comment"}

