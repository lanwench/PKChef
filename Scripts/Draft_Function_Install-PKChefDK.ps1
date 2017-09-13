#requires -Version 3
Function Install-PKChefDK {
<#
.Synopsis
    Downloads and installs the latest stable version of the ChefDK using the Omnitruck link

.Description
    Downloads and installs the latest stable version of the ChefDK using the Omnitruck link
    Optional -Force will proceed even if existing installation exists
    Runs as a remote background job
    Returns a PSJob
    Accepts pipeline input

.NOTES 
    Name    : Function_Install-PKChefDK.ps1
    Version : 02.00.0000
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00.0000 - 2017-02-09 - Created script
        v02.00.0000 - 2017-09-05 - Overhauled script
        
.LINK
    https://github.com/chef/chef-dk

.EXAMPLE
    PS C:\> Install-PKChefDK -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                     
        ---                   -----                     
        Verbose               True                      
        ComputerName          {MYWORKSTATION}         
        Credential                                      
        ForceInstall          False                     
        SuppressConsoleOutput False                     
        ScriptName            Install-PKChefDK
        ScriptVersion         2.0.0                     




        VERBOSE: MYWORKSTATION
        VERBOSE: Created job 41: ChefDK_MYWORKSTATION
        VERBOSE: 1 running job(s) created

        Id     Name            PSJobTypeName  State    HasMoreData  Location       Command                  
        --     ----            -------------  -----    -----------  --------       -------                  
        41     ChefDK_MYWOR... RemoteJob      Running  True         MYWORKSTATION  ...       

        PS C:\> Get-Job 41 | Wait-Job | Receive-Job

        ComputerName     : MYWORKSTATION
        DownloadURL      : https://omnitruck.chef.io/install.ps1
        PreviousInstall  : True
        PreviousVersion  : 2.0.28.1
        InstallCompleted : False
        InstallVersion   : 
        Messages         : Chef Development Kit v2.0.28 already installed, -Force not specified
        PSComputerName   : MYWORKSTATION
        RunspaceId       : d43067ec-400e-4c0e-b9c9-cb552bed2f01



.EXAMPLE
    PS C:\> Install-PKChefDK -ComputerName windev-14 -Verbose
        
        VERBOSE: PSBoundParameters: 
        Key                   Value                     
        ---                   -----                     
        ComputerName          {windev-14}            
        Verbose               True                      
        ForceInstall          False                      
        Credential                                      
        SuppressConsoleOutput False                     
        ScriptName            Install-PKChefDK
        ScriptVersion         2.0.0                     

        VERBOSE: windev-14
        VERBOSE: Created job 31: ChefDK_windev-14
        VERBOSE: 1 running job(s) created

        PS C:\> Get-Job 31 | Wait-Job | Receive-Job 

        ComputerName     : windev-14
        DownloadURL      : https://omnitruck.chef.io/install.ps1
        PreviousInstall  : False
        PreviousVersion  : 
        InstallCompleted : True
        InstallVersion   : 2.2.1.1
        Messages         : Installation completed successfully
        PSComputerName   : windev-14
        RunspaceId       : 55f23356-eec1-4cf3-9c6e-ed24f63987ce

.EXAMPLE
    PS C:\> $Arr | Install-PKChefDK -Verbose | Wait-Job | Receive-Job

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                     
        ---                   -----                     
        Verbose               True                      
        ComputerName                                    
        Credential                                      
        ForceInstall          False                     
        SuppressConsoleOutput False                     
        ScriptName            Install-PKChefDK
        ScriptVersion         2.0.0                     

        VERBOSE: webserver9
        VERBOSE: Created job 37: ChefDK_webserver9
        VERBOSE: workstation1
        VERBOSE: Created job 39: ChefDK_workstation1
        VERBOSE: 2 running job(s) created


        ComputerName     : webserver9
        DownloadURL      : https://omnitruck.chef.io/install.ps1
        PreviousInstall  : False
        PreviousVersion  : 
        InstallCompleted : True
        InstallVersion   : 2.2.1.1
        Messages         : Installation completed successfully
        PSComputerName   : webserver9
        RunspaceId       : 45d07ad3-5c63-4c16-92ba-339ac153dd52

        ComputerName     : workstation1
        DownloadURL      : https://omnitruck.chef.io/install.ps1
        PreviousInstall  : True
        PreviousVersion  : 2.2.1.1
        InstallCompleted : False
        InstallVersion   : 
        Messages         : Chef Development Kit v2.2.1 already installed, -Force not specified
        PSComputerName   : workstation1
        RunspaceId       : 67a15993-e6fe-497d-831e-b4990cf11242

#>

[CmdletBinding(    
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    
    [parameter(
        Mandatory=$False,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        HelpMessage = "Name of target computer"
    )]
    [ValidateNotNullOrEmpty()]
    [string[]]$ComputerName = $Env:ComputerName,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Admin credential on target computer"
    )]
    [ValidateNotNullOrEmpty()]
    [pscredential]$Credential,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Install even if current installation found"
    )]
    [Switch]$Force,

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Suppress all non-verbose console output"
    )]
    [Switch] $SuppressConsoleOutput 

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "02.00.0000"

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # For console output 
    $BGColor = $Host.UI.RawUI.BackgroundColor

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"

    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $False
    }
    
    $URI = "https://omnitruck.chef.io/install.ps1"
    $SB = [scriptblock]::Create('
            
        Param($URI,$Force,$StartTime)
        
        [switch]$OverWrite   = $Force
        $WMIFilter = "name LIKE `"Chef Development Kit%`"" 

        $StdParams = @{}
        $StdParams = @{
            ErrorAction = "Stop"
            Verbose = $False
        }
                
        [switch]$Continue = $True

        $InitialValue = "Error"
        $Output = New-Object PSObject -property ([ordered]@{
            ComputerName      = $Env:ComputerName
            DownloadURL       = $URI
            PreviousInstall   = $InitialValue
            PreviousVersion   = $InitialValue
            ForceSpecified    = $Overwrite
            InstallCompleted  = $InitialValue
            InstallVersion    = $InitialValue
            Messages          = $InitialValue
        })
      
        If ($Installed = Get-WmiObject -Class win32_product -Filter $WMIFilter @StdParams) {

            $Output.PreviousInstall = $True
            $Output.PreviousVersion = $Installed.Version

            If (-not ($OverWrite.IsPresent)) {
                $Msg = "$($Installed.Caption) already installed; -Force not specified"        
                $Output.InstallCompleted = $False
                $Output.InstallVersion = $Null
                $Output.Messages = $Msg
                $Continue = $False
            }
        }
        Else {
            $Output.PreviousInstall = $False
            $Output.PreviousVersion = $Null
        }
        
        If ($Continue.IsPresent) {
            
            Try {
                #. { Invoke-WebRequest -useb https://omnitruck.chef.io/install.ps1 } | Invoke-Expression; install -channel current -project chefdk
                #$RunInstall = Invoke-Command { { $Null = Invoke-WebRequest -useb $URI -EA SilentlyContinue } | Invoke-Expression -EA SilentlyContinue; install -channel current -project chefdk}
                
                $OmnitruckModule = (New-Module -Name OmniTruck -ScriptBlock { Invoke-WebRequest -useb $URI @StdParams | Invoke-Expression @StdParams} | Import-Module -PassThru @StdParams)

                Try {
                    $DoIt = Install-Project -channel current -project chefdk -ErrorAction Stop -Verbose
                    $Null = Get-Module Omnitruck -ErrorAction SilentlyContinue | Remove-Module -ErrorAction SilentlyContinue
                }
                Catch {
                    $Msg = "Installation failed"
                    $ErrorDetails = $_.Exception.Message
                    $Host.UI.WriteErrorLine("ERROR: $Msg;$ErrorDetails")
                }
                $EndTime = Get-Date
                $Finished = "$(($EndTime - $StartTime).Minutes)m, $(($EndTime - $StartTime).Seconds)s"
            }
            Catch {
                $Msg = "Installation failed after $Finished"    
                $ErrorDetails = $_.Exception.Message
                $Output.InstallCompleted = $False
                $Output.Messages = "$Msg`n$ErrorDetails"
            }
                
            If ($NewInstall = Get-WMIObject -Class win32_product -Filter $WMIFilter @StdParams) {
                
                If ($Installed.Version -and ($NewInstall.Version -gt $Installed.Version)) {
                    $Msg = "ChefDK upgraded successfully in $Finished"
                }
                If ($Installed.Version -and ($NewInstall.Version -eq $Installed.Version)) {
                    $Msg = "ChefDK not upgraded after $Finished"
                    $Output.InstallCompleted = $False
                }
                Else {$Msg = "ChefDK installed successfully in $Finished"}
                
                $Output.InstallCompleted = $True
                $Output.InstallVersion = $NewInstall.Version
                $Output.Messages = $Msg
            }
            Else {
                $Msg = "Installation failed after $Finished"
                $ErrorDetails = $_.Exception.Message
                $Output.InstallCompleted = $False
                $Output.Messages = "$Msg`n$ErrorDetails"
            }
        }                
        Write-Output $Output
            
    ')

    # Splat for Test-WSMAN (ping isn't enough)
    $Param_TestWSMAN = @{}
    $Param_TestWSMAN = @{
        ComputerName   = ""
        Authentication = "Negotiate"
        ErrorAction    = "SilentlyContinue"
        Verbose        = $False
    }

    # Splat for Invoke-Command
    $Param_InvokeCommand = @{}
    $Param_InvokeCommand = @{
        ComputerName = ""
        ErrorAction  = "Stop"
        ScriptBlock  = $SB
        ArgumentList = $Null
        AsJob        = $True
        JobName      = ""
        Verbose      = $False
    }
    If ($CurrentParams.Credential) {
        $Param_InvokeCommand.Add("Credential",$Credential)
    }

    $Activity = "Download and install ChefDK from $URI"

    # Splat for write-progress
    $Param_WP = @{}
    $Param_WP = @{
        Activity         =  $Activity
        PercentComplete  = ""
        CurrentOperation = "Working"
    }

    $Jobs = @()
    $Host.UI.WriteLine()
}
Process {
    
    $Total = $ComputerName.Count
    $Current = 0

    Foreach ($Computer in $ComputerName) {
        
        $Msg = $Computer
        Write-Verbose $Msg
        $Status = $ComputerName
        $Current ++
        
        $Param_WP.PercentComplete = ($Current / $Total * 100)
        Write-Progress @Param_WP

        If ($PSCmdlet.ShouldProcess($Computer,$Activity)) {
            
            $Param_TestWSMAN.ComputerName = $Computer
            
            If ($Null = Test-WSMan @Param_TestWSMAN) {
                
                $StartTime = Get-Date
                $ArgumentList = @($URI,$Force,$StartTime)
                $Jobname = "ChefDK_$Computer"
                $Param_InvokeCommand.ComputerName = $Computer
                $Param_InvokeCommand.JobName = $Jobname
                $Param_InvokeCommand.ArgumentList = $ArgumentList

                Try { 
                    $Job = Invoke-Command @Param_InvokeCommand
                    $Msg = "Created job $($Job.ID): $($Job.Name)"
                    Write-Verbose $Msg

                    $Jobs += $Job
                }
                Catch {
                    $Msg = "Job failed on '$Computer'"
                    $ErrorDetails = $($_.Exception.Message)
                    $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                }
            }
            Else {
                $Msg = "WinRM test failed on '$Computer'"
                $ErrorDetails = $($_.Exception.Message)
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
            }
        }
        Else {
            $Msg = "Operation cancelled by user on '$Computer'"
            Write-Warning $Msg
        }
    } #end foreach
}
End {

    Write-Progress -Activity $Activity -Completed
    If ($Jobs.count -gt 0) {
        $Msg = "$($Jobs.Count) running job(s) created"
        Write-Verbose $Msg
        Write-Output ($Jobs | Get-Job)
    }
    Else {
        $Msg = "No jobs were created"
        $Host.UI.WriteErrorLine("$Msg")
    }

}
} #End Install-PKChefDK


