# Verbose tasklit.exe output to table
& $env:windir\system32\tasklist.exe /v /fo csv  | ConvertFrom-Csv | format-table -AutoSize -wrap