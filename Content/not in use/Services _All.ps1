# Get Service information
Get-WmiObject win32_service | Select-Object Name, DisplayName, PathName, StartName, StartMode, State, TotalSessions, Description