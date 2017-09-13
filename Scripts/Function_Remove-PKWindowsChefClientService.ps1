#requires -Version 3.0
Function Remove-PKChefClientService {
<#
.Synopsis
    Looks for the chef-client service on a computer and prompts to remove it if found

.DESCRIPTION
    Looks for the chef-client service on a computer and prompts to remove it if found
    Accepts pipeline input
    Outputs array

.NOTES
    Name    : Function_Remove-PKChefClientService.ps1
    Version : 3.0.0
    Author  : Paula Kingsley
    History :
        v1.0.0 - 2016-05-05 - Created script
        v1.1.0 - 2016-05-12 - Added StopService() method if service is running
        v2.0.0 - 2016-09-14 - General updates/standardization from Remove-GNChefClientService
        v3.0.0 - 2016-10-11 - Renamed from Remove-ChefClientService for consistency

.EXAMPLE
    PS C:\> Remove-PKWindowsChefClientService -ComputerName computer1 -Verbose -Confirm
    # Looks for the chef-client service and prompts to remove it, if found

        VERBOSE: computer1
        VERBOSE: Service found
        VERBOSE: Remove service?
        VERBOSE: Stopped service
        VERBOSE: Service removed

        ComputerName   ServiceFound  ServiceRemoved  Messages                     
        ------------   ------------  --------------  --------                     
        computer1      True          True            Removed chef-client service

.EXAMPLE
    PS C:\> $Arr | Remove-PKWindowsChefClientService -Verbose -Confirm
    # Looks for the chef-client service and prompts to remove it, if found

        VERBOSE: lalala
        ERROR: Can't check for service on lalala 
        The RPC server is unavailable. (Exception from HRESULT: 0x800706BA)
        VERBOSE: computer2
        VERBOSE: Service found
        VERBOSE: Remove chef-client service?
        VERBOSE: Stopped service
        VERBOSE: Removed service
        VERBOSE: computer3
        VERBOSE: Service found
        VERBOSE: Remove chef-client service?
        VERBOSE: Operation canceled

        ComputerName  ServiceFound ServiceRemoved Messages                                                           
        ------------  ------------ -------------- --------                                                           
        lalala        Error        Error          The RPC server is unavailable. (Exception from HRESULT: 0x800706BA)
        computer2     True         True           Found and removed chef-client service                              
        computer3     True         False          Operation canceled              

#>

[Cmdletbinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        Mandatory  = $True,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        Position  = 0,
        HelpMessage = "Computer name(s)"
    )]
    [Alias("VM","VMName","FQDN","HostName","Node")]    
    [String[]]$ComputerName,

    [Parameter(
        Mandatory=$False,
        Position = 1,
        HelpMessage = "Valid credentials on target computer(s)"
    )]
    [ValidateNotNullOrEmpty()]
    [pscredential] $Credential = [System.Management.Automation.PSCredential]::Empty

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

    $Results = @()

    $GWMISplat = @{}
    $GWMISplat = @{
        ComputerName = ""
        Class       = "Win32_Service"
        Filter      = "Name='chef-client'"
        Credential  = $Credential
        ErrorAction = "Stop"
        Verbose     = $False    
    }

    # Output for service methods
    $WMISvcOutputTable = @{
        0 = "The request was accepted."
        1 = "The request is not supported."
        2 = "The user did not have the necessary access."
        3 = "The service cannot be stopped because other services that are running are dependent on it."
        4 = "The requested control code is not valid, or it is unacceptable to the service."
        5 = "The requested control code cannot be sent to the service because the state of the service (Win32_BaseService.State property) is equal to 0, 1, or 2."
        6 = "The service has not been started."
        7 = "The service did not respond to the start request in a timely fashion."
        8 = "Unknown failure when starting the service."
        9 = "The directory path to the service executable file was not found."
        10 = "The service is already running."
        11 = "The database to add a new service is locked."
        12 = "A dependency this service relies on has been removed from the system."
        13 = "The service failed to find the service needed from a dependent service."
        14 = "The service has been disabled from the system."
        15 = "The service does not have the correct authentication to run on the system."
        16 = "This service is being removed from the system."
        17 = "The service has no execution thread."
        18 = "The service has circular dependencies when it starts."
        19 = "A service is running under the same name."
        20 = "The service name has invalid characters."
        21 = "Invalid parameters have been passed to the service."
        22 = "The account under which this service runs is either invalid or lacks the permissions to run the service."
        23 = "The service exists in the database of services available from the system."
        24 = "The service is currently paused in the system."
    }

    # Template hashtable
    $InitialValue = "Error"
    $OutputHT = @{}
    $OutputHT = @{
        ComputerName   = $InitialValue
        ServiceFound   = $InitialValue
        ServiceRemoved = $InitialValue
        Messages       = $InitialValue
    }

}
Process {

    Foreach ($Computer in $ComputerName) {
        
        Write-Verbose "$Computer"

        $Out = $OutputHT.Clone()
        $Out.ComputerName = $Computer

        Try {
            $GWMISplat.ComputerName = $Computer
            If ($Service = Get-WmiObject @GWMISplat ) {
                $Out.ServiceFound = $True
                Write-Verbose "Service found"
                Write-Verbose "Remove chef-client service?"
                If ($pscmdlet.ShouldProcess($Computer,"Remove Chef-Client service")) {
                    If ($Service.State -eq "Running") {
                        Try {
                            $Null = $Service.StopService()
                            Write-Verbose "Stopped service"
                        }
                        Catch {
                            $Msg = "Service could not be stopped; $($WMISvcOutputTable.Item($Delete.ReturnValue -as [int]).tolower()) (error code $($Delete.ReturnValue))"
                            $ErrorDetails = $_.Exception.Message
                            $Host.UI.WriteErrorLine("ERROR: $Msg `n$ErrorDetails")
                        }
                    }
                    Try {
                        $Delete = $Service.Delete()

                        If ($Delete.ReturnValue -ne 0) {
                            $Out.ServiceRemoved = $False
                            $Msg = "Service could not be removed; $($WMISvcOutputTable.Item($Delete.ReturnValue -as [int]).tolower()) (error code $($Delete.ReturnValue))"
                            $ErrorDetails = $_.Exception.Message
                            $Out.Messages = $Msg
                            $Host.UI.WriteErrorLine("ERROR: $Msg `n$ErrorDetails")
                        }
                        Else {
                            $Out.ServiceRemoved = $True
                            $Out.Messages = "Found and removed chef-client service"
                            Write-Verbose "Removed service"
                        }
                    }
                    Catch {
                        $Out.ServiceRemoved = $False
                        $Msg = "Service could not be removed; $($WMISvcOutputTable.Item($Delete.ReturnValue -as [int]).tolower()) (error code $($Delete.ReturnValue))"
                        $ErrorDetails = $_.Exception.Message
                        $Out.Messages = $Msg
                        $Host.UI.WriteErrorLine("ERROR: $Msg `n$ErrorDetails")
                    }
                }
                Else {
                    $Msg = "Operation canceled"
                    Write-Verbose $Msg
                    $Out.ServiceRemoved = $False
                    $Out.Messages = $Msg
                }
            }
            Else {
                Write-Verbose "Service not found"
                $Out.ServiceFound = $False
                $Out.ServiceRemoved = $False
                $Out.Messages = "chef-client service not found"
            }
        }
        Catch {
            $Msg = "Can't check for service on $Computer"
            $ErrorDetails = $_.Exception.Message
            $Out.Messages = $ErrorDetails
            $Host.UI.WriteErrorLine("ERROR: $Msg `n$ErrorDetails")
        }
    
        $Results += New-Object PSObject -Property $Out
    }

}
End {

    Write-Output $Results  | Select ComputerName,ServiceFound,ServiceRemoved,Messages
}

} #end Remove-PKChefClientService


