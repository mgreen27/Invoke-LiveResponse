# Get WMI Event Consumers
$consumers=ForEach ($NameSpace in "root\subscription","root\default"){Get-WmiObject -Namespace $NameSpace -Query "select * from __EventConsumer" -ErrorAction SilentlyContinue}

# Get WMI Event Filters
$filters=ForEach ($NameSpace in "root\subscription","root\default"){Get-WmiObject -Namespace $NameSpace -Query "select * from __EventFilter" -ErrorAction SilentlyContinue}

# Get WMI Event Filter to COnsumer Bindings
$bindings=ForEach ($NameSpace in "root\subscription","root\default"){Get-WmiObject -Namespace $NameSpace -Query "select * from __FilterToConsumerBinding" -ErrorAction SilentlyContinue}

if($consumers){
    "`nWMI Event Consumers"
    $consumers
    "`n`n"+"#"*80
}

if($filters){
    "WMI Event Filters`n"
    $filters
    "`n`n"+"#"*80
}

if($bindings){
    "WMI Filter to Consumer Bindings"
    $bindings
    #"`n`n"+"#"*80
}