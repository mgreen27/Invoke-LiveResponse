<#
.SYNOPSIS
    Get-DNSCache.ps1 acquires DNS cache entries from the target host.

    Taken from Kansa
#>

# Convert function from https://xaegr.wordpress.com/2007/01/24/decoder/
# If you try to use old cmd commands such as net, schtask etc.
# and remote OS is other than English you will ran into problem
# with gibberish encoding output with no easy fix
# This is the ONLY way i was able to find to fix this
# Example:
# ipconfig | ConvertTo-Encoding cp866 windows-1251
# Function expect a string, pass Out-String before if needed.
function ConvertTo-Encoding ([string]$From, [string]$To){  
        Begin{  
            $encFrom = [System.Text.Encoding]::GetEncoding($from)  
            $encTo = [System.Text.Encoding]::GetEncoding($to)  
        }  
        Process{  
            $bytes = $encTo.GetBytes($_)  
            $bytes = [System.Text.Encoding]::Convert($encFrom, $encTo, $bytes)  
            $encTo.GetString($bytes)  
        }  
    }  


$DNSCache = If (Get-Command Get-DnsClientCache -ErrorAction SilentlyContinue) {
    Get-DnsClientCache | Select-Object TimeToLIve, Caption, Description, 
        ElementName, InstanceId, Data, DataLength, Entry, Name, Section, 
        Status, Type
}

$DNSCache | sort name | Format-Table Name,Entry,Data,DataLength,TimeToLive,Section,status,ElementName,instanceid,description,caption -AutoSize -Wrap

<# From what I've seen root\standardcimv2 is not available on older Windows OSes so below is not
# a good substitute for ipconfig /displaydns

    Get-WmiObject -query "Select * from MSFT_DNSClientCache" -Namespace "root\standardcimv2" | Select-Object TimeToLive,
        PSComputerName, Caption, Description, ElementName, InstanceId, Data, 
        DataLength, Entry, Name, Section, Status, Type
#>