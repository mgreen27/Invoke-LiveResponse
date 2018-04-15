<#
.SYNOPSIS
	Invoke-BitsParser.ps1 parses BITS jobs from QMGR queue.

    Name: Invoke-BitsParser.ps1
    Version: 0.3
    Author: Matt Green (@mgreen27)

.DESCRIPTION
    Invoke-BitsParser.ps1 parses BITS jobs from QMGR files.
    QMGR files are named qmgr0.dat or qmgr1.dat and located in the folder %ALLUSERSPROFILE%\Microsoft\Network\Downloader.
    Capable to run in live mode or against precollected files.

.PARAMETER Path
	Use this parameter to run against a previously collected QMgr file.

.EXAMPLE
	Invoke-BitsParser.ps1

    Run Invoke-BitsParser in live mode.

.EXAMPLE
	Invoke-BitsParser.ps1 -Path c:\cases\bits\qmgr0.dat

    Run Invoke-BitsParser in offline mode

.EXAMPLE
	Invoke-BitsParser.ps1 -verbose

    Run Invoke-BitsParser in verbose mode.

.NOTES
    Initial Python parser used as inspiration by ANSSI here - https://github.com/ANSSI-FR/bits_parser
    Invoke-BitsParser currently does not carve incomplete Jobs.

    FileHeader (32): 13-F7-2B-C8-40-99-12-4A-9F-1A-3A-AE-BD-89-4E-EA
    QueueHeader (32): 47-44-5F-00-A9-BD-BA-44-98-51-C4-7B-B6-C0-7A-CE
    Header (64): 13-F7-2B-C8-40-99-12-4A-9F-1A-3A-AE-BD-89-4E-EA-47-44-5F-00-A9-BD-BA-44-98-51-C4-7B-B6-C0-7A-CE
    XferHeader (32): 36-DA-56-77-6F-51-5A-43-AC-AC-44-A2-48-FF-F3-4D
    XferDelimiter (8): 03-00-00-00

    Job Delimiter (32)
        1: 93-36-20-35-A0-0C-10-4A-84-F3-B1-7E-7B-49-9C-D7
        2: 10-13-70-C8-36-53-B3-41-83-E5-81-55-7F-36-1B-87
        3: 8C-93-EA-64-03-0F-68-40-B4-6F-F9-7F-E5-1D-4D-CD
        4: B3-46-ED-3D-3B-10-F9-44-BC-2F-E8-37-8B-D3-19-86
#>

[CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)][String]$Path="$env:ALLUSERSPROFILE\Microsoft\Network\Downloader",
        [Parameter(Mandatory = $False)][Switch]$LiveMode = $True

)

    # Set switches
    $Verbose = $PSBoundParameters.ContainsKey("Verbose")
    If ($PSBoundParameters.ContainsKey("Path")){$LiveMode = $False}

    # Test for Elevated privilege if required
    If ($Path -eq "$env:ALLUSERSPROFILE\Microsoft\Network\Downloader"){
        If (!(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))){
            Write-Host -ForegroundColor Red "Exiting Invoke-BitsParser: Elevated privilege required for LiveResponse Mode"
            exit
        }
    }

    # Determine files in scope
    if(Test-Path $Path -pathType container){
        $QmgrFiles = (Get-ChildItem $Path -Filter qmgr*.dat).FullName
    }
    ElseIf(Test-Path $Path -pathType Leaf){
        $QmgrFiles = $Path
    }


   ## Regex setup
    # Chunk value for Memory optimised regex increment. Keep >= 2500
    $Chunk = 2500

    If ($Chunk -lt 2500){
        Write-Host -ForegroundColor Red "Exiting Invoke-BitsParser: Regex `$Chunk of $Chunk is too low!"
        exit
    }
    
    $Header = "13F72BC84099124A9F1A3AAEBD894EEA47445F00A9BDBA449851C47BB6C07ACE"
    $XferHeader = "36DA56776F515A43ACAC44A248FFF34D"
    

    # Job Delimiter lookup
    $JobDelimiterList = @(
        "93362035A00C104A84F3B17E7B499CD7",
        "101370C83653B34183E581557F361B87",
        "8C93EA64030F6840B46FF97FE51D4DCD",
        "B346ED3D3B10F944BC2FE8378BD31986"
    )


    # Job Control lookups
    $JobTypes = ("download","upload","upload_reply")
    
    $JobPriority = ("foreground","high","normal","low")
    
    $JobState = ("queued","connecting", "transferring","suspended","error","transient_error","transferred","acknowleged","cancelled")

    $JobFlags = ("NULL","BG_NOTIFY_JOB_TRANSFERRED","BG_NOTIFY_JOB_ERROR","BG_NOTIFY_JOB_TRANSFERRED_BG_NOTIFY_JOB_ERROR",
        "BG_NOTIFY_DISABLE","BG_NOTIFY_JOB_TRANSFERRED_BG_NOTIFY_DISABLE","BG_NOTIFY_JOB_ERROR_BG_NOTIFY_DISABLE",
        "BG_NOTIFY_JOB_TRANSFERRED_BG_NOTIFY_JOB_ERROR_BG_NOTIFY_DISABLE","BG_NOTIFY_JOB_MODIFICATION","NULL","NULL","WU Default","NULL",
        "NULL","NULL","NULL","BG_NOTIFY_FILE_TRANSFERRED")


   ## Main

    ForEach($Path in $QmgrFiles){

        # Resetting Hex stream, variables and results for each QMgrFile
        $Hex = $null
        $Position = $null
        $Output = @{}

        If ($Verbose){Write-Host -ForegroundColor Cyan "Parsing $Path"}

        # Adding QmanagerFile to a Hex Array
        $FileStream = New-Object System.IO.FileStream -ArgumentList ($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
	    $BinaryReader = New-Object System.IO.BinaryReader $FileStream
        $Hex = [System.BitConverter]::ToString($BinaryReader.ReadBytes($FileStream.Length)) -replace "-",""

        # Dispose FileStreams
        $FileStream.Dispose()
        $BinaryReader.Dispose()
        [gc]::Collect()


        # Finding Headerbytes different position accross some Windows versions using memory optimised regex
        $HeaderHit=$null
        $a = 0
        $b = $Chunk
        $Length = $hex.Length

        #$HeaderHit = [regex]::Match($Hex,$Header)
        While ($a -lt $Length -and !($HeaderHit)) {
            $HeaderHit = [regex]::Match($Hex[$a..$b]-join"",$Header)
            [gc]::Collect()
            # Add Chunk and allow for usecase of match end of previous block
            $a = $a + $Chunk -63
            $b = $b + $Chunk -63
        }
        
        If (!$HeaderHit){
            Write-Host -ForegroundColor Cyan "No BITS QueueManager header found."
            Break
        }

        $Position = $HeaderHit.Index + $HeaderHit.Length


        # Calculating number of jobs from 2 job bytes (with Endian black magic)
        $Jobs=$null
        $Jobs = $Hex[$Position..($Position + 7)]
        $Jobs = $Jobs[6..7] + $Jobs[4..5] + $Jobs[2..3] + $Jobs[0..1]
        
        Try{$JobsDetected = [convert]::toint32($Jobs -join "",16)}
        Catch{$JobsDetected = "ERROR in"} 
        
        $Position = $Position + 8

        If ($Verbose){Write-Host -ForegroundColor Cyan "$JobsDetected Jobs Detected"}


        # Determining Job delimiter
        $JobDelimiter = $Null
        $Match = $Null
        $JobDelimiter = $Hex[$Position..($Position + 31)] -join ""
        [gc]::Collect()

        Foreach($Item in $JobDelimiterList){
            if ($Item -eq $JobDelimiter){
                $Match = $true
                If ($Verbose){Write-Host -ForegroundColor Cyan "Job Delimiter is $JobDelimiter`n"}
            }
        }

        if (!$Match){
            Write-Host -ForegroundColor Cyan "Could not find Job Delimiter."
            break
        }
        

        For($Job = 0; $Job -lt $JobsDetected; $Job++){

            # Confirming JobDelimiter next 4 bytes and bumping to next JobDelimiter if required
            If($Job -eq 0){
                $Position = $Position + 32
            }
            Else{
                # Finding $JobDelimiterResults using memory optimised regex
                $JobDelimiterResults = $Null
                $a = $Position
                $b = $Position + $Chunk

                While ($a -lt $Length -and $JobDelimiterResults.count -lt 2){
                    [gc]::Collect()
                    $JobDelimiterResults = $JobDelimiterResults + [regex]::Matches(($Hex[$a..$b] -join ""),$JobDelimiter)
                    # JobDelimiter minus 1 to allow for usecase of match end of previous block
                    $a = $a + $Chunk -31
                    $b = $b + $Chunk -31
                    if ($JobDelimiterResults.count -eq 2){break}
                }
                [gc]::Collect()

                $Position = $Position + $JobDelimiterResults[1].Index + $JobDelimiterResults[1].Length
                
                # Cleaning up
                $JobDelimiterResults = $Null
            }


            # Job Type from 2 job bytes (with Endian black magic)
            $Type = $null
            $Type = $Hex[$Position..($Position + 7)] -join ""
            $Type = $Type[6..7] + $Type[4..5] + $Type[2..3] + $Type[0..1]
            
            Try{$Type = [convert]::toint32($Type -join "",16)}
            Catch{$Type = $Null}
            
            $Position = $Position + 8
       

            # Job priority from 2 priority bytes (with Endian black magic)
            $Priority = $null
            $Priority = $Hex[$Position..($Position + 7)] -join ""
            $Priority = $Priority[6..7] + $Priority[4..5] + $Priority[2..3] + $Priority[0..1]
            
            Try{$Priority = [convert]::toint32($Priority -join "",16)}
            Catch{$Priority = $Null}
            
            $Position = $Position + 8


            # Job state from 2 state bytes (with Endian black magic)
            $State = $null
            $State = $Hex[$Position..($Position + 7)] -join ""
            $State = $State[6..7] + $State[4..5] + $State[2..3] + $State[0..1]
            
            Try{$State = [convert]::toint32($State -join "",16)}
            Catch{$State = $Null}
            
            $Position = $Position + 8 


            # Dropping 2 additional bytes
            $Position = $Position + 8


            # Job GUID 1 (with Endian black magic )
            $Guid = $Null
            $Guid = $Hex[$Position..($Position + 31)] -join ""        
            
            $Guid = $Guid.substring(6,2) + $Guid.substring(4,2) + $Guid.substring(2,2) + $Guid.substring(0,2) + "-"`
                        + $Guid.substring(10,2) + $Guid.substring(8,2) + "-" + $Guid.substring(14,2) + $Guid.substring(12,2)`
                        + "-" + $Guid.substring(16,4) + "-" + $Guid.substring(20,12)
            
            $Position = $Position + 32


            # Job NameLength from 2 bytes (with Endian black magic)
            $NameLength = $Null
            $NameLength = $Hex[$Position..($Position + 7)] -join ""
            $NameLength = $NameLength[6..7] + $NameLength[4..5] + $NameLength[2..3] + $NameLength[0..1]
            
            Try{$NameLength = [convert]::toint32($NameLength -join "",16)}
            Catch{$NameLength = $Null}
            
            $Position = $Position + 8


            # Parsing each character from Name from 1 bytes x $NameLenth characters
            $Name = $Null
            
            For($Count = 0;$Count -lt ($NameLength -1);$Count++){
                    
                    Try{$Name = $Name + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint16($_,16))})}
                    Catch{Continue}

                    $Position = $Position + 4
            }
            
            $Position = $Position + 4


            # DescriptioneLength from 2 bytes (with Endian black magic)
            $DescriptionLength = $Null
            $DescriptionLength = $Hex[$Position..($Position + 7)] -join ""
            $DescriptionLength = $DescriptionLength[6..7] + $DescriptionLength[4..5] + $DescriptionLength[2..3] + $DescriptionLength[0..1]
            
            Try{$DescriptionLength = [convert]::toint32($DescriptionLength -join "",16)}
            Catch{$DescriptionLength = $Null}
            
            $Position = $Position + 8


            # Parsing each character from Descriptione from 1 bytes x $DescriptionLenth characters
            $Description = $Null
            
            For($Count = 0;$Count -lt ($DescriptionLength -1);$Count++){
                    
                    Try{$Description = $Description + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint16($_,16))})}
                    Catch{Continue}

                    $Position = $Position + 4
            }
            
            $Position = $Position + 4


            # CommandLineLength from 2 bytes (with Endian black magic)
            $CommandLineLength = $Null
            $CommandLineLength = $Hex[$Position..($Position + 7)] -join ""
            $CommandLineLength = $CommandLineLength[6..7] + $CommandLineLength[4..5] + $CommandLineLength[2..3] + $CommandLineLength[0..1]
            
            Try{$CommandLineLength = [convert]::toint32($CommandLineLength -join "",16)}
            Catch{$CommandLineLength = $null}
            
            $Position = $Position + 8


            # Parsing each character from CommandLine from 1 bytes x $CommandLineLenth characters
            $CommandLine = $Null
            
            For($Count = 0;$Count -lt ($CommandLineLength -1);$Count++){
                    
                    Try{$CommandLine = $CommandLine + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint16($_,16))})}
                    Catch{Continue}

                    $Position = $Position + 4
            }
            
            $Position = $Position + 4


            # CommandLineArgumentsLength from 2 bytes (with Endian black magic)
            $CommandLineArgumentsLength = $Null
            $CommandLineArgumentsLength = $Hex[$Position..($Position + 7)] -join ""
            $CommandLineArgumentsLength = $CommandLineArgumentsLength[6..7] + $CommandLineArgumentsLength[4..5] + $CommandLineArgumentsLength[2..3] + $CommandLineArgumentsLength[0..1]
            
            Try{$CommandLineArgumentsLength = [convert]::toint32($CommandLineArgumentsLength -join "",16)}
            Catch{$CommandLineArgumentsLength = $Null}
            
            $Position = $Position + 8

            # Parsing each character from CommandLineArguments from 1 bytes x $CommandLineArgumentsLenth characters
            $CommandLineArguments = $Null

            For($Count = 0;$Count -lt ($CommandLineArgumentsLength -1);$Count++){

                    Try{$CommandLineArguments = $CommandLineArguments + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint32($_,16))})}
                    Catch{continue}

                    $Position = $Position + 4
            }
            
            $Position = $Position + 4


            # SidLength from 2 bytes (with Endian black magic)
            $SidLength = $Null
            $SidLength = $Hex[$Position..($Position + 7)] -join ""
            $SidLength = $SidLength[6..7] + $SidLength[4..5] + $SidLength[2..3] + $SidLength[0..1]
            
            Try{$SidLength = [convert]::toint32($SidLength -join "",16)}
            Catch{$SidLength = $Null}
            
            $Position = $Position + 8


            # Parsing each character of SID from 1 bytes x $SidLenth characters
            $Sid = $Null
            
            For($Count = 0;$Count -lt ($SidLength -1);$Count++){
                    
                    Try{$Sid = $Sid + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint16($_,16))})}
                    Catch{continue}

                    $Position = $Position + 4
            }
            
            $Position = $Position + 4


            # Flag from 2 bytes (with Endian black magic)
            $Flag = $Null
            $Flag = $Hex[$Position..($Position + 7)] -join ""
            $Flag = $Flag[6..7] + $Flag[4..5] + $Flag[2..3] + $Flag[0..1]
            
            Try{$Flag = [convert]::toint32($Flag -join "",16)}
            Catch{$Flag=$Null}
            
            $Position = $Position + 8


            # Bumping forward to XferHeader using memory optimised regex
            $XferHeaderHit = $Null
            $a = $Position
            $b = $Position + $Chunk

            While ($a -lt $Hex.Length){
                [gc]::Collect()           
                $XferHeaderHit = [regex]::Match(($Hex[$a..$b] -join ""),$XferHeader)
                
                # Keeping position
                $Position = $a
                
                # Adding chunk minus xheader less 1
                $a = $a + $Chunk -31
                $b = $b + $Chunk -31

                If($XferHeaderHit){break}
            }
            [gc]::Collect()

            If($XferHeaderHit){
                # Needing to account for Regex starting from $Position previously
                $Position = $Position + $XferHeaderHit.index + $XferHeaderHit.length
            }
            Else{break} # We are done for that job


            # FilesCount in 1 byte (with Endian black magic)
            $FilesCount = $null
            $FilesCount = $Hex[$Position..($Position + 7)] -join ""
            $FilesCount = $FilesCount[6..7] + $FilesCount[4..5] + $FilesCount[2..3] + $FilesCount[0..1]
            
            Try{$FilesCount = [convert]::toint16($FilesCount -join "",16)}
            Catch{$FileCount = $null}
            
            $Position = $Position + 8

            

            # Some Bits versions will have Jobs with no filecount and requre carving. Jumping for now.
            If($FilesCount -gt 0){


                # DestLength in 2 bytes (With Endian black magic)
                $DestLength = $Null
                $DestLength = $Hex[$Position..($Position + 7)] -join ""
                $DestLength = $DestLength[6..7] + $DestLength[4..5] + $DestLength[2..3] + $DestLength[0..1]
                
                Try{$DestLength = [convert]::toint32($DestLength -join "",16)}
                Catch{$DestLength = $Null}
            
                $Position = $Position + 8


                # DestPath - Parsing each character of DestPath from 1 bytes x $DestPathLength characters
                $DestPath = $Null
            
                For($Count = 0;$Count -lt ($DestLength -1);$Count++){

                        Try{$DestPath = $DestPath + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint32($_,16))})}
                        Catch{Continue}

                        $Position = $Position + 4
                }
            
                $Position = $Position + 4


                # SourceLength in 2 bytes (With Endian black magic)
                $SourceLength = $Null
                $SourceLength = $Hex[$Position..($Position + 7)] -join ""
                $SourceLength = $SourceLength[6..7] + $SourceLength[4..5] + $SourceLength[2..3] + $SourceLength[0..1]
                
                Try{$SourceLength = [convert]::toint32($SourceLength -join "",16)}
                Catch{$SourceLength = $Null}
            
                $Position = $Position + 8


                # SourcePath - Parsing each character of SourcePath from 1 bytes x SourceLength characters
                $SourcePath = $Null
            
                For($Count = 0;$Count -lt ($SourceLength -1);$Count++){

                        Try{$SourcePath = $SourcePath + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint32($_,16))})}
                        Catch{Continue}

                        $Position = $Position + 4
                }
            
                $Position = $Position + 4


                # TempLength in 2 bytes (With Endian black magic)
                $TempLength = $Null
                $TempLength = $Hex[$Position..($Position + 7)] -join ""
                $TempLength = $TempLength[6..7] + $TempLength[4..5] + $TempLength[2..3] + $TempLength[0..1]
                
                Try{$TempLength = [convert]::toint16($TempLength -join "",16)}
                Catch{$TempLength = $Null}
            
                $Position = $Position + 8


                # TempPath - Parsing each character of TempPath from 1 bytes x $TempLength characters
                $TempPath = $Null
                For($Count = 0;$Count -lt ($TempLength -1);$Count++){
                        
                        Try{$TempPath = $TempPath + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint32($_,16))})}
                        Catch{Continue}

                        $Position = $Position + 4
                }
                $Position = $Position + 4


                # DownloadedBytes in 4 bytes (With Endian black magic)
                $DownloadedBytes = $Null
                $DownloadedBytes = $Hex[$Position..($Position + 15)] -join ""
                $DownloadedBytes = $DownloadedBytes[6..7] + $DownloadedBytes[4..5] + $DownloadedBytes[2..3] + $DownloadedBytes[0..1]
                
                Try{$DownloadedBytes = [convert]::toint32($DownloadedBytes -join "",16)}
                Catch{$DownloadedBytes = $null}
            
                $Position = $Position + 16


                # TotalBytes in 4 bytes (With Endian black magic)
                $TotalBytes = $Null
                $TotalBytes = $Hex[$Position..($Position + 15)] -join ""
                $TotalBytes = $TotalBytes[6..7] + $TotalBytes[4..5] + $TotalBytes[2..3] + $TotalBytes[0..1]
                
                Try{$TotalBytes = [convert]::toint32($TotalBytes -join "",16)}
                Catch{$TotalBytes = $Null}
            
                $Position = $Position + 16


                # Null half byte
                $Position = $Position + 2


                # DriveLength in 2 bytes (With endian black magic)
                $DriveLength = $Null
                $DriveLength = $Hex[$Position..($Position + 7)] -join ""
                $DriveLength = $DriveLength[6..7] + $DriveLength[4..5] + $DriveLength[2..3] + $DriveLength[0..1]
                
                Try{$DriveLength = [convert]::toint32($DriveLength -join "",16)}
                Catch{$DriveLength = $Null}
            
                $Position = $Position + 8


                # Drive path by parsing each character from each byte x $DriveLength characters
                $Drive = $Null
                For($Count = 0;$Count -lt ($DriveLength -1);$Count++){
                        
                        Try{$Drive = $Drive + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint32($_,16))})}
                        Catch{$Drive = $Null}

                        $Position = $Position + 4
                }
                $Position = $Position + 4


                # VolumeLength in 2 bytes (With endian black magic)
                $VolumeLength = $Null
                $VolumeLength = $Hex[$Position..($Position + 7)] -join ""
                $VolumeLength = $VolumeLength[6..7] + $VolumeLength[4..5] + $VolumeLength[2..3] + $VolumeLength[0..1]
                
                Try{$VolumeLength = [convert]::toint32($VolumeLength -join "",16)}
                Catch{$VolumeLength = $Null}

                $Position = $Position + 8

            
                # Volume by parsing each character from each byte x $VolumeLength characters
                $Volume = $Null
                For($Count = 0;$Count -lt ($VolumeLength -1);$Count++){

                        Try{$Volume = $Volume + ($Hex[$Position..($Position + 3)] -join "" -replace "00","" | forEach {[char]([convert]::toint32($_,16))})}
                        Catch{$Volume = $Null}

                        $Position = $Position + 4
                }
                $Position = $Position + 4


                # Jumping over next XferHeader footer and then some
                # If this is not a static number I will need to search for floating $XferHeader = [regex] "36DA56776F515A43ACAC44A248FFF34D"
                $Position = $Position + 194


                # MinRetryDelay in 2 bytes (With endian black magic)
                $MinRetryDelay = $Null
                $MinRetryDelay = $Hex[$Position..($Position + 7)] -join ""
                $MinRetryDelay = $MinRetryDelay[6..7] + $MinRetryDelay[4..5] + $MinRetryDelay[2..3] + $MinRetryDelay[0..1]
                
                Try{$MinRetryDelay = [convert]::toint32($MinRetryDelay -join "",16)}
                Catch{$MinRetryDelay = $Null}
                
                $Position = $Position + 8


                # NoProgressTimeout in 2 bytes (With endian black magic)
                $NoProgressTimeout = $Null
                $NoProgressTimeout = $Hex[$Position..($Position + 7)] -join ""
                $NoProgressTimeout = $NoProgressTimeout[6..7] + $NoProgressTimeout[4..5] + $NoProgressTimeout[2..3] + $NoProgressTimeout[0..1]
                
                Try{$NoProgressTimeout = [convert]::toint32($NoProgressTimeout -join "",16)}
                Catch{$NoProgressTimeout = $Null}
            
                $Position = $Position + 8


                # CreationTime in 2 bytes (With endian black magic)
                $CreationTime = $Null
                $CreationTime = $Hex[$Position..($Position + 15)] -join ""
                $CreationTime = $CreationTime[14..15] + $CreationTime[12..13] + $CreationTime[10..11] + $CreationTime[8..9] + $CreationTime[6..7] + $CreationTime[4..5] + $CreationTime[2..3] + $CreationTime[0..1]
            
                Try{$CreationTime = ([datetime]::FromFileTime([Convert]::ToInt64($CreationTime -join "",16))).ToString("s")}
                Catch{$CreationTime = "N/A"}
            
                $Position = $Position + 16
            

                # ModificationTime in 2 bytes (With endian black magic)
                $ModificationTime = $Null
                $ModificationTime = $Hex[$Position..($Position + 15)] -join ""
                $ModificationTime = $ModificationTime[14..15] + $ModificationTime[12..13] + $ModificationTime[10..11] + $ModificationTime[8..9] + $ModificationTime[6..7] + $ModificationTime[4..5] + $ModificationTime[2..3] + $ModificationTime[0..1]
            
                Try{$ModificationTime = ([datetime]::FromFileTime([Convert]::ToInt64($ModificationTime -join "",16))).ToString("s")}
                Catch{$ModificationTime = "N/A"}
            
                $Position = $Position + 16  
        

                # OtherTime1 in 2 bytes (With endian black magic)
                $OtherTime1 = $Null
                $OtherTime1 = $Hex[$Position..($Position + 15)] -join ""
                $OtherTime1 = $OtherTime1[14..15] + $OtherTime1[12..13] + $OtherTime1[10..11] + $OtherTime1[8..9] + $OtherTime1[6..7] + $OtherTime1[4..5] + $OtherTime1[2..3] + $OtherTime1[0..1]
            
                Try{$OtherTime1 = ([datetime]::FromFileTime([Convert]::ToInt64($OtherTime1 -join "",16))).ToString("s")}
                Catch{$OtherTime1 = "N/A"}
            
                $Position = $Position + 16        


                # Jump 7 unknown bytes
                $Position = $Position + 28


                # OtherTime2 in 2 bytes (With endian black magic)
                $OtherTime2 = $Null
                $OtherTime2 = $Hex[$Position..($Position + 15)] -join ""
                $OtherTime2 = $OtherTime2[14..15] + $OtherTime2[12..13] + $OtherTime2[10..11] + $OtherTime2[8..9] + $OtherTime2[6..7] + $OtherTime2[4..5] + $OtherTime2[2..3] + $OtherTime2[0..1]

                Try{$OtherTime2 = ([datetime]::FromFileTime([Convert]::ToInt64($OtherTime1 -join "",16))).ToString("s")}
                Catch{$OtherTime2 = "N/A"}

                $Position = $Position + 16  


                # ExpirationTime in 2 bytes (With endian black magic)
                $ExpirationTime = $Null
                $ExpirationTime = $Hex[$Position..($Position + 15)] -join ""
                $ExpirationTime = $ExpirationTime[14..15] + $ExpirationTime[12..13] + $ExpirationTime[10..11] + $ExpirationTime[8..9] + $ExpirationTime[6..7] + $ExpirationTime[4..5] + $ExpirationTime[2..3] + $ExpirationTime[0..1]
            
                Try{$ExpirationTime = ([datetime]::FromFileTime([Convert]::ToInt64($ExpirationTime -join "",16))).ToString("s")}
                Catch{$ExpirationTime = "N/A"}

                $Position = $Position + 16 

            }
            Else{
                # Setting skipped variables to Null for results.
                $SourcePath = $null
                $DestPath = $null
                $TempPath = $null
                $MinRetryDelay = $null
                $NoProgressTimeout = $null
                $CreationTime = $null
                $ModificationTime = $null
                $OtherTime1 = $null
                $OtherTime2 = $null
                $ExpirationTime = $null
                
            }

            
            # Display Results     
            $Output = [ordered] @{
                "Data File" = $Path
                "Job Guid" = $Guid
                "Job Name" = $Name
                Description = $Description
                Type = $JobTypes[$Type]
                Priority = $JobPriority[$Priority]
                JobState = $JobState[$State]
                CommandLine = $CommandLine
                Arguments = $CommandLineArguments
                SID = $Sid
                Flags = $JobFlags[$Flag]
                Files = $FilesCount
                Source = $SourcePath
                "Temp Path" = $TempPath
                Destination = $DestPath
                "Downloaded Bytes" = $DownloadedBytes
                "Total Bytes" = $TotalBytes
                Drive = $Drive
                Volume = $Volume
                "Minimun Retry Delay" = $MinRetryDelay
                "No Progress Timeout" = $NoProgressTimeout
                "Creation Time" = $CreationTime
                "Modification Time" = $ModificationTime
                "Other time 1" = $OtherTime1
                "Other time 2" = $OtherTime2
                "Expiration Time" = $ExpirationTime
            }

            $Output
            "`n"
            [gc]::Collect()
        }
    }