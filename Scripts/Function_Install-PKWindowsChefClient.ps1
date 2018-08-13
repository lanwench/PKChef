#requires -Version 3
function Install-PKWindowsChefClient {
<#
.Synopsis
    Installs chef-client on a remote machine from a local or downloaded MSI file
    using Invoke-Command and a remote job

.DESCRIPTION
    Installs chef-client on a remote machine from a local or downloaded MSI file
    using Invoke-Command and a remote job
    Allows selection of local MSI on target or download (of various versions)
    Parameter -ForceInstall forces installation even if existing version is present
    Allows for standard or verbose logging from msiexec (stores log on target computer)
    Returns jobs
    

.NOTES
    Name    : Function_Install-PKWindowsChefClient.ps1
    Version : 3.03.0000
    Author  : Paula Kingsley
    History : 
                
        ** PLEASE KEEP $VERSION UP TO DATE IN COMMENT BLOCK **

        v1.00.0000 - 2016-09-15 - Created Install-WindowsChefClient from older Install-ChefClient
        v2.00.0000 - 2016-09-23 - Updates galore; renamed from Install-WindowsChefClient (to make invoke-command clear)
        v3.00.0000 - 2016-10-11 - Renamed from Install-WindowsChefClient for consistency
        v3.01.0000 - 2016-10-27 - Minor cosmetic updates
        v3.01.0001 - 2016-12-21 - Fixed examples (still used old name)
        v3.02.0001 - 2017-02-22 - Updated version options to default 12.18.31 
        v3.03.0000 - 2017-09-01 - Changed reference to artifactory, changed semantic versioning 
    
.EXAMPLE
    PS C:\> Install-PKWindowsChefClient -ComputerName server-123 -DownloadMSIFile -ClientVersion '12.5.1' -Verbose

    # Installs Chef-Client v12.5 on a remote computer, downloading from an internal Ops server

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                                                      
        ---                   -----                                                                      
        ComputerName          {server-123}                                                           
        DownloadMSIFile       True                                                                       
        ClientVersion         12.5.1                                                                     
        Verbose               True                                                                       
        ParameterSetName      DownloadFile                                                               
        PipelineInput         False                                                                      
        KeepDownloadFile      False                                                                      
        ForceInstall          False                                                                      
        LogfileDirectory      C:\WINDOWS\Temp                                                            
        Credential                                                                                       
        LogfileVerbose        False                                                                      
        SuppressConsoleOutput False                                                                      
        DownloadURL           http://ops-repo-1.internal.domain.com/chef/chef-client-12.5.1-1-x86.msi
        ScriptName            Install-PKWindowsChefClient                                                
        ScriptVersion         2.0.0                                                                      

        Verify connectivity to target computer(s)
        VERBOSE: server-123
        Create remote job(s)
        VERBOSE: server-123
        Remote job list is below

        Id     Name                  PSJobTypeName   State         HasMoreData     Location             Command                  
        --     ----                  -------------   -----         -----------     --------             -------                  
        63     ChefClientInstall_... RemoteJob       Running       True            server-123       ...     

        <wait some reasonable period of time>

        PS C:\>Get-Job 63 | Receive-Job -Keep

        ComputerName      : server-123
        Source            : DownloadFile
        ClientVersion     : 12.5.1
        DownloadURL       : http://ops-repo-1.internal.domain.com/chef/chef-client-12.5.1-1-x86.msi
        Filepath          : C:\Windows\Temp\20160925-091309_ChefClient.msi
        DownloadCompleted : True
        PreviousInstall   : False
        PreviousVersion   : (none)
        InstallCompleted  : True
        InstallVersion    : 12.5.1.1
        ExitCode          : 0
        Logfile           : C:\WINDOWS\Temp\ChefClientInstallLog_2016-09-25_09-13-22.txt
        Messages          : Exit code 0, ERROR_SUCCESS
        PSComputerName    : server-123
        RunspaceId        : c18d988d-bb0d-4926-a5b7-e3f2d9681598

.EXAMPLE
    PS C:\> Install-PKWindowsChefClient -ComputerName server-999 -LocalMSIFile -MSIFilePath c:\installers\chefclient.msi -LogfileDirectory c:\logs -LogfileVerbose -Credential $Cred -Verbose
        
        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                    
        ---                   -----                                    
        ComputerName          {server-999}                         
        LocalMSIFile          True                                     
        MSIFilePath           c:\installers\chefclient.msi           
        LogfileDirectory      c:\logs                                  
        LogfileVerbose        True                                     
        Credential            System.Management.Automation.PSCredential
        Verbose               True                                     
        DownloadMSIFile       False                                    
        PipelineInput         False                                    
        ParameterSetName      LocalFile                                
        ForceInstall          False                                    
        SuppressConsoleOutput False                                    
        ScriptName            Install-PKWindowsChefClient              
        ScriptVersion         2.0.0                                    

        Verify connectivity to target computer(s)
        VERBOSE: server-999
        Create remote job(s)
        VERBOSE: server-999
        Remote job list is below

        Id     Name                  PSJobTypeName   State         HasMoreData     Location            
        --     ----                  -------------   -----         -----------     --------            
        99     ChefClientInstall_... RemoteJob       Running       True            server-999             

        
        PS C:\Get-Job 99 | Receive-Job -Keep

        ComputerName     : server-999
        Source           : LocalFile
        Filepath         : c:\installers\chefclient.msi
        PreviousInstall  : False
        PreviousVersion  : (none)
        InstallCompleted : True
        InstallVersion   : 12.5.1.1
        ExitCode         : 0
        Logfile          : c:\logs\ChefClientInstallLog_2016-09-26_08-59-34.txt
        Messages         : Exit code 0, [ERROR_SUCCESS] The action completed successfully.
        PSComputerName   : server-999
        RunspaceId       : 020aca7f-2fb8-4f1d-b995-8e0c19e97fae


.EXAMPLE
    PS C:\>Arr | Install-PKWindowsChefClient -DownloadMSIFile -ClientVersion '12.5.1' -Credential $Cred -Verbose
        
        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                                                      
        ---                   -----                                                                      
        DownloadMSIFile       True                                                                       
        ClientVersion         12.5.1                                                                     
        Credential            System.Management.Automation.PSCredential                                  
        Verbose               True                                                                       
        ComputerName                                                                                     
        ParameterSetName      DownloadFile                                                               
        PipelineInput         True                                                                       
        KeepDownloadFile      False                                                                      
        ForceInstall          False                                                                      
        LogfileDirectory      C:\WINDOWS\Temp                                                            
        LogfileVerbose        False                                                                      
        SuppressConsoleOutput False                                                                      
        DownloadURL           http://ops-repo-1.internal.domain.com/chef/chef-client-12.5.1-1-x86.msi
        ScriptName            Install-PKWindowsChefClient                                                
        ScriptVersion         2.0.0                                                                      



        Verify connectivity to target computer(s)
        Create remote job(s)
        ERROR: Ping failure on 'foo'
        Remote job list is below

        Id     Name                  PSJobTypeName   State         HasMoreData     Location             Command                  
        --     ----                  -------------   -----         -----------     --------             -------                  
        81     ChefClientInstall_... RemoteJob       Completed     True            server-123       ...                               
        83     ChefClientInstall_... RemoteJob       Running       True            server-765.gracen... ...               

        <snip>

        
        ComputerName      : server-123
        Source            : DownloadFile
        ClientVersion     : 12.5.1
        DownloadURL       : http://ops-repo-1.internal.domain.com/chef/chef-client-12.5.1-1-x86.msi
        Filepath          : C:\Windows\Temp\20160925-103210_ChefClient.msi
        DownloadCompleted : True
        PreviousInstall   : True
        PreviousVersion   : 12.5.1.1
        InstallCompleted  : False
        InstallVersion    : 12.5.1.1
        ExitCode          : 1603
        Logfile           : C:\WINDOWS\Temp\ChefClientInstallLog_2016-09-25_10-32-22.txt
        Messages          : Exit code 1603, [ERROR_INSTALL_FAILURE] A fatal error occurred during installation.
        PSComputerName    : server-123
        RunspaceId        : 505d59d4-010f-4c16-ba49-85c991103d5d

        ComputerName      : server-765
        Source            : DownloadFile
        ClientVersion     : 12.5.1
        DownloadURL       : http://ops-repo-1.internal.domain.com/chef/chef-client-12.5.1-1-x86.msi
        Filepath          : C:\Windows\Temp\20160925-103215_ChefClient.msi
        DownloadCompleted : True
        PreviousInstall   : True
        PreviousVersion   : 11.12.4.1
        InstallCompleted  : True
        InstallVersion    : 12.5.1.1
        ExitCode          : 0
        Logfile           : C:\WINDOWS\Temp\ChefClientInstallLog_2016-09-25_10-32-16.txt
        Messages          : Exit code 0, [ERROR_SUCCESS] The action completed successfully.
        PSComputerName    : server-765.internal.domain.com
        RunspaceId        : c80a0051-978f-451e-bc18-22d527d806b1

#>

[CmdletBinding(
    DefaultParameterSetName = "DownloadFile",
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
    [string[]]$ComputerName,

    [parameter(
        ParameterSetName = "DownloadFile",
        Mandatory=$True,
        HelpMessage = "Download MSI file"
    )]
    [ValidateNotNullorEmpty()]
    [Switch]$DownloadMSIFile,

    [parameter(
        ParameterSetName = "LocalFile",
        Mandatory=$True,
        HelpMessage = "Use local MSI file"
    )]
    [Switch]$LocalMSIFile,

    [parameter(
        ParameterSetName = "LocalFile",
        Mandatory=$False,
        HelpMessage = "Absolute path to folder containing MSI file on target computer (e.g., 'c:\windows\temp\chefclient.msi')"
    )]
    [ValidateNotNullorEmpty()]
    [string]$MSIFilePath = "$Env:WinDir\Temp\chefclient.msi" ,

    [parameter(
        ParameterSetName = "DownloadFile",
        Mandatory=$False,
        HelpMessage = "File version to download (default is 12.18.31 x64, from Ops Artifactory)"
    )]
    [ValidateNotNullorEmpty()]
    [ValidateSet("Latest_public","12.18.31_internal","12.18.31_public")]
    [string]$ClientVersion = "12.18.31_internal",

    [parameter(
        ParameterSetName = "DownloadFile",
        Mandatory=$False,
        HelpMessage = "Don't remove downloaded file"
    )]
    [switch]$KeepDownloadFile,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Install even if current installation found"
    )]
    [Switch]$ForceInstall,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Absolute path to logfile directory on target computer"
    )]
    [ValidateNotNullorEmpty()]
    [string]$LogfileDirectory = "$Env:WinDir\Temp",

    [parameter(
        Mandatory=$False,
        HelpMessage = "Valid credentials on target computer"
    )]
    [ValidateNotNullOrEmpty()]
    [pscredential] $Credential,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Use verbose logging"
    )]
    [switch] $LogfileVerbose,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Suppress non-verbose console output"
    )]
    [switch] $SuppressConsoleOutput

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "3.03.0000"

    # How did we get here
    $Source = $PsCmdlet.ParameterSetName

    # Detect pipeline input
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("ComputerName")) -and (-not $ComputerName)
   
    If ($PipelineInput -eq $True) {
        # Flags so we don't keep repeating ourseves w/console output
        [switch]$PipelineMsg_Ping = $True
        [switch]$PipelineMsg_Job = $True
    }

    If ($Source -eq "DownloadFile") {
        Switch ($ClientVersion) {
            "Latest_public"     {$DownloadURL = "http://chef.io/chef/install.msi"}
            "12.18.31_internal" {$DownloadURL = "https://artifacts.internal.domain.com/artifactory/gnops-generic/chef/chef-client-12.18.31-1-x64.msi"}
            "12.18.31_public"   {$DownloadURL = "https://packages.chef.io/files/stable/chef/12.18.31/windows/2012r2/chef-client-12.18.31-1-x64.msi"}
        }
    }

    # Show our settings
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    Switch ($Source) {
        DownloadFile {
            $CurrentParams.Add("DownloadURL",$DownloadURL)
            $CurrentParams.Remove("MSIFilePath")
            $CurrentParams.Remove("LocalMSIFile")
        }
        LocalFile{
            $CurrentParams.Remove("ClientVersion")
            $CurrentParams.Remove("KeepDownloadFile")
        }
    }
    $CurrentParams.Add("ParameterSetName",$Source)
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
    
    # Splat for write-progress
    $Params_WriteProgress = @{}
    $Params_WriteProgress = @{
        Activity         =  "Get remote job status until completed or $Timeout-second timeout is reached"
        SecondsRemaining = ""
        PercentComplete  = ""
        CurrentOperation = "Working"
    }

    # For console output
    $BGColor = $Host.UI.RawUI.BackgroundColor

    # Verbose level for remote log
    Switch ($LogFileVerbose){
        $True  {$LogStr = "/L*V" }
        $False {$LogStr = "/Log" }
    }

    # Need to see whether a different switch is needed for a force install; leaving identical for now
    Switch ($ForceInstall) {
        $True  {$CommandString = "/qn /i $Target $LogStr $LogFile"}
        $False {$CommandString = "/qn /i $Target $LogStr $LogFile"}
    }

    # MSIExec exit codes for lookup 
    $ExitCodes = @{
    
        [int]'0'   ='[ERROR_SUCCESS] The action completed successfully.'
        [int]'13'  ='[ERROR_INVALID_DATA] The data is invalid.'
        [int]'87'  ='[ERROR_INVALID_PARAMETER] One of the parameters was invalid.'
        [int]'120' ='[ERROR_CALL_NOT_IMPLEMENTED] This value is returned when a custom action attempts to call a function that cannot be called from custom actions. The function returns the value ERROR_CALL_NOT_IMPLEMENTED. Available beginning with Windows Installer version 3.0.'
        [int]'1259'='[ERROR_APPHELP_BLOCK] If Windows Installer determines a product may be incompatible with the current operating system, it displays a dialog box informing the user and asking whether to try to install anyway. This error code is returned if the user chooses not to try the installation.'
        [int]'1601'='[ERROR_INSTALL_SERVICE_FAILURE] The Windows Installer service could not be accessed. Contact your support personnel to verify that the Windows Installer service is properly registered.'
        [int]'1602'='[ERROR_INSTALL_USEREXIT] The user cancels installation.'
        [int]'1603'='[ERROR_INSTALL_FAILURE] A fatal error occurred during installation.'
        [int]'1604'='[ERROR_INSTALL_SUSPEND] Installation suspended, incomplete.'
        [int]'1605'='[ERROR_UNKNOWN_PRODUCT] This action is only valid for products that are currently installed.'
        [int]'1606'='[ERROR_UNKNOWN_FEATURE] The feature identifier is not registered.'
        [int]'1607'='[ERROR_UNKNOWN_COMPONENT] The component identifier is not registered.'
        [int]'1608'='[ERROR_UNKNOWN_PROPERTY] This is an unknown property.'
        [int]'1609'='[ERROR_INVALID_HANDLE_STATE] The handle is in an invalid state.'
        [int]'1610'='[ERROR_BAD_CONFIGURATION] The configuration data for this product is corrupt. Contact your support personnel.'
        [int]'1611'='[ERROR_INDEX_ABSENT] The component qualifier not present.'
        [int]'1612'='[ERROR_INSTALL_SOURCE_ABSENT] The installation source for this product is not available. Verify that the source exists and that you can access it.'
        [int]'1613'='[ERROR_INSTALL_PACKAGE_VERSION] This installation package cannot be installed by the Windows Installer service. You must install a Windows service pack that contains a newer version of the Windows Installer service.'
        [int]'1614'='[ERROR_PRODUCT_UNINSTALLED] The product is uninstalled.'
        [int]'1615'='[ERROR_BAD_QUERY_SYNTAX] The SQL query syntax is invalid or unsupported.'
        [int]'1616'='[ERROR_INVALID_FIELD] The record field does not exist.'
        [int]'1618'='[ERROR_INSTALL_ALREADY_RUNNING] Another installation is already in progress. Complete that installation before proceeding with this install. '
        [int]'1619'='[ERROR_INSTALL_PACKAGE_OPEN_FAILED] This installation package could not be opened. Verify that the package exists and is accessible, or contact the application vendor to verify that this is a valid Windows Installer package.'
        [int]'1620'='[ERROR_INSTALL_PACKAGE_INVALID] This installation package could not be opened. Contact the application vendor to verify that this is a valid Windows Installer package.'
        [int]'1621'='[ERROR_INSTALL_UI_FAILURE] There was an error starting the Windows Installer service user interface. Contact your support personnel.'
        [int]'1622'='[ERROR_INSTALL_LOG_FAILURE] There was an error opening installation log file. Verify that the specified log file location exists and is writable.'
        [int]'1623'='[ERROR_INSTALL_LANGUAGE_UNSUPPORTED] This language of this installation package is not supported by your system.'
        [int]'1624'='[ERROR_INSTALL_TRANSFORM_FAILURE] There was an error applying transforms. Verify that the specified transform paths are valid.'
        [int]'1625'='[ERROR_INSTALL_PACKAGE_REJECTED] This installation is forbidden by system policy. Contact your system administrator.'
        [int]'1626'='[ERROR_FUNCTION_NOT_CALLED] The function could not be executed.'
        [int]'1627'='[ERROR_FUNCTION_FAILED] The function failed during execution.'
        [int]'1628'='[ERROR_INVALID_TABLE] An invalid or unknown table was specified.'
        [int]'1629'='[ERROR_DATATYPE_MISMATCH] The data supplied is the wrong type.'
        [int]'1630'='[ERROR_UNSUPPORTED_TYPE] Data of this type is not supported.'
        [int]'1631'='[ERROR_CREATE_FAILED] The Windows Installer service failed to start. Contact your support personnel.'
        [int]'1632'='[ERROR_INSTALL_TEMP_UNWRITABLE] The Temp folder is either full or inaccessible. Verify that the Temp folder exists and that you can write to it.'
        [int]'1633'='[ERROR_INSTALL_PLATFORM_UNSUPPORTED] This installation package is not supported on this platform. Contact your application vendor.'
        [int]'1634'='[ERROR_INSTALL_NOTUSED] Component is not used on this machine.'
        [int]'1635'='[ERROR_PATCH_PACKAGE_OPEN_FAILED] This patch package could not be opened. Verify that the patch package exists and is accessible, or contact the application vendor to verify that this is a valid Windows Installer patch package.'
        [int]'1636'='[ERROR_PATCH_PACKAGE_INVALID] This patch package could not be opened. Contact the application vendor to verify that this is a valid Windows Installer patch package.'
        [int]'1637'='[ERROR_PATCH_PACKAGE_UNSUPPORTED] This patch package cannot be processed by the Windows Installer service. You must install a Windows service pack that contains a newer version of the Windows Installer service.'
        [int]'1638'='[ERROR_PRODUCT_VERSION] Another version of this product is already installed. Installation of this version cannot continue. To configure or remove the existing version of this product, use�Add/Remove Programs�in�Control Panel.'
        [int]'1639'='[ERROR_INVALID_COMMAND_LINE] Invalid command line argument. Consult the Windows Installer SDK for detailed command-line help.'
        [int]'1640'='[ERROR_INSTALL_REMOTE_DISALLOWED] The current user is not permitted to perform installations from a client session of a server running the Terminal Server role service.'
        [int]'1641'='[ERROR_SUCCESS_REBOOT_INITIATED] The installer has initiated a restart. This message is indicative of a success.'
        [int]'1642'='[ERROR_PATCH_TARGET_NOT_FOUND] The installer cannot install the upgrade patch because the program being upgraded may be missing or the upgrade patch updates a different version of the program. Verify that the program to be upgraded exists on your computer and that you have the correct upgrade patch.'
        [int]'1643'='[ERROR_PATCH_PACKAGE_REJECTED] The patch package is not permitted by system policy.'
        [int]'1644'='[ERROR_INSTALL_TRANSFORM_REJECTED] One or more customizations are not permitted by system policy.'
        [int]'1645'='[ERROR_INSTALL_REMOTE_PROHIBITED] Windows Installer does not permit installation from a Remote Desktop Connection.'
        [int]'1646'='[ERROR_PATCH_REMOVAL_UNSUPPORTED] The patch package is not a removable patch package. Available beginning with Windows Installer version 3.0.'
        [int]'1647'='[ERROR_UNKNOWN_PATCH] The patch is not applied to this product. Available beginning with Windows Installer version 3.0.'
        [int]'1648'='[ERROR_PATCH_NO_SEQUENCE] No valid sequence could be found for the set of patches. Available beginning with Windows Installer version 3.0.'
        [int]'1649'='[ERROR_PATCH_REMOVAL_DISALLOWED] Patch removal was disallowed by policy. Available beginning with Windows Installer version 3.0.'
        [int]'1650'='[ERROR_INVALID_PATCH_XML] The XML patch data is invalid. Available beginning with Windows Installer version 3.0.'
        [int]'1651'='[ERROR_PATCH_MANAGED_ADVERTISED_PRODUCT] Administrative user failed to apply patch for a per-user managed or a per-machine application that is in advertise state. Available beginning with Windows Installer version 3.0.'
        [int]'1652'='[ERROR_INSTALL_SERVICE_SAFEBOOT] Windows Installer is not accessible when the computer is in Safe Mode. Exit Safe Mode and try again or try using�System Restore�to return your computer to a previous state. Available beginning with  Windows Installer version 4.0.'
        [int]'1653'='[ERROR_ROLLBACK_DISABLED] Could not perform a multiple-package transaction because rollback has been disabled.�Multiple-Package Installationscannot run if rollback is disabled. Available beginning with Windows Installer version 4.5.'
        [int]'1654'='[ERROR_INSTALL_REJECTED] The app that you are trying to run is not supported on this version of Windows. A Windows Installer package, patch, or transform that has not been signed by Microsoft cannot be installed on an ARM computer.'
        [int]'3010'='[ERROR_SUCCESS_REBOOT_REQUIRED] A restart is required to complete the install. This message is indicative of a success. This does not include installs where the�ForceReboot�action is run.'
    }


    # Create scriptblock
    Switch ($Source) {
        
        LocalFile {
            
            # Output hashtable (return if job fails)
            $InitialValue = "Error"
            $OutputHT = @{
                ComputerName      = $InitialValue
                Source            = $Source
                Filepath          = $MSIFilePath
                PreviousInstall   = $InitialValue
                PreviousVersion   = $InitialValue
                InstallCompleted  = $InitialValue
                InstallVersion    = $InitialValue
                ExitCode          = $InitialValue
                Logfile           = $InitialValue
                Messages          = $InitialValue
            }

            $ArgumentList = @($MSIFilePath,$Source,$ClientVersion,$ForceInstall,$CommandString,$ExitCodes,$LogfileDirectory,$LogStr)
            
            $SB = [scriptblock]::Create('
            
                Param($MSIFilePath,$Source,$WMIFilter,$ForceInstall,$CommandString,$ExitCodes,$LogfileDirectory,$LogStr)
                        
                $Status = @()
                $FileDate = (get-date -f yyyyMMdd-HHmmss)
                $Overwrite = $ForceInstall
                $Target    = $MSIFilePath
                $WMIFilter = "name LIKE `"Chef Client%`"" 

                $StdParams = @{}
                $StdParams = @{
                    ErrorAction = "Stop"
                    Verbose = $False
                }
                
                [switch]$Continue = $True

                $InitialValue = "Error"
                $Output = New-Object PSObject -property ([ordered]@{
                    ComputerName      = $Env:ComputerName
                    Source            = $Source
                    Filepath          = $Target
                    PreviousInstall   = $InitialValue
                    PreviousVersion   = $InitialValue
                    InstallCompleted  = $InitialValue
                    InstallVersion    = $InitialValue
                    ExitCode          = $InitialValue
                    MSILogfile        = $InitialValue
                    GNOpsLogfile      = $InitialValue
                    Messages          = $InitialValue
                })

                If ($Continue -eq $True) {
                    
                    $Continue = $False

                    $LogDate = (Get-Date -Format yyyy-MM-dd_HH-mm-ss)
                    $MSILogFile = "$LogfileDirectory\ChefClientInstall_MSILog_$LogDate.txt"
                    $GNOpsLogFile = "$LogfileDirectory\ChefClientInstall_GNOpsLog_$LogDate.txt"
                                        
                    # Create logfile
                    if (-not (Test-Path $LogfileDirectory)) {

                        Try {
                            $Null = New-Item -Path $LogfileDirectory -ItemType Directory @StdParams
                            $Continue = $True
                        }
                        Catch {
                            $Msg = "Logfile directory creation failed"
                            $ErrorDetails = $_.Exception.Message

                            $Output.InstallCompleted = $False
                            $Output.Messages = "$Msg`n$ErrorDetails"

                            $Continue = $False
                        }
                    }
                    Else {$Continue = $True}
                }
                    
                If ($Continue -eq $True) {
                    
                    $Continue = $False
                    
                    Try {
                        $Null = New-Item -Path $MSILogFile -ItemType File @StdParams
                        $Null = New-Item -Path $GNOpsLogFile -ItemType File @StdParams

                        $Output.MSILogfile = $MSILogfile
                        $Output.GNOpsLogfile = $GNOpsLogfile
                        
                        $Msg = "MSI logfile $Logfile created $($MSILogfile.CreationTime)`nGNOps logfile $GNOpsLogfile created $($GNOpsLogfile.CreationTime)"
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                        $Continue = $True

                    }
                    Catch {
                        $Msg = "Logfile creation failed "
                        $ErrorDetails = $_.Exception.Message

                        $Output.InstallCompleted = $False
                        $Output.Messages = "$Msg`n$ErrorDetails"

                        $Continue = $False
                    }   
                }

                # Verify source file
                if (-not (Test-Path $Target)) {
                    
                    $Msg = "File $Target not found"
                    $Msg | Out-File -FilePath $GNOpsLogFile -Append
                    $Output.Messages = $Msg

                    $Continue = $False
                }
                Else {$Continue = $True}

                If ($Continue.IsPresent) {

                    # Look for existing install
                    If ($Install = get-wmiobject -Class win32_product -Filter $WMIFilter @StdParams) {

                        $Output.PreviousInstall = $True
                        $Output.PreviousVersion = $Install.Version

                        If (-not ($OverWrite -eq $True)) {

                            $Msg = "$($Install.Caption) already installed, -ForceInstall not specified"
                            
                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                            $Output.FilePath = $Null
                            $Output.InstallVersion = $Null
                            $Output.ExitCode = $Null
                            $Output.Messages = $Msg

                            $Continue = $False
                        }
                    }
                    Else {
                        $Output.PreviousInstall = $False
                        $Output.PreviousVersion = "(none)"

                        $Msg = "No existing Chef-Client installation detected"

                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append
                    }
                }
                
                If ($Continue -eq $True) {
                    
                    # Install it
                    $CommandString = "/qn /i /fa $Target $LogStr $MSILogFile"

                    Try {
                        
                        $Msg = "Executing: msiexec $CommandString"
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                        $Execute = Start-Process -FilePath msiexec -ArgumentList $CommandString -Wait -PassThru @StdParams
                        
                        $Output.Exitcode = $Execute.ExitCode
                        
                        If ($Output.ExitCode -in @(0,3010)) {$Output.InstallCompleted = $True}
                        Else {$Output.InstallCompleted = $False}
                        
                        $Lookup = $ExitCodes.Item($Output.ExitCode)
                        $Results = "Exit code $($Output.ExitCode), $Lookup"
                        
                        $Output.Messages = $Results

                        $Msg = $Results
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append
                        
                        $Output.InstallVersion = (get-wmiobject -Class win32_product -Filter $WMIFilter @StdParams).Version

                    }
                    Catch {
                        $Msg = "Installation failed"
                        $ErrorDetails = $_.Exception.Message

                        $Output.InstallCompleted = $False
                        $Output.Messages = "$Msg, $ErrorDetails"

                        "[$((Get-Date).ToString())]: $Msg`n$ErrorDetails" | Out-File -FilePath $GNOpsLogFile -Append

                    }
                }
                Write-Output $Output
            
            ')
        }
        DownloadFile {

            # Output hashtable (return if job fails)
            $InitialValue = "Error"
            $OutputTemplate = New-Object PSObject -property ([ordered]@{
                ComputerName      = $Env:ComputerName
                ClientVersion     = $ClientVersion
                DownloadURL       = $DownloadUrl
                Filepath          = $Target
                DownloadCompleted = $InitialValue
                PreviousInstall   = $InitialValue
                PreviousVersion   = $InitialValue
                InstallCompleted  = $InitialValue
                InstallVersion    = $InitialValue
                ExitCode          = $InitialValue
                Logfile           = $InitialValue
                Messages          = $InitialValue
            })

            
            $ArgumentList = @($DownloadUrl,$Source,$ClientVersion,$KeepDownloadFile,$ForceInstall,$CommandString,$ExitCodes,$LogfileDirectory,$LogStr)

            $SB = [scriptblock]::Create('
            
                Param($DownloadUrl,$Source,$CLientVersion,$KeepDownloadFile,$ForceInstall,$CommandString,$ExitCodes,$LogfileDirectory,$LogStr)
                        
                $Status = @()
                $FileDate = (get-date -f yyyyMMdd-HHmmss)

                $Folder    = $TargetFolder
                $File      = $File
                $Target    = "$Env:WinDir\Temp\$FileDate`_ChefClient.msi"
                $URL       = $DownloadURL
                $Version   = $ClientVersion
                $OverWrite = $ForceInstall
                $Keep      = $KeepDownloadFile

                $WMIFilter = "name LIKE `"Chef Client%`"" 

                $StdParams = @{}
                $StdParams = @{
                    ErrorAction = "Stop"
                    Verbose = $False
                }
                
                [switch]$Continue = $True

                $InitialValue = "Error"
                $Output = New-Object PSObject -property ([ordered]@{
                    ComputerName      = $Env:ComputerName
                    Source            = $Source
                    ClientVersion     = $Version
                    DownloadURL       = $URL
                    Filepath          = $InitialValue
                    DownloadCompleted = $InitialValue
                    PreviousInstall   = $InitialValue
                    PreviousVersion   = $InitialValue
                    InstallCompleted  = $InitialValue
                    InstallVersion    = $InitialValue
                    ExitCode          = $InitialValue
                    MSILogfile        = $InitialValue
                    GNOpsLogfile      = $InitialValue
                    Messages          = $InitialValue
                })
                
                If ($Continue -eq $True) {
                        
                    $Continue = $False

                    $LogDate = (Get-Date -Format yyyy-MM-dd_HH-mm-ss)
                    $MSILogFile = "$LogfileDirectory\ChefClientInstall_MSILog_$LogDate.txt"
                    $GNOpsLogFile = "$LogfileDirectory\ChefClientInstall_GNOpsLog_$LogDate.txt"

                                        
                    # Create logfile
                    if (-not (Test-Path $LogfileDirectory)) {
                        Try {
                            $Null = New-Item -Path $LogfileDirectory -ItemType Directory @StdParams
                            
                            $Continue = $True
                        }
                        Catch {
                            $Msg = "Logfile directory creation failed"
                            $ErrorDetails = $_.Exception.Message
                            
                            $Output.InstallCompleted = $False
                            $Output.Messages = "$Msg`n$ErrorDetails"
                        }
                    }
                    Else {$Continue = $True}
                }
                            
                If ($Continue.IsPresent) {
                    
                    $Continue = $False
                    
                    Try {
                        
                        $Null = New-Item -Path $MSILogFile -ItemType File @StdParams
                        $Null = New-Item -Path $GNOpsLogFile -ItemType File @StdParams

                        $Output.MSILogfile = $MSILogfile
                        $Output.GNOpsLogfile = $GNOpsLogfile
                        
                        $Msg = "MSI logfile $Logfile created $($MSILogfile.CreationTime)`nGNOps logfile $GNOpsLogfile created $($GNOpsLogfile.CreationTime)"
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                        $Continue = $True
                    }
                    Catch {
                        $Msg = "Logfile creation failed "
                        $ErrorDetails = $_.Exception.Message
                        
                        $Output.InstallCompleted = $False
                        $Output.Messages = "$Msg`n$ErrorDetails"

                        $Continue = $False
                    }   
                }


                If ($Continue.IsPresent) {

                    # Look for existing install
                    If ($Install = get-wmiobject -Class win32_product -Filter $WMIFilter @StdParams) {

                        $Output.PreviousInstall = $True
                        $Output.PreviousVersion = $Install.Version

                        If (-not ($OverWrite -eq $True)) {

                            $Msg = "$($Install.Caption) already installed, -ForceInstall not specified, file not downloaded"

                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append
                            
                            $Output.FilePath = $Null
                            $Output.InstallVersion = $Null
                            $Output.ExitCode = $Null
                            $Output.DownloadCompleted = $False
                            $Output.InstallCompleted = $False
                            $Output.Messages = $Msg
                            
                            $Continue = $False
                        }
                    }
                    Else {
                        $Output.PreviousInstall = $False
                        $Output.PreviousVersion = "(none)"

                        $Msg = "No existing Chef-Client installation detected"
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append
                    }
                }

                If ($Continue.IsPresent) {
                    
                    $Continue = $False
                    Try {

                        $Msg = "Download Chef-Client from $URL as file $Target"
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                        $ProgressPreference = "SilentlyContinue"
                        Invoke-WebRequest -Uri $URL -OutFile $Target @StdParams
                        
                        $Output.DownloadCompleted = $True
                        $Output.Filepath = $Target
                        
                        $Msg = "Download completed"
                        $Status += $Msg

                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append
                        
                        $Continue = $True
                    }
                    Catch {
                        Try {
                            $WebClient = New-Object System.Net.WebClient @StdParams
                            $Null = $WebClient.DownloadFile($URL, $Target)
                            
                            $Output.DownloadCompleted = $True
                            $Output.Filepath = $Target

                            $Msg = "Download completed"
                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                            $Status += $Msg

                            $Continue = $True
                        }
                        Catch {
                            $Msg = "Download failed"
                            $ErrorDetails = $_.Exception.Message

                            "[$((Get-Date).ToString())]: $Msg`n$ErrorDetails" | Out-File -FilePath $GNOpsLogFile -Append

                            $Output.DownloadCompleted = $False
                            $Output.InstallCompleted = $False
                            $Output.Messages = "$Msg`n$ErrorDetails"

                            $Continue = $False
                        }
                    }
                    $ProgressPreference = "Continue"
                }
                
                If ($Continue.IsPresent) {
                    
                    # Install it
                    $CommandString = "/qn /i $Target $LogStr $MSILogFile"

                    Try {

                        $Msg = "Execute msiexec $CommandString"
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                        $Execute = Start-Process -FilePath msiexec -ArgumentList $CommandString -Wait -PassThru @StdParams
                        $Output.Exitcode = $Execute.ExitCode
                        
                        If ($Output.ExitCode -in @(0,3010)) {$Output.InstallCompleted = $True}
                        Else {$Output.InstallCompleted = $False}
                        
                        $Lookup = $ExitCodes.Item($Output.ExitCode)
                        $Results = "Exit code $($Output.ExitCode), $Lookup"
                        
                        $Msg = $Results
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append

                        $Output.Messages = $Results
                        $Output.InstallVersion = (get-wmiobject -Class win32_product -Filter $WMIFilter @StdParams).Version

                    }
                    Catch {
                        $Msg = "Installation failed"
                        $ErrorDetails = $_.Exception.Message

                        "[$((Get-Date).ToString())]: $Msg`n$ErrorDetails" | Out-File -FilePath $GNOpsLogFile -Append

                        $Output.InstallCompleted = $False
                        $Output.Messages = "$Msg, $ErrorDetails"                            
                    }

                    If (-not ($Keep -eq $True)) {
                        Try {
                            $Null = Get-Item $Target | Remove-Item -Force -ErrorAction SilentlyContinue
                            $Msg = "Removed file $Target"
                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $GNOpsLogFile -Append
                        }
                        Catch {}
                    }
                }
                Write-Output $Output
            
            ')
        }
    }

    # Splat for Invoke-Command
    $Params_InvokeCommand = @{}
    $Params_InvokeCommand = @{
        ComputerName = ""
        ErrorAction  = "Stop"
        ScriptBlock  = $SB
        ArgumentList = $ArgumentList
        AsJob        = $True
        JobName      = ""
        Verbose      = $False
    }
    If ($CurrentParams.Credential) {
        $Params_InvokeCommand.Add("Credential",$Credential)
    }

    # Flags so we don't keep repeating ourseves w/console output
    If ($PipelineInput -eq $True) {
        [switch]$PipelineMsg_Ping = $True
        [switch]$PipelineMsg_Job = $True
    }

    # Arrays
    $Target = @()
    $Jobs = @()
    $FailedJobs = @()

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
        $Msg = "Test connection"
        $Activity = $Msg

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
                        $Msg = "Ping failure on $Computer"
                        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("ERROR: $Msg on '$Computer'")}
                        Else {Write-Verbose $Msg}

                        $Output = $OutputTemplate.PSObject.Copy()
                        $Output.ComputerName = $Computer
                        $Output.Messages = $Msg
                        $FailedJobs += $Output
                    }
                } 
                Catch {}
            }
            Else {
                $Msg = "Ping test for $Computer cancelled by user"
                $FGColor = "Red"
                
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}   

                $Output = $OutputTemplate.PSObject.Copy()
                $Output.ComputerName = $ComputerName
                $Output.InstallComplete = $False
                $Output.Messages = "Ping $($Msg.tolower())"  
                $FailedJobs += $Output 
            }
        }
        $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False
    }

    # If we have target computers
    If ($Target) {

        $Total = $Target.Count
        $Current = 0

        # Loop
        Foreach ($Computer in ($Target | Sort-Object)) {
            
            $Current ++

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

            # For progress bar
            $Msg = "Create remote job to install Chef-Client"
            
            If (-not $PipelineInput) {Write-Verbose $Computer}
            Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 
            
            If ($PsCmdlet.ShouldProcess($Computer,$Msg)) {
                Try {
                    $Params_InvokeCommand.ComputerName = $Computer
                    $Params_InvokeCommand.JobName = "ChefClientInstall_$Computer_$((Get-Date -f yyyy-MM-yy_HH-mm-ss))"
                    $Jobs += Invoke-Command @Params_InvokeCommand
                }

                Catch {
                    $Msg = "Can't create job"
                    $ErrorDetails = $_.Exception.Message
                    $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                    $Output = $OutputTemplate.PSObject.Copy()
                    $Output.ComputerName = $ComputerName
                    $Output.Messages = "$Msg`n$ErrorDetails"  
                    $JobResults += $Output  
                }
            }
            Else {
                $Msg = "Chef-Client installation on $Computer cancelled by user"
                $FGColor = "Red"
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
                Else {Write-Verbose $Msg}   

                $Output = $OutputTemplate.PSObject.Copy()
                $Output.ComputerName = $ComputerName
                $Output.InstallComplete = $False
                $Output.Messages = "Ping $($Msg.tolower())"  
                $FailedJobs += $Output 
            }

        } #end create jobs for each computer
        
        $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False

    } #end if target
   
} #end process

End {
    
    If ($FailedJobs.Count -gt 0) {
        $Msg = "Errors/cancellations"
        #$FGColor = "Red"
        #If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
        Write-Verbose $Msg
        Write-Output ($FailedJobs | Select $Select)
    }

    If ($Jobs.count -gt 0) {
        $Msg = "Remote job list is below"
        #$FGColor = "Green"
        #If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
        Write-Verbose $Msg
        Write-Output ($Jobs | Get-Job)
    }
    Else {
        $Msg = "Job execution failed"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
    }


}

} #end Function_Install-PKWindowsChefClient.ps1

