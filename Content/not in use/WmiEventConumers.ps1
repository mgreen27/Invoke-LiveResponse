# Get WMI Event Consumers
ForEach ($NameSpace in "root\subscription","root\default"){Get-WmiObject -Namespace $NameSpace -Query "select * from __EventConsumer" -ErrorAction SilentlyContinue}
