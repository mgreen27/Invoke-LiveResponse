<#
.SYNOPSIS
	Invoke-BitsDetection.ps1 detects on anomalous BITS transfer URLs from Windows BITS Event log. 

    Name: Invoke-BitsDetection.ps1
    Version: 0.1
    Author: Matt Green (@mgreen27)

.DESCRIPTION
    Invoke-BitsDetection.ps1 extracts all BITS transfer URLs from Windows Event log.
    Microsoft-Windows-Bits-Client/Operational Event ID 59.
    
    Utilising a WHitelist of expected BITs domains, the goal of this script is to detect anomolous sources for BITs transfers that can lead to additional investigation.
    Use -All switch to list all URL sources and do not run Whitleist check.

    Please add new domains to whitelist.

.PARAMETER BackDays
    Optional parameter for specifying number of days to search back in Microsoft-Windows-Bits-Client/Operational Eventlog. Default is 14.

.PARAMETER All
    List all URLs and bypass whitelist comparison.

.EXAMPLE
	Invoke-BitsDetection.ps1

    Run Invoke-BitsDetection and alert on anomolous or new source urls.

.EXAMPLE
	Invoke-BitsDetection.ps1 -Backdays 7

    Run Invoke-BitsDetection back 7 days of event logs from current date.

.EXAMPLE
	Invoke-BitsDetection.ps1 -All

    Run Invoke-BitsDetection and show all URLs unfiltered.
.NOTES
    
#>
[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$False)][int32]$BackDays=14,
        [Parameter(Mandatory = $False)][Switch]$All = $False
)

    # Set whitelist
    $Whitelist = @(
        "http*://aka.ms/*",# Microsoft site
        "http*://img-prod-cms-rt-microsoft-com.akamaized.net/*",# Microsoft on Akamai
        "http*://img-s-msn-com.akamaized.net/*",# MSN on Akamai
        "http*://*.adobe.com/*",# adobe
        "http*://*.adobe.com/*",# adobe
        "http*://*.amazon.com/*",# Amazon corporate
        "http*://*.apache.org/*",# Apache
        "http*://*.avast.com/*",# Avast
        "http*://*.avcdn.net/*",# Avast cdn
        "http*://*.bing.com/*",# Microsoft Bing
        "http*://*.core.windows.net/*",# Microsoft site
        "http*://*.fbcdn.net/*",# Facebook cdn
        "http*://*.google.com/*",# Google
        "http*://*.googleapis.com/*",# Google api domain
        "http*://*.googleusercontent.com/*",# GoogleUsercontent
        "http*://*.gvt1.com/*"# Google chrome
        "http*://*.hp.com/*",# HP domain
        "http*://*.live.com/*",# Microsoft Live
        "http*://*.microsoft.com/*",# Microsoft site
        "http*://*.msn.com/*",# MSN
        "http*://*.nero.com/*",# Nero software
        "http*://*.office365.com/*",# Microsoft office 365
        "http*://*.onenote.net/*",# OneNote cdn
        "http*://*.oracle.com/*",# Oracle domain
        "http*://*.s-msn.com/*",# MSN
        "http*://*.symantec.com/*",# Symantec
        "http*://*.thomsonreuters.com/*",# News site
        "http*://*.visualstudio.com/*",# Microsoft VisualStudio
        "http*://*.windowsupdate.com/*",# Windows update
        "http*://*.xboxlive.com/*"# Microsoft site
    )

    $All = $PSBoundParameters.ContainsKey("All")
    
    $Results = $False
    $BackTime=(Get-Date) - (New-TimeSpan -Days $BackDays)

    $RawEvents = Get-WinEvent -LogName "Microsoft-Windows-Bits-Client/Operational" | Where-Object {$_.TimeCreated -ge $BackTime} | Where-Object { $_.Id -eq 59}

    
    $RawEvents | ForEach-Object { 

        If(!$All){
            Foreach ($Url in $Whitelist){
                If ($_.Properties[3].Value -like $Url ){return}
            }
        }
        
        $Results = $True
        
        $PropertyBag = [ordered] @{
            TimeUTC = Get-Date (($_.TimeCreated).ToUniversalTime()) -Format s
            TransferId = $_.Properties[0].Value
            Name = $_.Properties[1].Value
            Id = $_.Properties[2].Value
            URL = $_.Properties[3].Value
            FileTime = $_.Properties[5].Value
            FileLength = $_.Properties[6].Value
            BytesTotal = $_.Properties[7].Value
            BytesTransferred = $_.Properties[8].Value
        }

        $Output = New-Object -TypeName PSCustomObject -Property $PropertyBag

        # When modifying PropertyBag remember to change Seldect-Object for ordering below
        $Output | Select-Object TimeUTC,Name,URL
        [gc]::Collect()
    }

    If(!$Results){"Invoke-BitsDetecton: No anomolous BITS activity deteted."}