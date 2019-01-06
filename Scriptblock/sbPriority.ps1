
$sbPriority = {
    $Process = Get-Process -Id $Pid
    $Process.PriorityClass = 'IDLE'
}
