#requires -Version 3
function Invoke-PKChefClient {
<#
.Synopsis
    Runs chef-client on a remote machine as a job using invoke-command

.DESCRIPTION
    Runs chef-client on a remote machine as a job using invoke-command
    Returns a PSObject for the job invocation results, as well as the job state(s)
    Accepts pipeline input
    Uses implicit or explicit credentials
    
.NOTES
    Name    : Function_Invoke-PKChefClient.ps1
    Version : 1.2.1
    Author  : Paula Kingsley
    History : 
                
        ** PLEASE KEEP $VERSION UP TO DATE IN COMMENT BLOCK **

        v1.0.0 - 2016-10-03 - Created script
        v1.1.0 - 2016-10-27 - Changed job invocation output at end to verbose, minor cosmetic changes
        v1.1.1 - 2017-03-21 - Minor cosmetic changes/standardization
            
    
.EXAMPLE
    PS C:\> Invoke-PKChefClient -ComputerName server-123,server-xyz -Verbose
    
        VERBOSE: PSBoundParameters: 
	
        Key                   Value                        
        ---                   -----                        
        ComputerName          {server-123}             
        Verbose               True                         
        Credential                                         
        SuppressConsoleOutput False                        
        PipelineInput         False                        
        ScriptName            Invoke-PKChefClient
        ScriptVersion         1.0.0                        

        Verify connectivity to target computer(s)
        VERBOSE: server-123
        VERBOSE: server-xyz
        Create remote job(s)
        VERBOSE: server-123
        VERBOSE: server-xyz

        VERBOSE: Job invocation status
        
        VERBOSE: 
        ComputerName  JobID Messages                         JobInvoked JobName                          
        ------------  ----- --------                         ---------- -------                          
        server-123    30    Operation completed successfully       True ChefClientRun_server-123_2016-10-16_13-33-54
        server-xyz    32    Operation completed successfully       True ChefClientRun_server_xyz_2016-10-16_13-33-54

        
        VERBOSE: Remote job list is below

        Id     Name            PSJobTypeName   State         HasMoreData     Location    Command                  
        --     ----            -------------   -----         -----------     --------    -------                  
        30     ChefClientRu... RemoteJob       Running       True            server-123  ...                      
        32     ChefClientRu... RemoteJob       Running       True            server-xyz  ...       

        <snip>
        Receive-Job 30 -Wait

#>

[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [parameter(
        Mandatory=$True,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        HelpMessage = "Name of target computer"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("NodeName","Hostname","Name","FQDN")]
    [string[]]$ComputerName,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Valid credentials on target computer"
    )]
    [ValidateNotNullOrEmpty()]
    [pscredential] $Credential,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Suppress non-verbose console output"
    )]
    [switch] $SuppressConsoleOutput

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "1.1.1"

    # Detect pipeline input
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("ComputerName")) -and (-not $ComputerName)
   
    If ($PipelineInput -eq $True) {
        # Flags so we don't keep repeating ourseves w/console output
        [switch]$PipelineMsg_Ping = $True
        [switch]$PipelineMsg_Job = $True
    }

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams| Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "SilentlyContinue"

    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $False
    }

    # For console output
    $BGColor = $Host.UI.RawUI.BackgroundColor

    # Output hashtable (return if job fails)
    $InitialValue = "Error"
    $OutputHT = @{
        ComputerName = $InitialValue
        JobInvoked   = $InitialValue
        JobName      = $InitialValue
        JobID        = $InitialValue
        Messages     = $InitialValue
    }
    $Select = "ComputerName","JobInvoked","JobName","JobID","Messages"

    $SB = [scriptblock]::Create('
        Try {
            Invoke-Expression -Command "chef-client" -ErrorAction Stop
        }
        Catch {
            $_.Exception.Message
        }  
    ')

    # Splat for Invoke-Command
    $Param_InvokeCommand = @{}
    $Param_InvokeCommand = @{
        ComputerName = ""
        ErrorAction  = "Stop"
        ScriptBlock  = $SB
        AsJob        = $True
        JobName      = ""
        Verbose      = $False
    }
    If ($CurrentParams.Credential) {
        $Param_InvokeCommand.Add("Credential",$Credential)
    }

    # Output
    $Results = @()
    $Jobs = @()

}

Process {
    
    # Foreground color
    $FGColor = "Yellow"

    # Just assign variable to current computername if not pinging
    If ($SkipConnectionTest.IsPresent) {
        $Target = $ComputerName
    }
    Else {

        # Ping computers
        $Total = $ComputerName.Count
        $Current = 0

        # Write output to console, but don't keep repeating it if using pipeline input
        $Msg = "Verify connectivity to target computer(s)"
        If ($PipelineInput -eq $False) {
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
            Else {Write-Verbose $Msg}                
        }
        Else {
            If ($PipelineMsg_Ping.IsPresent -eq $True) {
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}   
                $PipelineMsg_Ping = $False
            }
        }
        
        # For progress bar
        $Activity = "Test connection"

        # Ping computers and if they pass, add them to a new array
        $Target = @()
        Foreach ($Computer in ($computerName | Sort-Object)) {

            $Current ++
            Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 
            If (-not $PipelineInput) {Write-Verbose $Computer}

            $Msg = "Test connection"
            If ($PsCmdlet.ShouldProcess($Computer,$Msg)) {
                Try {
                    If ($Null = Test-Connection -ComputerName $computer -Quiet -Count 1 @StdParams) {$Target += $Computer}
                    Else {
                        $Msg = "Ping failure"
                        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg on '$Computer'")}
                        Else {Write-Verbose $Msg}

                        $Output = $OutputHT.Clone()
                        $Output.ComputerName = $Computer
                        $Output.Messages = $Msg
                        $Output.JobInvoked = $False
                        $Results += New-Object PSObject -Property $Output
                    }
                } 
                Catch {}
            }
            Else {
                $Msg = "Ping test cancelled by user"
                $Output = $OutputHT.Clone()
                $Output.ComputerName = $Computer
                $Output.Messages = $Msg
                $Output.JobInvoked = $False
                $Results += New-Object PSObject -Property $Output
            }
        }
        $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False
    }

    # If we have target computers
    If ($Target.Count -gt 0) {

        $Total = $Target.Count
        $Current = 0

        # Loop
        Foreach ($Computer in ($Target | Sort-Object)) {
            
            $Current ++

            $Output = $OutputHT.Clone()
            $Output.Computername = $Computer

            # Task
            $Msg = "Create remote job(s)"
            
            # For progress bar
            $Activity = $Msg

            # Write output to console, but don't keep repeating it if using pipeline input
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

            If (-not $PipelineInput) {Write-Verbose $Computer}
            Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 
            
            $Msg = "Create remote job to run chef-client"
            If ($PsCmdlet.ShouldProcess($Computer,$Msg)) {
            
                Try {
                    $JobName = "ChefClientRun_$Computer`_$((Get-Date -f yyyy-MM-yy_HH-mm-ss))"
                
                    $Param_InvokeCommand.ComputerName = $Computer
                    $Param_InvokeCommand.JobName = $JobName

                    $Job = Invoke-Command @Param_InvokeCommand
                    $Output.JobInvoked = $True
                    $Output.JobName = $JobName
                    $Output.JobID = $Job.ID
                    $Output.Messages = "Operation completed successfully"
                
                    $Jobs += (Get-Job $Job.ID)
                }

                Catch [exception] {
                    $Msg = "Can't create job"
                    $ErrorDetails = $_.Exception.Message
                    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")}
                    Else {Write-Verbose $Msg}
                
                    $Output.ComputerName = $ComputerName
                    $Output.JobInvoked = $False
                    $Output.Messages = "$Msg; $ErrorDetails"  
                }
            }
            Else {
                $Msg = "Job creation cancelled by user"
                $Output = $OutputHT.Clone()
                $Output.ComputerName = $Computer
                $Output.Messages = $Msg
                $Output.JobInvoked = $False
            }

            $Results += New-Object PSObject -Property $Output  

        } #end create jobs for each computer
        
        $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False

    } #end if target
   
} #end process

End {

    If ($Results.Count -gt 0) {
        $Msg = "Job invocation status"
        Write-Verbose "$Msg`n"
        Write-Verbose "$($Results| Format-Table -AutoSize | out-string )"
    }

    If ($FailedJobs.Count -gt 0) {
        $Msg = "Errors/cancellations"
        Write-Verbose $Msg
        Write-Output ($FailedJobs | Select $Select)
    }

    If ($Jobs.count -gt 0) {
        $Msg = "Remote job list is below"
        Write-Verbose $Msg
        Write-Output ($Jobs | Get-Job)
    }
    Else {
        $Msg = "Job execution failed"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg")}
        Else {Write-Verbose $Msg}
    }


}

} #end Function_Invoke-PKChefClient.ps1

