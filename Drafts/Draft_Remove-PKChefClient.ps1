#requires -Version 3
Function Remove-GNWindowsChefClient {
<#
.SYNOPSIS
    Removes the Chef client from a remote Windows server

.DESCRIPTION
    Removes the Chef client from a remote Windows server using Invoke-Command
    and jobs
    Supports ShouldProcess
    Accepts pipeline input

.NOTES
    Filename  : Function_Remove-GNWindowsChefClient.ps1
    Version   : 1.0.0
    Author    : Paula Kingsley
    Created   : 2016-09-14
    History   : 
        
        ** PLEASE KEEP $VERSION UPDATED IN BEGIN BLOCK **

        v1.0.0 - 2016-09-14 - Created script

.EXAMPLE



#>
[CmdletBinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(

    [Parameter(
        Mandatory=$False,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true
    )]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName,

    [Parameter(
        Mandatory=$False
    )]
    [ValidateNotNullOrEmpty()]
    [pscredential] $Credential,

    [Parameter(
        Mandatory=$false,
        HelpMessage="Timeout in seconds to wait for job"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1,320)]
    [int] $Timeout = 90,

#    [Parameter(
#        Mandatory=$false,
#        HelpMessage="Don't ping computer(s) before running job"
#    )]
#    [Switch] $SkipConnectionTest,   

    [Parameter(
        Mandatory=$false,
        HelpMessage="Don't remove job when complete"
    )]
    [Switch] $KeepJob = $True,

    [Parameter(
        Mandatory   = $False,
        HelpMessage ="Suppress non-verbose console output"
    )]
    [switch] $SuppressConsoleOutput

)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "2.0.0"

    # Detect pipeline input
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("ComputerName")) -and (-not $ComputerName)

    # How did we get here
    $Source = $PsCmdlet.ParameterSetName

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
    $ProgressPreference = "SilentlyContinue"


    # Create arguments for invoke-command
    $Filter = "chef client"
    $Params_GetChef = @{
        Class       = "Win32_Product"
        Filter      = "Name LIKE '%$Filter%'"
        ErrorAction = "Stop"
    }
    
    # Create scriptblock for remote-comand
    $SB = [scriptblock]::Create('
        
        param($Params_GetChef)
                        
        $ErrorActionPreference = "Stop"
        $InitialValue = "Error"

        $Output = @{}
        $Output = @{
            ComputerName  = $Env:ComputerName
            ClientFound   = $InitialValue
            Name          = $InitialValue
            Version       = $InitialValue
            ClientRemoved = $InitialValue
            Messages      = $InitialValue
        }

        Try {
    
            # Find it
            $ChefClient = Get-WMIObject @Params_GetChef

            $Output.ClientFound = $True
            $Output.Name        = $ChefClient.Caption
            $Output.Version     = $ChefClient.Version

            # Not gonna use this now
            #$ClassKey = "IdentifyingNumber=`"$($ChefClient.IdentifyingNumber)`",Name=`"$($ChefClient.Name)`",version=`"$($ChefClient.Version)`""

            Try {
                # Remove it
                If ($ChefClient.Uninstall()) {
                    $Output.ClientRemoved = $True
                    $Output.Messages      = "Operation completed successfully"
                }
                Else {
                    $Output.ClientRemoved = $False
                    $Output.Messages      = "Operation failed"
                }
            }
            Catch {
                $Output.ClientRemoved = $False
                $Output.Messages      = $_.Exception.Message
            }
        }
        Catch {
            $Output.ClientRemoved = $False
            $Output.Messages      = $_.Exception.Message
        }

        New-Object PSObject -Property $Output | Select ComputerName,ClientFound,Name,Version,ClientRemoved,Messages

    ')
    
    #region Splats

    # Invoke-Command
    $Params_InvokeCommand = @{}
    $Params_InvokeCommand = @{
        #ComputerName = ""
        ErrorAction  = "Stop"
        ScriptBlock  = $SB
        ArgumentList = $Params_GetChef
        Verbose      = $False
    }
    If ($CurrentParams.Credential) {
        $Params_InvokeCommand.Add("Credential",$Credential)
    }

    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $False
    }
    
    # Write-Progress
    $Params_WriteProgress = @{}
    $Params_WriteProgress = @{
        Activity         =  "Get remote job status until completed or $Timeout-second timeout is reached"
        SecondsRemaining = ""
        PercentComplete  = ""
        CurrentOperation = "Working"
    }

    #endregion Splats

    #region Output

    # Output hashtable (return if job fails)
    $InitialValue = "Error"
    $OutputHT = @{}
    $OutputHT = @{
        ComputerName  = $Env:ComputerName
        ClientFound   = $InitialValue
        Name          = $InitialValue
        Version       = $InitialValue
        ClientRemoved = $InitialValue
        Messages      = $InitialValue
    }

    # Selection order
    $Select = "ComputerName","ClientFound","Name","Version","ClientRemoved","Messages" 

    # Arrays
    $Jobs = @()
    $JobResults = @()  

    #endregion Output

    # Console output color
    $BGColor = $Host.UI.RawUI.BackgroundColor

    # Make sure we aren't going to set off alarms
    $Msg = "`nType YES to confirm that you have already removed the computer(s) from Operations Chef/monitoring"
    [string]$Confirm = Read-Host $Msg 
    If ($Confirm -ne "YES") {
        $Msg = "`nERROR: Please remove '$ComputerName' from Operations Chef/monitoring before running this script!"
        $FGColor = "Red"
        $Host.UI.WriteLine($FGColor,$BGColor,$Msg)
        Break
    }

}

Process {

   # For progress bar
   $Activity = "Test connection"

   # Ping computers and if they pass, add them to a new array
   $Target = @()
   
   $Total = $ComputerName.Count
   $Current = 0

   Foreach ($Computer in ($computerName | Sort-Object)) {

       $Current ++
       Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 
       If (-not $PipelineInput) {Write-Verbose $Computer}
       Try {
           If ($Null = Test-Connection -ComputerName $computer -Quiet -Count 1 @StdParams) {$Target += $Computer}
           Else {
               $Msg = "Ping failure"
               If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg on '$Computer'")}
               Else {Write-Verbose $Msg}

               $Output = $OutputHT.Clone()
               $Output.ComputerName  = $Computer
               $OUtput.ClientRemoved = $False
               $Output.Messages      = $Msg
               $JobResults += New-Object PSObject -Property $Output
           }
       } 
       Catch {}
   }
   $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False
    
    
    # If we have target computers
    If ($Target) {
        
        $Total = $Target.Count
        $Current = 0
        
        # For console/confirm prompt
        $Msg = "Create remote job(s) to remove Chef-Client"

        # Write output to console, but don't keep repeating it if using pipeline input
        $FGColor = "Yellow"
        If ($PipelineInput -eq $False) {
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"$Msg`?")}
            Else {Write-Verbose $Msg}                
        }
        Else {
            If ($PipelineMsg_Job -eq $True) {
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"$Msg`?")}
                Else {Write-Verbose $Msg}   
                $PipelineMsg_Job = $False
            }
        }
        
        # For progress bar
        $Activity = $Msg
        
        # Loop through the array
        Foreach ($Computer in ($Target | Sort-Object)) {
            
            $Current ++
            $Msg = "Create remote job(s) to remove Chef-Client"
            $FGColor = "White"
            If ($PsCmdlet.ShouldProcess($Target,$Msg)) {
                
                If (-not $PipelineInput) {Write-Verbose $Computer}
                Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 

                Try {
                    $Params_InvokeCommand.ComputerName = $Computer
                    $Params_InvokeCommand.JobName = "ChefClient_$Computer_$((Get-Date -f yyyy-MM-yy_hh-mm-ss))"
                    $Jobs += Invoke-Command @Params_InvokeCommand
                }

                Catch {
                    $Msg = "Can't create job"
                    $ErrorDetails = $_.Exception.Message
                    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")}
                    Else {Write-Verbose $Msg}
                
                    $Output = $OutputHT.Clone()
                    $Output.ComputerName = $ComputerName
                    $Output.Messages     = "$Msg`n$ErrorDetails"  
                    $JobResults += New-Object PSObject -Property $Output  
                }
                $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False
            }
            Else {
                $Msg = "Operation cancelled by user"
                $FGColor = "Red"
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"$Msg`?")}
                Else {Write-Verbose $Msg} 
                
                $Output = $OutputHT.Clone()
                $Output.ComputerName  = $ComputerName
                $Output.ClientRemoved = $False
                $Output.Messages      = $Msg 
                $JobResults += New-Object PSObject -Property $Output
            }
        } #end create jobs for each computer

    } #end if target computers
    Else {
        $Msg = "Can't connect to computer(s)"
        $FGColor = "Red"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
        Else {Write-Verbose $Msg} 
    }


}
End {
        
    If ($Jobs.count -gt 0) {

        Try {
            $FGColor = "Yellow"
            $Msg = "Get remote job(s) until completed or $Timeout-second timeout is reached"
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
            Else {Write-Verbose $Msg}
    
            # Start the clock
            $Timespan = new-timespan -seconds $Timeout
            $SW = [diagnostics.stopwatch]::StartNew()
    
            While (($SW.elapsed -lt $Timespan) -and ($Null = $Jobs | Get-Job -IncludeChildJob @StdParams).state -contains "Running") {
            
                $Percent = [math]::min([math]::ceiling(($SW.Elapsed.Seconds / $Timeout) * 100),100)
                if ($sw.Elapsed.TotalSeconds -lt 5) {$SecondsRemaining = -1} 
                Else {$SecondsRemaining = $sw.Elapsed.TotalSeconds * (100 - $Percent)/$Percent}
        
                $Params_WriteProgress.SecondsRemaining = $SecondsRemaining
                $Params_WriteProgress.PercentComplete = $Percent
    
                Write-Progress @Params_WriteProgress
            
                $Null = $Jobs | Get-Job @StdParams
            } 
    
            $Null = Write-Progress -Activity $Params_WriteProgress.Activity -Completed -Verbose:$False -ErrorAction SilentlyContinue
        
            If ($SW.elapsed -eq $Timespan) {
                $Msg = "Job(s) did not complete within $Timeout-second timeout; please check manually"
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg")}
                Else {Write-Verbose $Msg}
                $Jobs
                Break
            }

            Else {
                $FGColor = "Yellow"
                $Msg = "Receive job results"
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}
    
                # Get the results for the completed jobs
                $JobResults += $Jobs |  Where-Object {$_.State -eq "Completed"} | Receive-Job| Select $Select
    
                # Add the failed jobs to the output
                Foreach ($Fail in ($Jobs | Where-Object {$_.State -eq "Failed"})) {
                    $Output = $OutputHT.Clone()
                    $Output.ComputerName  = $Fail.Location
                    $Output.ClientRemoved = $False
                    $Output.Messages      = $Fail.ChildJobs[0].JobStateInfo.Reason.Message
                    $JobResults += New-Object PSObject -Property $Output
                }
    
                # Remove the job(s)
                If (-not $KeepJob.IsPresent) {
                    $FGColor = "Yellow"
                    $Msg = "Remove job(s)"
                    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                    Else {Write-Verbose $Msg}
                    $Jobs | Remove-Job -Force -Verbose:$False -ErrorAction SilentlyContinue
                }
            }
    
        } #end get remote job

        Catch {
            $Msg = "Can't get job state/results"
            $ErrorDetails = $_.Exception.Message
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")}
            Else {Write-Verbose $Msg}   
        }
    } #end if job ran
    
    Else {
        $Msg = "Job execution failed"
        $ErrorDetails = $_.Exception.Message
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")}
        Else {Write-Verbose $Msg} 
    }

    If ($JobResults) {
        $FGColor = "Green"
        $Msg = "See job results below"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
        Else {Write-Verbose $Msg}
        Write-Output ($JobResults | Select $Select)
    }

} #end End

} # End Remove-GNWindowsChefClient

