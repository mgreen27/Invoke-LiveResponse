# Get WMI Event Filter to COnsumer Bindings
ForEach ($NameSpace in "root\subscription","root\default"){Get-WmiObject -Namespace $NameSpace -Query "select * from __FilterToConsumerBinding" -ErrorAction SilentlyContinue}
