# Get WMI Event Filters
ForEach ($NameSpace in "root\subscription","root\default"){Get-WmiObject -Namespace $NameSpace -Query "select * from __EventFilter" -ErrorAction SilentlyContinue}
