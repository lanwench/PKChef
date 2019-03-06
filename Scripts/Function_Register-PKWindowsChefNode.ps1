#Requires -version 3
Function Register-PKWindowsChefNode {
<# 
.SYNOPSIS
    Registers a Windows computer as a chef node using an initial JSON file and client.rb file, using Invoke-Command to run a scriptblock (interactively or as a job)

.DESCRIPTION
    Registers a Windows computer as a chef node using an initial JSON file and client.rb file, using Invoke-Command to run a scriptblock (interactively or as a job)
    Accepts pipeline input
    Returns a PSobject or PSJob

.NOTES        
    Name    : Function_Register-PKWindowsChefNode.ps1
    Created : 2019-02-28
    Author  : Paula Kingsley
    Version : 01.00.0000
    History :

        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK **
        
        v01.00.0000 - 2018-10-22 - Created script to supersede New-PKWindowsChefClientConfig (not yet deprecated)

.PARAMETER ComputerName
    One or more computer names

.PARAMETER Credential
    Valid credentials on target (default is current user credentials)

.PARAMETER AsJob
    Invoke command as a PSjob

.PARAMETER ConnectionTest
    Run WinRM or ping connectivity test prior to Invoke-Command, or no test (default is WinRM)

.PARAMETER SuppressConsoleOutput
    Hide all non-verbose/non-error console output

.EXAMPLE
    PS C:\> Register-PKChefNode -ComputerName foo -Verbose

        
#> 

[CmdletBinding(
    DefaultParameterSetName = "__DefaultParameterSet",
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
[OutputType([Array])]
Param (
    [Parameter(
        Position = 0,
        Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        HelpMessage="One or more computer names"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("Computer","Name","HostName","FQDN")]
    [String[]] $ComputerName,

    [Parameter(
        Mandatory = $True,
        HelpMessage="Full URL to Chef server (e.g., 'https://chef.domain.local/organizations/ops')"
    )]
    [ValidateNotNullOrEmpty()]
    [String] $ChefServerURL,

    [Parameter(
        Mandatory = $True,
        HelpMessage="Valid environment on Chef server (default is '_default')"
    )]
    [ValidateNotNullOrEmpty()]
    [String] $Environment,

    [Parameter(
        Mandatory = $True,
        HelpMessage='Runlist/roles for initial JSON file (e.g., ''@("base-chef","base-baremetal","base-os","base-monitoring")'')'
    )]
    [Alias("Roles")]
    [ValidateNotNullOrEmpty()]
    [String[]] $Runlist,

    [Parameter(
        HelpMessage="Valid credentials on target"
    )]
    [ValidateNotNullOrEmpty()]
    [pscredential] $Credential = [System.Management.Automation.PSCredential]::Empty,

    [Parameter(
        ParameterSetName = "Job",
        HelpMessage = "Run Invoke-Command scriptblock as PSJob"
    )]
    [Switch] $AsJob,

    [Parameter(
        ParameterSetName = "Job",
        HelpMessage = "Prefix for job name (default is 'Chef')"
    )]
    [String] $JobPrefix = "Chef",

    [Parameter(
        HelpMessage="Test to run prior to Invoke-Command: WinRM, ping, or None (default is None)"
    )]
    [ValidateSet("WinRM","Ping","None")]
    [string] $ConnectionTest = "None",

    [Parameter(
        HelpMessage="Hide all non-verbose/non-error console output"
    )]
    [Switch] $SuppressConsoleOutput

)

Begin { 
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00.0000"

    # Show our settings
    $Source = $PSCmdlet.ParameterSetName
    [switch]$PipelineInput = (-not $PSBoundParameters.ContainsKey("ComputerName")) -and (-not $ComputerName)
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference    = "Continue"
    
    # Warning!
    $Msg = "This script assumes that:`n`n * chef-client is installed on the remote Windows computer`n * A valid key is present in c:\chef\validator.pem`n * Any environment specified is valid on the Chef server`n * The Chef server URL is valid`n`nIf all criteria are met, the script will create the first-boot.json and client.rb files to allow the target to register`n`with a Chef server. After the file creation, it will run chef-client once with the -j switch.`n`nAs this process can take some time, the command is best run as a PowerShell job using the -AsJob switch."
    Write-Warning $Msg

    # Output
    [array]$Results = @()
    
    #region Scriptblock for Invoke-Command

    $ScriptBlock = {

        Param($Environment,$ChefServerURL,$RunList,$ValidationKeyName)

        # Array for messages 
        $Messages = @()

        # Set flag
        [switch]$Continue = $False
        
        # Output object
        $Messages = @()
        $ConfigDate = (Get-Date)
        $FileDate = (Get-Date $ConfigDate).tostring("yyyy-MM-dd-HH-mm-ss")
        $Output = New-Object PSObject -Property @{
            ComputerName = $Env:ComputerName
            IsSuccess    = $False
            NodeName     = "Error"
            Environment  = $Environment
            Runlist      = $Runlist -join("`n")
            ChefServer   = $ChefServerURL
            Date         = $ConfigDate
            Messages     = "Error"
        }
        $Select = 'ComputerName','IsSuccess','NodeName','Environment','Runlist','ChefServer','Date','Messages'

        # File paths
        $File_Validator   = "c:\chef\validator.pem"
        $File_InitialJSON = "c:\chef\first-boot.json"
        $File_Clientrb    = "c:\chef\client.rb"
        $File_Environment = "c:\chef\production.txt"
        $File_ClientLog   = "c:\chef\first-boot_$($FileDate).log"
        $File_ConfigLog   = "c:\chef\ClientConfig_$($FileDate).log"
        $File_ClientKey   = "c:\chef\client.pem"
            
        # Look for key
        If ($Null = Test-Path $File_Validator -ErrorAction SilentlyContinue) {
            $Msg = "Verified path '$File_Validator'"
            $Messages += $Msg
            $Continue = $True
        }
        Else {
            $Msg = "Invalid path '$File_Validator'"
            $Output.IsSuccess = $False
            $Messages += $Msg
        }
            
        # Create the files and run chef-client with the initial JSON file & logging
        If ($Continue.IsPresent) {
            
            Try {
    
                # Get host's FQDN and force it to lower case
                $GWMI = Get-WmiObject -Class win32_computersystem -Property Name,Domain | Select Name,Domain
                $NodeName = "$($GWMI.Name.ToLower()).$($GWMI.Domain.ToLower())"
                $Output.NodeName = $NodeName

                # Get rid of any old files
                Foreach ($File in ($File_InitialJSON,$File_Clientrb,$File_Environment,$File_ClientLog,$File_ConfigLog | Where-Object {Test-Path $_ -ErrorAction SilentlyContinue})) {
                    $Null = Remove-Item $File -Force -ErrorAction Continue -Confirm:$False
                }

                ## Create first-boot.json
                $Content_InitialJSON = @{
                    "run_list" = $RunList
                }
                If (-not (Get-Item $File_InitialJSON -EA SilentlyContinue)) {
                    $Null = New-Item $File_InitialJSON -ItemType File -Force -EA Stop
                }
                #$Null = Set-Content -Path $File_InitialJSON -Value ($Content_InitialJSON | ConvertTo-Json -Depth 10) -Encoding UTF8 -EA Stop
                $Null = Set-Content -Path $File_InitialJSON -Value ($Content_InitialJSON | 
                    ConvertTo-Json -Depth 10 -ErrorAction Stop) -ErrorAction Stop                        

                $Msg = "Created '$File_InitialJSON'"
                $Messages += $Msg

                # If Production, set to Default, then drop a file in the c:\chef dir called 'Production' so the chef-client run
                # will move it to Production and append the location after node is registered
                If ($Environment -eq "Production") {
                    $ChefEnv = "_default"
                    $Null = "production" | Out-File -FilePath $File_Environment -EA Stop
                    $Messages += "Environment 'production' will be appended with location after initial run; created $File_Environment and reset initial environment to '_default'"
                }
                Else {$ChefEnv = $Environment}
                $Output.Environment = $ChefEnv
                    
                # Create client.rb from here-string
                $Content_Clientrb = @"
chef_server_url        '$ChefServerURL'
validation_client_name '$ValidationKeyName'
validation_key         '$File_Validator'
environment            '$ChefEnv'
node_name              '$NodeName'
"@
                    
                If (-not ($Null = Get-Item $File_Clientrb -EA SilentlyContinue)) {
                    $Null = New-Item $File_Clientrb -ItemType File -Force -EA Stop
                }
                $Null = Set-Content -Path $File_Clientrb -Value $Content_Clientrb -EA Stop
                $Msg = "Created '$File_ClientRB'"
                $Messages += $Msg

                # Update output object
                Try {
                    $Null = Invoke-Expression -Command "C:\opscode\chef\bin\chef-client.bat -j $File_InitialJSON -L $File_ClientLog" -EA Stop
                    $Msg = "Invoked 'C:\opscode\chef\bin\chef-client.bat -j $File_InitialJSON -L $File_ClientLog'"
                    $Messages += $Msg

                    If ($Null = Get-Item $File_ClientKey -ErrorAction SilentlyContinue) {
                        $Output.IsSuccess = $True
                        $Msg = "Confirmed file '$File_ClientKey' was created"
                        $Messages += $Msg
                    }
                    Else {
                        $Output.IsSuccess = $False
                        $Msg = "Failed to confirme file '$File_ClientKey' was created; please view $File_ClientLog"
                        $Messages += $Msg
                    }
                }
                Catch {
                    $Output.IsSuccess = $False
                    $Msg = $_.Exception.Message
                    $Messages += $Msg
                }
            }
            Catch {
                $Output.IsSuccess = $False
                $Msg = $_.Exception.Message
                $Messages += $Msg
            }
            
        } #end if continue

        $Output.Messages = $Messages -Join("`n")
        $Output | Select-Object $Select | Out-String -EA SilentlyContinue | Out-File -FilePath $File_ConfigLog -EA SilentlyContinue
        Write-Output $Output | Select-Object $Select

    } #end scriptblock

    #endregion Scriptblock for Invoke-Command

    #region Functions

    Function Test-WinRM{
        Param($Computer)
        $Param_WSMAN = @{
            ComputerName   = $Computer
            Credential     = $Credential
            Authentication = "Kerberos"
            ErrorAction    = "Silentlycontinue"
            Verbose        = $False
        }
        Try {
            If (Test-WSMan @Param_WSMAN) {$True}
            Else {$False}
        }
        Catch {$False}
    }

    Function Test-Ping{
        Param($Computer)
        $Task = (New-Object System.Net.NetworkInformation.Ping).SendPingAsync($Computer)
        If ($Task.Result.Status -eq "Success") {$True}
        Else {$False}
    }

    #endregion Functions

    #region Splats

    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose     = $False
    }

    # Splat for Write-Progress
    $Activity = "Invoke scriptblock to register a Windows server as a node in Chef"
    If ($AsJob.IsPresent) {
        $Activity = "$Activity (running as a remote PSJob)"
    }
    $Param_WP = @{}
    $Param_WP = @{
        Activity         = $Activity
        CurrentOperation = $Null
        Status           = "Working"
        PercentComplete  = $Null
    }

    # Parameters for Invoke-Command
    $ConfirmMsg = $Activity
    $Param_IC = @{}
    $Param_IC = @{
        ComputerName   = $Null
        Authentication = "Kerberos"
        ScriptBlock    = $ScriptBlock
        Credential     = $Credential
        ErrorAction    = "Stop"
        Verbose        = $False
    }
    If ($AsJob.IsPresent) {
        $Jobs = @()
        $Param_IC.Add("AsJob",$True)
        $Param_IC.Add("JobName",$Null)
    }
    
    #endregion Splats

    # Console output
    $BGColor = $host.UI.RawUI.BackgroundColor
    $Msg = "Action: $Activity"
    $FGColor = "Yellow"
    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"$Msg`n")}
    Else {Write-Verbose $Msg}


} #end begin

Process {

    # Counter for progress bar
    $Total = $ComputerName.Count
    $Current = 0

    Foreach ($Computer in $ComputerName) {
        
        $Computer = $Computer.Trim()
        $Current ++ 

        [int]$percentComplete = ($Current/$Total* 100)
        $Param_WP.PercentComplete = $PercentComplete
        $Param_WP.Status = $Computer
        
        [switch]$Continue = $False

        Switch ($ConnectionTest) {
            Default {$Continue = $True}
            Ping {
                If ($Computer -ne $env:COMPUTERNAME) {
                    $Msg = "Ping computer"
                    $Param_WP.CurrentOperation = $Msg
                    Write-Verbose "[$Computer] $Msg"
                    Write-Progress @Param_WP

                    If ($PSCmdlet.ShouldProcess($Computer,"`n$Msg`n")) {
                        If ($Null = Test-Ping -Computer $Computer) {$Continue = $True}
                        Else {
                            $Msg = "Ping failure"
                            $Host.UI.WriteErrorLine("[$Computer] $Msg")
                        }
                    }
                    Else {
                        $Msg = "Ping connection test cancelled by user"
                        $Host.UI.WriteErrorLine("[$Computer] $Msg")
                    }
                }
                Else {$Continue = $True}
            }
            WinRM {
                If ($Computer -ne $env:COMPUTERNAME) {
                    $Msg = "Test WinRM connection"
                    $Param_WP.CurrentOperation = $Msg
                    Write-Verbose "[$Computer] $Msg"
                    Write-Progress @Param_WP

                    If ($PSCmdlet.ShouldProcess($Computer,"`n$Msg`n")) {
                        If ($Null = Test-WinRM -Computer $Computer) {$Continue = $True}
                        Else {
                            $Msg = "WinRM failure"
                            $Host.UI.WriteErrorLine("[$Computer] $Msg")
                        }
                    }
                    Else {
                        $Msg = "WinRM connection test cancelled by user"
                        $Host.UI.WriteErrorLine("[$Computer] $Msg")
                    }
                }
                Else {$Continue = $True}
            }        
        }

        If ($Continue.IsPresent) {
            
            If ($PSCmdlet.ShouldProcess($Computer,$Activity)) {
                
                Try {
                    $Msg = "Invoke command"
                    If ($AsJob.IsPresent) {$Msg += " as PSJob"}
                    $Param_WP.CurrentOperation = $Msg
                    Write-Verbose "[$Computer] $Msg"
                    Write-Progress @Param_WP

                    $Param_IC.ComputerName = $Computer
                    If ($AsJob.IsPresent) {
                        $Job = $Null
                        $Param_IC.JobName = "$JobPrefix`_$Computer"
                        $Job = Invoke-Command @Param_IC 
                        $Jobs += $Job
                        $Job
                    }
                    Else {
                        Invoke-Command @Param_IC
                    }
                }
                Catch {
                    $Msg = "Operation failed"
                    If ($ErrorDetails = $_.Exception.Message) {$Msg += "; $ErrorDetails"}
                    $Host.UI.WriteErrorLine("[$Computer] $Msg")
                }
            }
            Else {
                $Msg = "Operation cancelled by user"
                $Host.UI.WriteErrorLine("[$Computer] $Msg")
            }
        
        } #end if proceeding with script
        
    } #end for each computer
        
}
End {
    
    $Null = Write-Progress -Activity $Activity -Completed

     If ($AsJob.IsPresent) {

        If ($Jobs.Count -gt 0) {
            $Msg = "$($Jobs.Count) job(s) created; run 'Get-Job -Id # | Wait-Job | Receive-Job' to view output"
            Write-Verbose $Msg
            $Jobs | Get-Job
        }
        Else {
            $Msg = "No jobs created"
            Write-Warning $Msg
        }
    } #end if AsJob

}

} # end Do-SomethingCool

