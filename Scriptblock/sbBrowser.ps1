
# User browser artefact collection
Write-Host -ForegroundColor Yellow "`tCollecting User Browser Artefacts"
                       
$Users = Get-ChildItem "$env:systemdrive\Users\" -Force | where-object {$_.PSIsContainer} | Where-object { $_.Name -ne "Public" -And $_.Name -ne "All Users" -And $_.Name -ne "Default" -And $_.Name -ne "Default User"} | select-object -ExpandProperty name

# From https://github.com/mark-hallman/plaso_filters/blob/master/filter_windows.txt
$ChromeFiles = @("Bookmarks", "Cookies", "Current Session", "Current Tabs", "Extension Rules", "Extension State", "Favicons", "History", "Last Session", "Last Tabs", "Preferences", "Shortcuts", "Top Sites", "Visited Links", "Web Data")

Foreach ($User in $Users) {
    ### Chrome ###
    # Determine if user has Chrome installed
    if ( Test-Path "$env:systemdrive\Users\$User\AppData\Local\Google\Chrome\User Data" ) {
        # Find all Chrome profile directories
        if ( (Test-Path variable:Triage) -and ($Triage -eq $True) ) {
            $ChromeProfiles = @("Default")
        } else {
            $ChromeProfiles = Get-ChildItem "$env:systemdrive\Users\$User\AppData\Local\Google\Chrome\User Data" -recurse -include "Google Profile.ico" -force | Select-Object -Property Directory | ForEach-Object { Split-Path $_.Directory -Leaf }
        }
        
        # Collect Chrome artefacts
        foreach ($ChromeProfile in $ChromeProfiles ) {
            $ChromeUserFiles = @()
            $ChromeProfilePath = "$env:systemdrive\Users\$User\AppData\Local\Google\Chrome\User Data\$ChromeProfile"
            $Destination = "$Output\User\$user\Chrome\$ChromeProfile"
            if ( ( Test-Path variable:Triage) -and ($Triage -eq $True) ) {
                Invoke-BulkCopy -folder $ChromeProfilePath -target $Destination -where "$_.Name -match `"(Bookmarks|History|Preferences)`""
            } else {
                $ExtensionMessages = Get-ChildItem -recurse $ChromeProfilePath -include "messages.json" -force | Select-Object -property FullName | Where-Object FullName -match ".*\\_locales\\en.*\\messages.json"
                $ExtensionManifests = Get-ChildItem -recurse $ChromeProfilePath -include "manifest.json" -force | Select-Object -property FullName

                foreach ($rawfilename in $ExtensionMessages + $ExtensionManifests) {
                    # removes path up to Extensions folder to place at same level as other $ChromeFiles members
                    $ChromeUserFiles += $rawfilename.FullName -replace "\w:.+(?=Extensions)", ""
                }
                New-Item $Destination -type directory -force > $null
                foreach ($file in $ChromeFiles + $ChromeUserFiles) {
                    if ( $file.split("\")[0] -eq "Extensions") {
                        New-Item "$Destination\$file" -type file -force > $null
                    }
                    Try {
                        Copy-Item -Path "$ChromeProfilePath\$file" -Destination "$Destination\$file" -recurse -force
                    } Catch [System.IO.IOException] {
                        # Acquire user-locked files
                        Invoke-BulkCopy -folder "$ChromeProfilePath\$file" -target "$Destination\$file" -recurse -forensic
                    }
                }
            }
        }
    }
}
