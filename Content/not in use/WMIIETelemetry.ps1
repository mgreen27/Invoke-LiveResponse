# Get IEUrl Info if availible
Get-WmiObject -Namespace 'root\cimv2\IETelemetry' -Class IEURLInfo -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap