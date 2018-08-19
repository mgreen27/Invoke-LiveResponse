# Interesting detection
# Background: Most PE files in System32 are hard links to the real file under \Windows\WinSxS\. This query finds files that do not match that pattern and is an easy win for detection in a common staging location.
# Source: Twitter - Microsoft DFIR

Get-ChildItem c:\windows\system32 -filter *.exe | %{ $a = $_.fullname; fsutil hardlink list $_.fullname | measure | ?{ $_.count -eq 1 } | %{ get-authenticodesignature $a | select IsOSBinary,Status,StatusMessage,Path,SignerCertificate | format-List }}
