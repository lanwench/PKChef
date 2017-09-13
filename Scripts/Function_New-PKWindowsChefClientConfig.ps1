#requires -Module ActiveDirectory
function New-PKChefClientConfig {
<#
.SYNOPSIS
    Creates new files on a remote computer to register the node with a Chef server on the next chef-client run

.DESCRIPTION
    Creates new files on a remote computer to register the node with a Chef server on the next chef-client run
    Files include client.rb file and initial json, plus a nodename.rb to force lowercase name registration
    Renames previous folder if found and -ForceFolderCreation is specified, otherwise will not proceed if folder already exists
    Uses Invoke-Command and a remote scriptblock
    Supports ShouldProcess
    Accepts pipeline input
    Returns a PSObject

.NOTES
    File    : Function_New-PKChefClientConfig.ps1
    Version : 04.02.0000
    Author  : Paula Kingsley
    History :    
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 
        
        v1.0.0      - 2016-09-16 - Created script
        v2.0.0      - 2016-10-11 - Renamed for consistency
        v3.0.0      - 2017-02-01 - Fixed issue with connection failure when not using -ActiveDirectoryLookup, added Credential, 
                                   general improvements, warning for new nodes
        v3.1.0      - 2017-03-21 - Added Server parameter for AD lookup
        v4.0.0      - 2017-03-28 - Made more generic; removed embedded validator key (now uses get-content from provided file) 
                                   and allows selection of roles (defaults to Ops standard)
        v4.0.1      - 2017-03-29 - Fixed missing comma in node.json
        v4.1.0      - 2017-05-05 - Commenting out logfile line, adding parameter to invoke chef-client run
        v04.02.0000 - 2017-09-07 - Added seconds to get-date


.EXAMPLE
     C:\> New-PKChefClientConfig -ComputerName server-xyz -Credential $Cred -ValidatorPemFile "C:\Users\jbloggs\Dropbox\Powershell\ops_chef_validator.pem" -ForceFolderCreation -Verbose
        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                                       
        ---                   -----                                                       
        ComputerName          {server-xyz}                                              
        ValidatorPemFile      C:\Users\jbloggs\Dropbox\Powershell\ops_chef_validator.pem
        ForceFolderCreation   True                                                        
        Verbose               True                                                        
        Roles                 {base-chef, base-baremetal, base-os, base-monitoring}       
        ChefServerURL         https://chef.internal.domain.com/organizations/gnops    
        ChefDir               c:\chef                                                     
        ChefEnvironment       _default                                                    
        ADDomain              internal.domain.com                                     
        Server                
        Credential            System.Management.Automation.PSCredential                                                                               
        SuppressConsoleOutput False                                                       
        PipelineInput         False                                                       
        ScriptName            New-PKChefClientConfig                            
        ScriptVersion         3.0.0                                                       

        Connect to 'internal.domain.com'
        VERBOSE: Connected to 'internal.domain.com'
        Get nearest available domain controller
        VERBOSE: Connected to domain controller 'EVLDC00.internal.domain.com'
        Check validator key file
        VERBOSE: Validator key file syntax appears correct

        Type YES to confirm that computer 'server-xyz' is *NOT* already registered in 
        Chef server https://chef.internal.domain.com/organizations/gnops: yes

        server-xyz
	        Look up FQDN in internal.domain.com
	        Create remote PSsession
	        Invoke remote scriptblock
	        Operation completed successfully


        ComputerName   : SERVER-XYZ
        NodeStatus     : NewNode
        ConfigCopied   : True
        LogFile        : C:\Windows\Temp\ChefConfig_2017-03-28_15-14.txt
        Messages       : Renamed c:\chef to c:\chef.bak.2017-03-28_15-14
                         Created directory c:\chef
                         Created file c:\chef\client.rb
                         Created file c:\chef\validator.pem
                         Created file c:/chef/client.d/nodename.rb
                         Added content to file c:/chef/client.d/nodename.rb
                         Created file c:\chef\node.json
        PSComputerName : server-xyz.internal.domain.com
        RunspaceId     : ad137b7c-7e10-478a-9e62-75b76275d508


.EXAMPLE
    C:\> New-PKChefClientConfig -ComputerName server-abc -ValidatorPemFile "c:\Users\jbloggs\Dropbox\Powershell\ops_chef_validator.pem" -Roles foo,bar -ForceFolderCreation -Verbose
    
        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                                       
        ---                   -----                                                       
        ComputerName          {server-abc}                                              
        ValidatorPemFile      c:\Users\jbloggs\Dropbox\Powershell\ops_chef_validator.pem
        Roles                 {foo, bar}                                                  
        ForceFolderCreation   True                                                        
        Verbose               True                                                        
        ChefServerURL         https://chef.internal.domain.com/organizations/gnops    
        ChefDir               c:\chef                                                     
        ChefEnvironment       _default                                                    
        ADDomain              internal.domain.com                                     
        Server                                                                            
        Credential                                                                        
        SuppressConsoleOutput False                                                       
        PipelineInput         False                                                       
        ScriptName            New-PKChefClientConfig                            
        ScriptVersion         3.0.0                                                       

        Connect to 'internal.domain.com'
        VERBOSE: Connected to 'internal.domain.com'
        Get nearest available domain controller
        VERBOSE: Connected to domain controller 'EVLDC00.internal.domain.com'
        Check validator key file
        VERBOSE: Validator key file syntax appears correct

        Type YES to confirm that computer 'server-abc' is *NOT* already registered in 
        Chef server https://chef.internal.domain.com/organizations/gnops: yes

        server-abc
	        Look up FQDN in internal.domain.com
	        Create remote PSsession
	        Invoke remote scriptblock
	        Operation completed successfully


        ComputerName   : SERVER-ABC
        NodeStatus     : NewNode
        ConfigCopied   : True
        LogFile        : C:\Windows\Temp\ChefConfig_2017-03-28_15-15.txt
        Messages       : Renamed c:\chef to c:\chef.bak.2017-03-28_15-15
                         Created directory c:\chef
                         Created file c:\chef\client.rb
                         Created file c:\chef\validator.pem
                         Created file c:/chef/client.d/nodename.rb
                         Added content to file c:/chef/client.d/nodename.rb
                         Created file c:\chef\node.json
        PSComputerName : server-abc.internal.domain.com
        RunspaceId     : 9aef36f8-3280-4c3a-a4c5-c9df4fdcb3d1

#>
[cmdletbinding(
    #DefaultParameterSetName = $True,
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [parameter(
        Mandatory = $True,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Name or FQDN of remote computer to register"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("Name","FQDN","HostName","VM")]
    [string[]]$ComputerName,

    [parameter(
        Mandatory = $False,
        HelpMessage = "Roles (default is Ops standard base roles: 'base-chef','base-baremetal','base-os','base-monitoring'"
    )]
    [ValidateNotNullOrEmpty()]
    [string[]]$Roles = @('base-chef','base-baremetal','base-os','base-monitoring'),

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Full URL to Chef server (default is Operations, chef.internal.domain.com)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("https://")]
    [string]$ChefServerURL = "https://chef.internal.domain.com/organizations/gnops",

    [parameter(
        Mandatory = $True,
        HelpMessage = "Full path to validator.pem file"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$ValidatorPemFile,

    [Parameter(
        Mandatory = $False,
        HelpMessage = "Chef directory (absolute path on remote computer; modify at your peril)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$ChefDir = "c:\chef",

    [parameter(
        Mandatory=$False,
        HelpMessage = "Chef environment for node (default is '_default')"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("Location")]
    [string]$ChefEnvironment = '_default',

    [parameter(
        Mandatory=$False,
        HelpMessage = "Rename old Chef directory if found & recreate (new node only)" 
    )]
    [Switch] $ForceFolderCreation,

    [parameter(
        Mandatory = $False,
        HelpMessage = "Active Directory domain (required for lookups as nodes will register using their AD DNS domain name) - default is user domain"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name,

    [parameter(
        Mandatory = $False,
        HelpMessage = "Domain controller name or FQDN (default is next available)"
    )]
    [ValidateNotNullOrEmpty()]
    [string] $Server,

    [parameter(
        #ParameterSetName = "AD",
        Mandatory = $False,
        HelpMessage = "Valid credentials on target computer"
    )]
    [ValidateNotNullOrEmpty()]
    [PSCredential] $Credential,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Invoke a chef-client run after successful file/directory creation"
    )]
    [Switch]$InvokeChefClientRun,

    [parameter(
        Mandatory=$False,
        HelpMessage = "Hide non-verbose console output"
    )]
    [Switch]$SuppressConsoleOutput

)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "04.02.0000"

    # Detect pipeline input
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("ComputerFQDN")) -and (-not $ComputerName)

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

    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $False
    }

    # Console output color
    $BGColor = $Host.UI.RawUI.BackgroundColor


    #region Active Directory

    # Connect to AD
    $Msg = "Connect to '$ADDomain'"
    Write-Verbose $Msg

    Try {
        $Param_GetAD = @{}
        $Param_GetAD = @{
            Identity    = $ADDomain
            ErrorAction = "Stop"
            Verbose     = $False
        }
        If ($CurrentParams.Credential) {
            $Param_GetAD.Add("Credential",$Credential)
        }
        $ADConfirm = Get-ADDomain @Param_GetAD
        $Msg = "Connected to '$($ADConfirm.DNSRoot)'"
        Write-Verbose $Msg
    
        If (-not $Server) {
            $Msg = "Get nearest available domain controller"
            Write-Verbose $Msg
            Try {        
                $Param_GetDC = @{}
                $Param_GetDC = @{
                    DomainName      = $ADConfirm.DNSRoot
                    Discover        = $True
                    NextClosestSite = $True
                    ErrorAction     = "Stop"
                    Verbose         = $False
                }
                $DC = $((Get-ADDomainController @Param_GetDC).Hostname)
                Write-Verbose "Connected to domain controller '$DC'"
            }
            Catch {
                $Msg = "Can't connect to a domain controller for '$($ADConfirm.DNSRoot)'"
                $ErrorDetails = $_.exception.message
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                Break
            }    
        }
        Else {
            $Msg = "Get available domain controller"
            Write-Verbose $Msg
            Try {        
                $Param_GetDC = @{}
                $Param_GetDC = @{
                    Identity    = $Server
                    ErrorAction = "Stop"
                    Verbose     = $False
                }
                If ($CurrentParams.Credential) {
                    $Param_GetDC.Add("Credential",$Credential)
                }
                $DC = $((Get-ADDomainController @Param_GetDC).Hostname)
                Write-Verbose "Connected to domain controller '$DC'"
            }
            Catch {
                $Msg = "Can't connect to  domain controller' $Server' in '$($ADConfirm.DNSRoot)''"
                $ErrorDetails = $_.exception.message
                $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
                Break
            }  
        }
    }
    Catch [exception] {
        $Msg = "Can't connect to '$ADDomain'"
        $ErrorDetails = $_.exception.Message
        If (-not $SuppressConsoleOutput) {$Host.UI.WriteErrorLine("ERROR: $Msg `n$ErrorDetails")}
        Else {Write-Verbose "$Msg `n$ErrorDetails"}
        Break
    }
    #endregion Active Directory
    
    #region Attempt to validate the validator pem file
    $Msg = "Check validator key file"
    $FGColor= "Yellow"
    If (-not $SuppressConsoleOutput.IsPresent ){$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}

    Try {
        $HS_ValidatorPEM_Text = [IO.File]::ReadAllText($ValidatorPemFile) -replace '\s+\r\n+', ""

        If (($HS_ValidatorPEM_Text | Select-String "-----BEGIN RSA PRIVATE KEY-----").LineNumber -ne 1) {
            $Msg = "Invalid validator PEM key. Please ensure your file begins with -----BEGIN RSA PRIVATE KEY-----"
            If (-not $SuppressConsoleOutput) {$Host.UI.WriteErrorLine("ERROR: $Msg `n$ErrorDetails")}
            Else {Write-Verbose "$Msg `n$ErrorDetails"}
            Break
        }
        Else {
            $Msg = "Validator key file syntax appears correct"
            Write-Verbose $Msg
        }
    }
    Catch {
        $Msg = "Invalid validator key file"
        If (-not $SuppressConsoleOutput) {$Host.UI.WriteErrorLine("ERROR: $Msg `n$ErrorDetails")}
        Else {Write-Verbose "$Msg `n$ErrorDetails"}
        Break
    }

    #region Here-Strings  & scriptblock content
    
    [string]$NodeStatus = "NewNode"  # Adding this because existingnode isn't working right now
    Switch ($NodeStatus) {
        NewNode {[switch]$Initialize = $True}
        ExistingNode {[switch]$Initialize = $False}
    } 

    # Ruby directory path
    $RBChefDir = $ChefDir.Replace("\","/")


    # Here-string for main content of client.rb
    $HS_ClientRB_Text_Normal = @"
#json_attribs '$($RBChefDir)/node.json'
chef_server_url "$ChefServerURL"
# Using the FQDN as default node name
node_name "##NODENAME##"
client_fork true
#log_location '$($RBChefDir)/client.log'
ssl_verify_mode :verify_none
validation_client_name "gnops-validator"
verify_api_cert false
environment "$ChefEnvironment"

Ohai::Config[:plugin_path] << "$($RBChefDir)/ohai_plugins"

Dir.glob(File.join("$($RBChefDir)", "client.d", "*.rb")).each do |conf|
  Chef::Config.from_file(conf)
end
"@

    #Here-string for initial content of client.rb (??)
    $HS_ClientRB_Text_Initial = @"
json_attribs '$($RBChefDir)/node.json'
chef_server_url    '$ChefServerURL'
node_name "##NODENAME##"
validation_key     '$($RBChefDir)/validator.pem'
validation_client_name 'bm_iso_validator'
ssl_verify_mode :verify_none
"@

    # Here-string for node name in client.rb (??)
    $HS_ClientRB_Name_Text = @"
node_name "##NODENAME##"
"@
 
    # Here-string for roles in JSON file
    $Str = $Null
    $Str = "`n{`n"
    $Str += '   "roles": ['
    Foreach ($Role in ($Roles | Select -SkipLast 1)){
        $Str += "`n     """
        $Str += "$role"
        $Str += ""","
    }
    $Str += "`n     """
    $Str += "$($Roles | Select -Last 1)"
    $Str += """"
    $Str += "`n   ],`n"

    $Str += '   "recipes": ['
    Foreach ($Role in ($Roles | Select -SkipLast 1)){
        $Str += "`n     """
        $Str += "role_$role"
        $Str += ""","
    }
    $Str += "`n     """
    $Str += "role_$($Roles | Select -Last 1)"
    $Str += """"
    $Str += "`n   ]"
    $Str += "`n}"


    $HS_JSON_Text_Initial = @"
    $Str    
"@
    #endregion Here-Strings

    #region scriptblock

    # Hashtable for parameters in remote scriptblock
    $Param_ICArgs_Template = @{}
    $Param_ICArgs_Template = @{
        NodeName              = $Null
        NodeStatus            = $NodeStatus
        Initialize            = $Initialize
        Rename                = $ForceFolderCreation.IsPresent
        ChefDir               = $ChefDir
        RBChefDir             = $RBChefDir
        ClientRB_File         = "$ChefDir\client.rb"
        ValidatorPEM_File     = "$ChefDir\validator.pem"
        ClientPEM_File        = "$ChefDir\client.pem"
        JSON_File             = "$ChefDir\node.json"
        ConfD_Dir             = "$RBChefDir/client.d"
        ClientRB_Name_File    = "$RBChefDir/client.d/nodename.rb"
        ValidatorPEM_Text     = $HS_ValidatorPEM_Text
        JSONText_Initial      = $HS_JSON_Text_Initial
        ClientRB_Name_Text    = $HS_ClientRB_Name_Text
        ClientRB_Text_Normal  = $HS_ClientRB_Text_Normal
        ClientRB_Text_Initial = $HS_ClientRB_Text_Initial
    }

    #region scriptblocks

    # SB to create files
    $ScriptBlockCreate = [scriptblock]::Create('
    
        param($Param_ICArgs)

        $ErrorActionPreference = "Stop"
        $InitialValue = "Error"
        $Date = (Get-Date -f yyyy-MM-dd_HH.mm)
        
        switch($Param_ICArgs.Rename) {
            $True {[switch]$RenameFolder = $True}
            $False {[switch]$RenameFolder = $False}
        }

        $StdParams = @{}
        $StdParams = @{
            ErrorAction = "Stop"
            Verbose = $False
        }

        $LogDate = Get-Date -f yyyy-MM-dd_HH-mm-ss
        Try {
            If (-not (test-path ($LogFile = "$Env:WinDir\Temp\ChefConfig_$LogDate.txt"))) {
                $Null = New-Item $LogFile -ItemType File -Force @StdParams
            }
        }
        Catch {}

        $Msg = "Logfile $Logfile created"
        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
        
        $Output = @{
            ComputerName = $Env:ComputerName
            NodeName     = $Param_ICArgs.NodeName
            NodeStatus   = $Param_ICArgs.NodeStatus
            ConfigCopied = $InitialValue
            LogFile      = $LogFile
            Messages     = $InitialValue
        }
        $Select = "ComputerName","NodeStatus","ConfigCopied","LogFile","Messages"

        # Fix boilerpate
        # Replace nodename in template here-string within parameter hashtable
        $Param_ICArgs.ClientRB_Name_Text    = $Param_ICArgs.ClientRB_Name_Text.Replace("##NODENAME##",$Param_ICArgs.NodeName)
        $Param_ICArgs.ClientRB_Text_Initial = $Param_ICArgs.ClientRB_Text_Initial.Replace("##NODENAME##",$Param_ICArgs.NodeName)
        $Param_ICArgs.ClientRB_Text_Normal  = $Param_ICArgs.ClientRB_Text_Normal.Replace("##NODENAME##",$Param_ICArgs.NodeName)
        
        $Actions = @()
        [switch] $Continue = $False

        Try {
            Switch ($Param_ICArgs.NodeStatus) {
                NewNode {
                    If (Test-Path $Param_ICArgs.ChefDir) {
                        If ($RenameFolder.IsPresent) {
                            Try {
                                $Date = (Get-Date -f yyyy-MM-dd_HH-mm)
                                $Null = Rename-Item -Path $Param_ICArgs.Chefdir -NewName "$($Param_ICArgs.Chefdir).bak.$Date" -force @StdParams
                                $Msg = "Renamed $($Param_ICArgs.Chefdir) to $($Param_ICArgs.Chefdir).bak.$Date"
                                $Actions += $Msg
                                $Continue = $True

                                "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
                            }
                            Catch {
                                $ErrorDetails = $_.Exception.Message
                                $Msg = "Error renaming existing directory $($Param_ICArgs.Chefdir)`n$ErrorDetails"
                                $Actions += $Msg
                                $Continue = $False

                                "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
                            }
                        }
                        Else {
                            $Msg = "Chef directory already exists; -ForceFolderCreation not specified"
                            $Output.ConfigCopied = $False
                            $Output.Messages = $Msg
                            $Actions += $Msg
                            $Continue = $False

                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
                        }
                   }
                   Else {$Continue = $True}
                   If ($Continue.IsPresent) {
                        Try {
                            # Create directory c:\chef
                            $Null = New-Item -ItemType Directory -Force -Path $Param_ICArgs.ChefDir @StdParams
                            $Msg = "Created directory $($Param_ICArgs.ChefDir)"
                            $Actions += $Msg

                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
        
                            # Create initial client.rb file in c:\chef
                            $Param_ICArgs.ClientRB_Text_Initial | out-file -FilePath $Param_ICArgs.ClientRB_File @StdParams -Encoding ASCII
                            $Msg = "Created file $($Param_ICArgs.ClientRB_File)"
                            $Actions += $Msg

                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams

                            # Create validator PEM file in c:\chef
                            $Param_ICArgs.ValidatorPEM_Text | out-file -FilePath $Param_ICArgs.ValidatorPEM_File @StdParams -Force -Encoding ASCII
                            $Msg = "Created file $($Param_ICArgs.ValidatorPEM_File)"
                            $Actions += $Msg

                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams

                            # Set flag
                            $Continue = $True
                        }
                        Catch {
                            $ErrorDetails = $_.Exception.Message
                            $Msg = "Operation failed`n$ErrorDetails"
                            $Actions += $Msg
                            $Continue = $False

                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
                        }
                    }
                }
                ExistingNode {

                    If (-not (Test-Path $Param_ICArgs.ChefDir)) {
                        $Msg = "Chef directory not found"
                        $Output.ConfigCopied = $False
                        $Actions += $Msg
                        $Continue = $False
                        "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
                    }
                    Else {
                        Try {
                            $Continue = $False
                            # Rename old client.rb file    
                            If (Test-Path $Param_ICArgs.ClientRB_File) {$Null = Rename-Item $Param_ICArgs.ClientRB_File -NewName "Backup_$Param_ICArgs.ClientRB_File`_$Date" @StdPArams}
                            $Msg = "Rename $($Param_ICArgs.ClientRB_File) file if found"
                            $Actions += $Msg
                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
                            
                            # Create new client.rb file
                            $Null = $ClientRB_Text_Normal | out-file -FilePath $Param_ICArgs.ClientRB_File @StdParams -Force -Encoding ASCII
                            $Msg = "Created $($Param_ICArgs.ClientRB_File) file"
                            $Actions += $Msg
    
                            # Remove the old validator.pem if found
                            If (Test-Path $Param_ICArgs.ValidatorPEM_File) {$Null = Remove-Item $Param_ICArgs.ValidatorPEM_File @StdParams}
                            $Msg = "Removed any existing $($Param_ICArgs.ValidatorPEM_File) file"
                            $Actions += $Msg
                
                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams

                            # Set flag
                            $Continue = $True
                        }
                        Catch {
                            $ErrorDetails = $_.Exception.Message
                            $Msg = "Operation failed`n$ErrorDetails"
                            
                            $Actions += $Msg
                            
                            "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams

                            $Continue = $False

                        }
                    }
                }
            } #end switch

            If ($Continue.IsPresent) {

                Try {
                    # Create new nodename.rb
                    If (-not (Test-Path $Param_ICArgs.ClientRB_Name_File)) {$Null = New-Item -ItemType File -Force -Path $Param_ICArgs.ClientRB_Name_File -ErrorAction Stop}
                    $Msg = "Created file $($Param_ICArgs.ClientRB_Name_File)"
                    $Actions += $Msg
                    "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
    
                    # Add content to new nodename.rb
                    $Null = $Param_ICArgs.ClientRB_Name_Text | out-file -FilePath $Param_ICArgs.ClientRB_Name_File -Force -Encoding ASCII -ErrorAction Stop 
                    $Msg = "Added content to file $($Param_ICArgs.ClientRB_Name_File)"
                    $Actions += $Msg
                    "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams

                    # Create new json file
                    $Msg = "Created file $($Param_ICArgs.json_file)"
                    $Null = $Param_ICArgs.JSONText_Initial | out-file -FilePath $Param_ICArgs.json_file -Force -Encoding ASCII -ErrorAction Stop
                    
                    $Actions += $Msg
                    "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams

                    $Output.ConfigCopied = $True
                }
                Catch {
                    $ErrorDetails = $_.Exception.Message
                    $Msg = "Operation failed`n$ErrorDetails"
                    $Output.ConfigCopied = $False
                    $Actions += $Msg
                    
                    $Actions += $Msg
                    "[$((Get-Date).ToString())]: $Msg" | Out-File -FilePath $LogFile -Append @StdParams
                    
                    $Continue = $False
                }
            
                If ($Actions) {$Output.Messages = ($Actions -join("`n"))}
            }
        }
        Catch {
            $Msg = "Operation failed"
            $Output.Messages = "$Msg ($($_.Exception.Message))"
        }

        Write-Output (New-Object PSObject -Property $Output | Select $Select)
    ')

    # SB to run chef-client
    $ScriptBlockRun = [scriptblock]::Create('
        Try {
            Invoke-Expression -Command "chef-client" -ErrorAction Stop
        }
        Catch {
            $_.Exception.Message
        }
    ')
    #endregion scriptblocks

    #region Splats

    # Get AD computer dnshostname
    $Param_GetADComputer = @{}
    $Param_GetADComputer = @{
        Identity    = ""
        Server      = $DC
        ErrorAction = "Stop"
        Verbose     = $False
    }
    If ($CurrentParams.Credential) {
        $Param_GetADComputer.Add("Credential",$Credential)
    }

    # Create remote PSsession
    $Param_NewPSSession = @{}
    $Param_NewPSSession = @{
        ComputerName   = ""
        Authentication = "Negotiate"
        ErrorAction    = "Stop"
        Verbose        = $False
    }
    If ($CurrentParams.Credential) {
        $Param_NewPSSession.Add("Credential",$Credential)
    }

    # Run invoke-command in pssession
    $Param_InvokeCommand = @{
        Session      = ""
        ErrorAction  = "Stop"
        ScriptBlock  = ""
        ArgumentList = ""
        Verbose      = $False
    }

    #endregion Splats

    #region Output

    # Output hashtable (return if job fails)
    $InitialValue = "Error"
    $OutputHT = @{}
    $OutputHT = @{
        ComputerName = $Env:ComputerName
        NodeName     = $InitialValue
        NodeStatus   = $NodeStatus
        ConfigCopied = $InitialValue
        LogFile      = $InitialValue
        Messages     = $InitialValue
    }
    $Select = "ComputerName","NodeName","NodeStatus","ConfigCopied","InvokedRun","LogFile","Messages"
    If ($InvokeChefClientRun.IsPresent) {
        $OutputHT.Add("InvokedRun",$InitialValue)
        $Select = "ComputerName","NodeName","NodeStatus","ConfigCopied","InvokedRun","JobID","LogFile","Messages"    
    }
    
    # Arrays
    $Jobs = @()
    $JobResults = @()  

    #endregion Output

    $Host.UI.WriteLine()

}
Process {
    
    $Total = $ComputerName.Count
    $Current = 0

    $Activity = "Copy Ops Chef configuration files to target computer(s)"

    Foreach ($Computer in $ComputerName) {
        
        $Current ++

        # Make sure we aren't going to set off alarms
        $Msg = "Type YES to confirm that computer '$Computer' is *NOT* already registered in `nChef server $ChefServerURL"
        [string]$Continue = Read-Host $Msg 
        If ($Continue -ne "YES") {
            $Msg = "`nERROR: Please remove '$Computer' from Operations Chef/monitoring before running this script!"
            $FGColor = "Red"
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
            Break
        }
        Else {$Host.UI.WriteLine()}

        $Msg = $Computer
        $FGColor = "Yellow"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
        Else {Write-Verbose $Msg}
        
        Write-Progress -Activity $Activity -CurrentOperation $Computer -PercentComplete (($Current/$Total) * 100) 

        $Output = $OutputHT.Clone()
        $Output.ComputerName = $Computer

        # Set flag
        [switch]$Continue = $False

        $Msg = "`tLook up FQDN in $ADDomain"
        $FGColor = "White"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
        Else {Write-Verbose $Msg}
            
        Try {
            # Normalize computername
            If ($Computer -match ".") {$Computer = $Computer.split(".")[0]}

            # Update splat & get AD dnshostname property
            $Param_GetADComputer.Identity = $Computer
            $Target = (Get-ADComputer @Param_GetADComputer).DNSHostName.tolower()
                
            # Update output
            $Output.NodeName = $Target

            # Reset flag
            $Continue = $True
        }
        Catch {
            $Msg = "Can't find computer '$Computer'"
            $ErrorDetails = $_.Exception.Message
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("`tERROR:$Msg`n`t$ErrorDetails")}
            Else {Write-Verbose "`t$Msg"}
            $Output.Messages = "$Msg`n$ErrorDetails"
                
            # Reset flag
            $Continue = $False
        }
        
        If ($Continue.IsPresent) {
            
            # Reset flag
            $Continue = $False
            Try {
                $Msg = "Create remote PSsession"
                $FGColor = "White"
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                Else {Write-Verbose $Msg}
                
                # Update splat & create session
                $Param_NewPSSession.ComputerName = $Target
                $PSSession = New-PSSession @Param_NewPSSession
        
                # Update nodename in arguments parameter hashtable (clone)
                $Param_ICArgs = $Param_ICArgs_Template.Clone()
                $Param_ICArgs.NodeName = $Target

                # Reset flag
                $Continue = $True
            }
            Catch {
                $Msg = "Can't create remote PSSession"
                $ErrorDetails = $_.Exception.Message
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("`tERROR: $Msg`n`t$ErrorDetails")}
                Else {Write-Verbose "`t$Msg`n`t$ErrorDetails"}
                $Output.Messages = "$Msg`n$ErrorDetails"   
                $Results = (New-Object PSObject -Property $Output | Select $Select)
            }

            If ($Continue.IsPresent) {

                # Prompt to confirm; execute 
                $Msg = "Invoke remote scriptblock"
                $FGColor = "White"
                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                Else {Write-Verbose $Msg}

                If ($PsCmdlet.ShouldProcess($Computer,$Msg)) {
                    Try {
                        $Param_InvokeCommand.Scriptblock = $ScriptBlockCreate
                        $Param_InvokeCommand.Session = $PSSession 
                        $Param_InvokeCommand.ArgumentList = $Param_ICArgs
                        $Execute = Invoke-Command @Param_InvokeCommand 
                        
                        If ($Execute) {
                            If ($Execute.ConfigCopied -eq $True) {
                                
                                $Msg = "Remote files created successfully"
                                $FGColor = "Green"
                                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                                Else {Write-Verbose $Msg}
                                
                                $Execute.Messages = $Msg

                                If ($InvokeChefClientRun.IsPresent) {

                                    $Execute | Add-Member -MemberType NoteProperty -Name "InvokedRun" -Value $InitialValue
                                    $Execute | Add-Member -MemberType NoteProperty -Name "JobName" -Value $InitialValue
                                    $Execute | Add-Member -MemberType NoteProperty -Name "JobID" -Value $InitialValue

                                    $JobName = "RunChef_$Computer"

                                    $Param_InvokeCommand.Scriptblock = $ScriptBlockRun
                                    $Msg = "Invoke chef-client run"
                                    $FGColor = "White"
                                    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                                    Else {Write-Verbose $Msg}
                
                                    If ($PSCmdlet.ShouldProcess($Computer,$Msg)) {
                                        Try {
                                            $Run = Invoke-Command @Param_InvokeCommand -AsJob -JobName $JobName
                                            $Msg = "Invoked chef-client run on $Computer as job ID $($Run.ID)"
                                            $FGColor = "Green"
                                            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                                            Else {Write-Verbose $Msg}
                                            
                                            $Execute.InvokedRun = $True
                                            $Execute.JobName = $JobName
                                            $Execute.JobID = $Run.ID
                                        }
                                        Catch {
                                            $Msg = "Remote job execution failed"
                                            $ErrorDetails = $_.Exception.Message
                                            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("`tERROR: $Msg`n`t$ErrorDetails")}
                                            Else {Write-Verbose "`t$Msg`n`t$ErrorDetails"}
                                            
                                            $Execute.InvokedRun = $False
                                            $Execute.Messages += "`n$Msg; $ErrorDetails"
                                        }
                                    } 
                                    Else {
                                        $Msg = "Remote chef-client run cancelled by user"
                                        $Execute.JobName = $Execute.JobID = $Null
                                        $Execute.Messages += "`n$Msg"
                                    }
                                } # end if executing remote job for chef-client
                            }
                            Else {
                                $Msg = "File creation failed"
                                $FGColor = "Red"
                                If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                                Else {Write-Verbose $Msg}
                            }
                            
                            # Wrap it up for output
                            $Results = $Execute
                        }
                        Else {
                            $Msg = "Operation failed"
                            $FGColor = "Red"
                            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                            Else {Write-Verbose "$Msg"}
                            $Output.Messages = $Msg
                            $Results = (New-Object PSObject -Property $Output | Select $Select)
                        }
                    }
                    Catch {
                        $Msg = "File creation failed"
                        $ErrorDetails = $_.Exception.Message
                        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteErrorLine("`tERROR: $Msg`n`t$ErrorDetails")}
                        Else {Write-Verbose "`t$Msg`n`t$ErrorDetails"}
                        $Output.Messages = "$Msg`n$ErrorDetails"   
                        $Results = (New-Object PSObject -Property $Output | Select $Select)
                    }
                    
                } #end confirm command
                Else {
                    $Msg = "File creation cancelled by user"
                    $FGColor = "Red"
                    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,"`t$Msg")}
                    Else {Write-Verbose "`t$Msg"}
                    $Output.ConfigCopied = $False
                    $Output.LogFile = $Null
                    $Output.Messages = $Msg
                    $Results = (New-Object PSObject -Property $Output | Select $Select)
                }
            }
        }
        If ($PSSession) {
            $Null = $PSSession | Remove-PSSession -Verbose:$False -ErrorAction SilentlyContinue
        }            
        Write-Output $Results

    } #end for each computer

    
}
End {
    $Null = Write-Progress -Activity $Activity -Completed -ErrorAction SilentlyContinue -Verbose:$False
    
}

} # End New-PKChefClientConfig
