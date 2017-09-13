#requires -Version 3.0

Function Get-PKChefClient {
<#
.Synopsis
    Looks for Chef-Client on a Windows server, using Invoke-Command as a job

.DESCRIPTION
    Looks for Chef-Client on a Windows server, using Invoke-Command as a job
    Returns a PSObject
    Accepts pipeline input
    Accepts ShouldProcess

.NOTES
    Name    : Function_Get-PKChefClient.ps1
    Version : 3.0.0
    Author  : Paula Kingsley
    History : 

        ** PLEASE KEEP $VERSION UP TO DATE IN COMMENT BLOCK **
        
        v1.0   - 2016-04-22 - Created script
        v1.1   - 2016-04-22 - Adding pipeline input, support for multiple computernames
        v1.2   - 2016-04-26 - Adding parameter to get Windows service as output
        v2.0.0 - 2016-10-07 - Renamed from Get-ChefInstall, changed from registry (failing) to WMI (working),
                              made job default setting, other improvements & standardizations
        v3.0.0 - 2016-10-11 - Renamed from Get-WindowsChefClient for consistency

.EXAMPLE
    PS C:\> Get-PKWindowsChefClient -ComputerName dms-fpdev-1 -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                    
        ---                   -----                                    
        ComputerName          {dms-fpdev-1}                            
        Verbose               True                                     
        Credential            System.Management.Automation.PSCredential
        CheckWindowsService   False                                    
        SkipConnectionTest    False                                    
        SuppressConsoleOutput False                                    
        PipelineInput         False                                    
        ScriptName            Get-PKWindowsChefClient                  
        ScriptVersion         2.0.0                                    

        Verify connectivity
        VERBOSE: dms-fpdev-1
        VERBOSE: Performing the operation "Ping computer" on target "dms-fpdev-1".
        Create jobs to look for chef-Client
        VERBOSE: dms-fpdev-1
        VERBOSE: Performing the operation "Create remote job to get-Chef-Client install status" on target "dms-fpdev-1".

        Running jobs

        Id Name                                      PSJobTypeName State   HasMoreData Location    Command                                           
        -- ----                                      ------------- -----   ----------- --------    -------                                           
        56 GetChefClient_dms-fpdev-12016-10-07_15-55 RemoteJob     Running True        dms-fpdev-1    ...                                            

        <please hold>

        PS C:\> Get-Job 56 | Receive-Job

        Computername   : DMS-FPDEV-1
        IsInstalled    : True
        DisplayName    : Chef Client v12.5.1
        DisplayVersion : 12.5.1.1
        InstallSource  : C:\Windows\Installer\12149.msi
        InstallDate    : 2016-10-06
        Messages       : Found Chef-Client installation
        PSComputerName : dms-fpdev-1
        RunspaceId     : 65415e5f-c328-4c57-a6d0-f0c4fd95377a

.EXAMPLE
     $Arr | Get-PKWindowsChefClient -Credential $Credential -CheckWindowsService -SkipConnectionTest -SuppressConsoleOutput

        Id Name                                      PSJobTypeName State   HasMoreData Location    Command                                                                                                                                                               
        -- ----                                      ------------- -----   ----------- --------    -------                                                                                                                                                               
        74 GetChefClient_dms-fpdev-12016-10-07_15-07 RemoteJob     Running True        dms-fpdev-1    ...                                                                                                                                                                
        76 GetChefClient_ops-wsus012016-10-07_15-07  RemoteJob     Running True        ops-wsus01     ...                                                                                                                                                                
        78 GetChefClient_foo2016-10-07_15-07         RemoteJob     Running True        foo            ...    
        
        <snip>



#>
[cmdletbinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "Low"
)]

Param(
    [parameter(
        Mandatory=$False,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Name of computer to search (default is local host); separate multiple names with commas"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("FQDN","HostName","VM")]
    [string[]]$ComputerName = $env:COMPUTERNAME,
    
    [parameter(
        Mandatory=$False,
        HelpMessage = "Valid credentials on target computer (default is passthrough of local credentials)"
    )]
    [ValidateNotNullOrEmpty()]
    [pscredential] $Credential = ([PSCredential]::Empty),
    
    [parameter(
        Mandatory=$False,
        HelpMessage = "Include Windows service status"
    )]
    [Switch] $CheckWindowsService,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Don't ping computer first"
    )]
    [Switch] $SkipConnectionTest,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Hide non-verbose console output"
    )]
    [Switch]$SuppressConsoleOutput
)

Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "3.0.0"

    # Detect pipeline input
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("ComputerName")) -and (-not $ComputerName)
    
    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference    = "Continue"

    # Generalpurpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose     = $False
    }

    # Variables/arrays
    $Select = "ComputerName","IsInstalled","DisplayName","DisplayVersion","InstallSource","InstallDate","Messages"
    
    # Create initial output object/hashtable
    $InitialValue = "Error"
    $OutputHT = @{
        Computername    = $InitialValue
        IsInstalled     = $InitialValue
        DisplayName     = $InitialValue
        DisplayVersion  = $InitialValue
        InstallSource   = $InitialValue
        InstallDate     = $InitialValue
        Messages        = $InitialValue
    }
    If ($IncludeServiceCheck.IsPresent) {
        $OutputHT.Add("IsWindowsService",$InitialValue)
        $OutputHT.Add("ServiceState",$InitialValue)
        $OutputHT.Add("ServiceStartMode",$InitialValue)
        $OutputHT.Add("ServiceDetails",$InitialValue)
        
        $Select = "ComputerName","IsInstalled","DisplayName","DisplayVersion","InstallSource","InstallDate","IsService","ServiceState","ServiceStartMode","ServiceDetails","Messages"
    }

    # Create string for remote scriptblock
    $ScriptblockStr = @'
   
    # Variables/arrays
    $Select = "ComputerName","IsInstalled","DisplayName","DisplayVersion","InstallSource","InstallDate","Messages"
    
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $True
    }

    
    [switch]$CheckWindowsService = $False

    $Messages = @()

    # Create initial output object/hashtable
    $InitialValue = "Error"
    $Output = New-Object PSObject -Property ([ordered] @{
        Computername     = $Env:ComputerName
        IsInstalled      = $InitialValue
        DisplayName      = $InitialValue
        DisplayVersion   = $InitialValue
        InstallSource    = $InitialValue
        InstallDate      = $InitialValue
        IsWindowsService = $InitialValue 
        ServiceState     = $InitialValue
        ServiceStartMode = $InitialValue
        ServiceDetails   = $InitialValue
        Messages         = $InitialValue
    })
    If ($CheckWindowsService.IsPresent) {
        $Select = "ComputerName","IsInstalled","DisplayName","DisplayVersion","InstallSource","InstallDate","IsService","ServiceState","ServiceStartMode","ServiceDetails","Messages"
    }

    $WMIFilter = "name LIKE `"Chef Client%`"" 
    $Param_GetInstall = @{}
    $Param_GetInstall = @{
        Filter      = $WMIFilter
        ClassName   = "Win32_Product"
        ErrorAction = "Stop"
        Verbose     = $False
    }

    $Props = @("Name","PathName","StartName","StartMode","State")
    $Param_GetService = @{}
    $Param_GetService = @{
        Filter      = "name LIKE '%chef-client%'"
        Properties  = $Props
        ClassName   = "win32_service"
        ErrorAction = "Stop"
        Verbose     = $False
    }

    Try {
         # Look for existing install
        If ($Install = Get-CIMInstance @Param_GetInstall) {
        
            $Output.IsInstalled     = $True
            $Output.DisplayName     = $Install.Name
            $Output.DisplayVersion  = $Install.Version
            $Output.InstallDate     = Get-Date ([datetime]::ParseExact($Install.InstallDate,'yyyyMMdd',$null)) -format yyyy-MM-dd
            $Output.InstallSource   = $Install.LocalPackage
        
            $Msg = "Found Chef-Client installation"
            $Messages += $Msg
        
            If ($IncludeServiceCheck.IsPresent) {
            
                Try {
                                                            
                    If ($Service = @(Get-CimInstance @Param_GetService | select $Props)) {
                        $Output.IsWindowsService = $True
                        $Output.ServiceState     = $Service.State
                        $Output.ServiceStartMode = $Service.Startmode
                        $Output.ServiceDetails   = @($Service.Name,$ServicePathName)
                        
                        $Msg = "Chef-Client service found"
                        $Messages += $Msg
                    }
                    Else {
                        $Output.IsWindowsService = $False
                        $Output.ServiceState     = $Output.ServiceStartMode = $Output.ServiceDetails = $Null
                        
                        $Msg = "Chef-Client service not found"
                        $Messages += $Msg
                    }
                }
                Catch {
                    $Msg = "Errpr checking for chef-client service`n$($_.Exception.Message)" 
                    $Messages += $Msg
                }

            } #end if checking for service 
        }     
        Else {
        
            $Output.IsInstalled = $False
            $Output.DisplayName = $Output.DisplayVersion = $Output.InstallSource = $Output.InstallDate = $Null    
            
            $Msg = "Chef-Client mpt fpimd"
            $Messages += $Msg
        }
    }
    Catch {
        $Msg = "Error looking for installation`n$($_.Exception.Message)"
        $Messages += $Msg
    }

    $Output.Messages = $Messages -join("`n")
    Write-Output $Output | Select $Select


'@                
    
    # Update with values
    Switch ($CheckWindowsService) {
        $True {$ScriptBlockStr = $ScriptBlockStr.Replace("##CHECKWINDOWSSERVICE##",'$True')}
        $False {$ScriptBlockStr = $ScriptBlockStr.Replace("##CHECKWINDOWSSERVICE##",'$False')}
    }
    #create scriptblock
    $ScriptBlock = [scriptblock]::Create($ScriptblockStr)

     # Create parameter splat
    $Param_InvokeCommand = @{}
    $Param_InvokeCommand = @{
        ComputerName   = ""
        Credential     = $Credential
        Authentication = "Negotiate"
        Scriptblock    = $ScriptBlock
        AsJob          = $True
        JobName        = ""
        ErrorAction    = "Stop"
        Verbose        = $False
    }
    
    If ($PipelineInput -eq $True) {
        # Flags so we don't keep repeating ourseves w/console output
        [switch]$PipelineMsg_Ping = $True
        [switch]$PipelineMsg_Job = $True
    }

    # For console output
    $BGColor = $Host.UI.RawUI.BackgroundColor  
    
    # Output
    $Target = @()
    $Jobs = @()     
    $Failed = @()

}
Process {


  # Foreground color
    

    # Just assign variable to current computername if not pinging
    If ($SkipConnectionTest.IsPresent) {
        $Target = $ComputerName
    }

    # Ping computers
    Else { 
        
        $Total = $ComputerName.Count
        $Current = 0

        # Write output to console, but don't keep repeating it if using pipeline input
        $Msg = "Verify connectivity"
        $FGColor = "Yellow"
        If ($PipelineInput -eq $False) {
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
            Else {Write-Verbose $Msg}                
        }
        Else {
            If ($PipelineMsg_Ping.IsPresent) {
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}   
                $PipelineMsg_Ping = $False
            }
        }
        
        # For progress bar
        $Msg = "Test connection"
        $Activity = $Msg

        # Ping computers and if they pass, add them to a new array
        Foreach ($Computer in ($computerName | Sort-Object)) {

            $Current ++

            $Output = $OutputHT.Clone()
            $Output.ComputerName = $ComputerName

            $Msg = $Computer
            Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 
            If (-not $PipelineInput) {Write-Verbose $Computer}
            
            $Msg = "Ping computer"

            If ($PSCmdlet.ShouldProcess($Computer,$Msg)) {
                Try {
                    
                    If ($Null = Test-Connection -ComputerName $Computer -Quiet -Count 1 -Verbose:$False -ErrorAction SilentlyContinue) {
                        $Target += $Computer
                        $Msg = "Ping succeeded"
                    }
                    Else {
                        $Msg = "Ping failed"
                        $Output = $OutputHT.Clone()
                        $Output.ComputerName = $Computer
                        $Output.Messages = $Msg
                        $Failed += New-Object PSObject -Property $Output
                    }
                } 
                Catch {
                    $Msg = "Ping error"
                    $Output.Messages = "$Msg`n$ErrorDetails"  
                    $Failed += New-Object PSObject -Property $Output 
                
                }
                $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False
            }
            Else {
                $Msg = "Ping test for $Computer cancelled by user"
                $FGColor = "Red"
                
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}   

                $Output = $OutputHT.Clone()
                $Output.ComputerName = $ComputerName
                $Output.Messages = "Ping failed"  
                $Failed += New-Object PSObject -Property $Output 
            }
        
        } #End for each computer

    } #end if pinging computers

    # If we have target computers
    If ($Target) {
        
        $Total = $Target.Count
        $Current = 0
        
        # Write output to console, but don't keep repeating it if using pipeline input
        $Msg = "Create jobs to look for chef-Client"
        $FGColor = "Yellow"
        If ($PipelineInput -eq $False) {
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
            Else {Write-Verbose $Msg}                
        }
        Else {
            If ($PipelineMsg_Job.IsPresent) {
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}   
                $PipelineMsg_Job = $False
            }
        }
        
        # For progress bar
        $Activity = $Msg
        
        # Loop through the array
        Foreach ($Computer in ($Target| Sort-Object)) {
            
            $Current ++
            If (-not $PipelineInput) {Write-Verbose $Computer}

            $Output = $OutputHT.Clone()
            $Output.ComputerName = $Computer

            $JobName = "GetChefClient_$Computer"+(get-date -f yyyy-MM-dd_HH-ss)

            Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 

            $Msg = "Create remote job to get-Chef-Client install status"

            If ($PsCmdlet.ShouldProcess($Computer,$Msg)) {
                
                Try {
                    $Param_InvokeCommand.ComputerName = $Computer
                    $Param_InvokeCommand.JobName = $JobName

                    $Jobs += Invoke-Command @Param_InvokeCommand
                }

                Catch {
                    $Msg = "Can't create job"
                    $ErrorDetails = $_.Exception.Message
                    
                    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")}
                    Else {Write-Verbose $Msg}
                    
                    $Msg = "Can't create job"
                    $ErrorDetails = $_.Exception.Message
                    $Output.Message = "$Msg`n$ErrorDetails"

                    # Return a new PSObject based on the error
                    $Failed += New-Object PSObject -Property $Output

                }
            }
            Else {
                $Msg = "Job invocation for $Computer cancelled by user"
                $Output.Messages = $Msg
                $Failed += New-Object PSObject -Property $Output  
            
            }
        } #end create jobs for each computer
        
        $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False

    } #end if target

}
End {

    If ($Failed.Count -gt 0) {
        $Msg = "Job failures"
        $FGColor = "Red"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`n$Msg")}
        Else {Write-Verbose $Msg}   

        Write-Output ($Failed | Select $Select)
    }

    If ($Jobs.Count -gt 0) {
        $Msg = "Running jobs"
        $FGColor = "Green"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`n$Msg")}
        Else {Write-Verbose $Msg}   

        ($Jobs | Get-Job) | FT -AutoSize
    } 
    
}

} #end Get-PKWindowsChefClient

