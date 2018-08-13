#requires -Version 3
Function Get-PKChefNode {
<#
.SYNOPSIS
    Uses knife and invoke-expression to return details about a Chef node (full, default, or Boolean)

.Description
    Uses knife and invoke-expression to return details about a Chef node (full, default, or Boolean)
    Returns a PSObject
    Accepts pipeline input
    Can search for knife.rb and allow for selection if -FindKnife is present

.NOTES 
    Name    : Function_Get-PKChefNode.ps1
    Created : 2016-10-11
    Author  : Paula Kingsley
    Version : 05.00.0000
    History :  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0      - 2016-10-11 - Created script based on old Get-Chefnode
        v2.0.0      - 2016-01-20 - Removed parameter for knife path, changed default to search, other general updates
        v2.1.0      - 2017-03-31 - Added out-gridview -passthru for selection of knife.rb
        v2.2.0      - 2017-06-14 - Added -FindKnife parameter so it will not default to searching 
        v3.0.0      - 2017-06-20 - Changed to use JSON, added more output types, other general improvements
        v04.00.0000 - 2017-11-08 - Added -AsJob, changed to use scriptblock, general cosmetic updates/standardization
        v05.00.0000 - 2018-01-18 - Added OS filter, general updates/improvements


.EXAMPLE
    PS C:\> Get-GNOpsChefNode -Name opstest.domain.local -Method Show -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                 
        ---                   -----                                 
        Name                  {opstest.domain.local}
        Method                Show                                  
        Verbose               True                                  
        Platform              All                                   
        Architecture          All                                   
        SearchField           Name                                  
        Case                  ForceLower                            
        OutputType            Basic                                 
        AsJob                 False                                 
        FindKnifePath         False                                 
        SuppressConsoleOutput False                                 
        ParameterSetName      Name                                  
        PipelineInput         False                                 
        ScriptName            Get-GNOpsChefNode                     
        ScriptVersion         5.0.0                                 


        ACTION: knife node show <name>
        NODENAME: opstest.domain.local

        Name        : opstest.domain.local
        IsPresent   : True
        ChefServer  : https://chef.domain.local/organizations/internal
        FQDN        : opstest.domain.local
        Environment : qa
        Location    : maui
        Platform    : windows
        IsVirtual   : True
        RunList     : {recipe[role_base-chef], recipe[role_base-baremetal], recipe[role_base-os], 
                      recipe[role_base-monitoring]...}
        Roles       : {base-chef, base-baremetal, base-os, base-monitoring}
        Recipes     : {role_base-chef, role_base-chef::default, role_base-baremetal, 
                      role_base-baremetal::default...}
        Tags        : {nomonitor-host, nomonitor-service, devops, [ops_patching_ops_group1]}
        IPv4Address : 10.11.178.23
        NTPServers  : {}
        Uptime      : 30 days 14 hours 39 minutes 45 seconds
        ChefClient  : 12.18.31
        LogDir      : C:/chef/log/client.log
        Command     : knife node show opstest.domain.local -l -F json 2>&1
        Messages    : Node found in 5.77 seconds

.EXAMPLE
    PS C:\> Get-GNOpsChefNode -Name *sql* -Architecture Physical -AsJob -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value                                                                                 
        ---                   -----                                                                                 
        Name                  {*sql*}                                                                              
        Architecture          Physical                                                                              
        OutputType            Basic                                                                                  
        AsJob                 True                                                                                  
        Verbose               True                                                                                                                                                               
        Platform              All                                                                                   
        Method                Search                                                                                
        SearchField           Name                                                                                  
        Case                  ForceLower                                                                            
        FindKnifePath         False                                                                                 
        SuppressConsoleOutput False                                                                                 
        ParameterSetName      Name                                                                                  
        PipelineInput         False                                                                                 
        ScriptName            Get-GNOpsChefNode                                                                     
        ScriptVersion         5.0.0                                                                                 

        ACTION: Search for node (knife search node 'platform:<name>') as PSJob
        NODENAME: *sql*
        VERBOSE: 1 job(s) submitted; run 'Get-Job x | Wait-Job | Receive-Job'

        Id     Name            PSJobTypeName   State         HasMoreData     Location             Command           
        --     ----            -------------   -----         -----------     --------             -------           
        1      GetChef_*sql*   BackgroundJob   Running       True            localhost            ...               

        PS C:\> Get-Job 1 | Receive-Job | Select -Property * -ExcludeProperty RunspaceID

        Name        : sql-prod-17.domain.local
        IsPresent   : True
        ChefServer  : https://chef.domain.local/organizations/sysops
        FQDN        : SQL-PROD-17.domain.local
        Environment : prod
        Location    : santaclara
        Platform    : windows
        IsVirtual   : False
        RunList     : {recipe[role_base-chef], recipe[role_base-baremetal], recipe[role_base-os], 
                        recipe[role_base-monitoring]}
        Roles       : {sql2014, base-chef, base-baremetal, base-os, base-monitoring}
        Recipes     : {msssql::2014, role_base-chef, role_base-chef::default, role_base-baremetal, 
                        role_base-baremetal::default...}
        Tags        : {ops_patching_prod_group2}
        IPv4Address : 10.11.131.3
        NTPServers  : {}
        Uptime      : 16 days 12 hours 02 minutes 48 seconds
        ChefClient  : 12.18.31
        LogDir      : C:/chef/log/client.log
        Command     : knife search node 'name:*sql*' -l -F json 2>&1
        Messages    : Node found in 7.85 seconds

        Name        : sql-dev.domain.local
        IsPresent   : True
        ChefServer  : https://chef.domain.local/organizations/sysops
        FQDN        : sql-dev.domain.local
        Environment : dev
        Location    : tuscon
        Platform    : windows
        IsVirtual   : False
        RunList     : {recipe[role_base-chef], recipe[role_base-baremetal], recipe[role_base-os], 
                        recipe[role_base-monitoring]...}
        Roles       : {sql2014, base-chef, base-baremetal, base-os, base-monitoring}
        Recipes     : {msssql::2014, role_base-chef, role_base-chef::default, role_base-baremetal, 
                        role_base-baremetal::default...}
        Tags        : {devmonitor, ops_patching_dev_group3}
        IPv4Address : 10.11.128.206
        NTPServers  : {}
        Uptime      : 16 days 15 hours 00 minutes 18 seconds
        ChefClient  : 12.18.31
        LogDir      : C:/chef/log/client.log
        Command     : knife search node 'name:*sql*' -l -F json 2>&1
        Messages    : Node found in 7.86 seconds

        Name        : mssql2016test.domain.local
        IsPresent   : True
        ChefServer  : https://chef.domain.local/organizations/sysops
        FQDN        : mssql2016test.domain.local
        Environment : internal
        Location    : albuquerque
        Platform    : windows
        IsVirtual   : False
        RunList     : {recipe[role_base-chef], recipe[role_base-baremetal], recipe[role_base-os], 
                        recipe[role_base-monitoring]...}
        Roles       : {sql2016, base-chef, base-baremetal, base-os, base-monitoring}
        Recipes     : {msssql::2016, role_base-chef, role_base-chef::default, role_base-baremetal, 
                        role_base-baremetal::default...}
        Tags        : {gn_qa, ops_patching_qa_group1, dummy_tag, octopus}
        IPv4Address : 10.11.128.217
        NTPServers  : {}
        Uptime      : 30 days 13 hours 15 minutes 54 seconds
        ChefClient  : 12.18.31
        LogDir      : C:/chef/log/client.log
        Command     : knife search node 'name:*sql*' -l -F json 2>&1
        Messages    : Node found in 7.86 seconds


.EXAMPLE
    PS C:\> Get-GNOpsChefNode -Name webtest* -FindKnifePath -SearchField FQDN -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value            
        ---                   -----            
        Name                  {webtest*}  
        FindKnifePath         True             
        SearchField           FQDN             
        Verbose               True             
        Platform              All              
        Architecture          All              
        Method                Search           
        Case                  ForceLower       
        OutputType            Basic            
        AsJob                 False            
        SuppressConsoleOutput False            
        ParameterSetName      Name             
        PipelineInput         False            
        ScriptName            Get-GNOpsChefNode
        ScriptVersion         5.0.0            

        VERBOSE: Verify/look for path to knife.rb on WORKSTATION7
        VERBOSE: Found 'C:\Users\jbloggs\dropbox\.chef\knife.rb'
        ACTION: knife search node 'fqdn:<name>'
        NODENAME: webtest*
        Operation cancelled for 'webtest*'

.EXAMPLE
    PS C:\> Get-GNOpsChefNode -Name db-* -Platform Linux -Architecture Virtual -AsJob

        ACTION: knife search node 'name:<name> AND os:linux' as PSJob
        NODENAME: db-*

        Id     Name            PSJobTypeName   State         HasMoreData     Location             Command           
        --     ----            -------------   -----         -----------     --------             -------           
        5      GetChef_db-*    BackgroundJob   Running       True            localhost            ...        
    
        Get-Job 5 | Receive-Job | Select Name,Platform,Uptime

        Name                                    Platform Tags                               Uptime               
        ----                                    -------- ----                               ------               
        db-bigdata-dev-503.colo.domain.local    ubuntu   {dba, mapr_cluster_node, mapr_dev} 214 days 10 hours ...
        db-mysql-test-2.domain.local            ubuntu   {dba}                              492 days 13 hours ...
        db-exports-1.domain.local               ubuntu   {}                                 478 days 13 hours ...
        db-oem-grid-1.domain.local              redhat   {dba}                              275 days 10 hours ...
        db-bigdata-dev-504.colo.domain.local    ubuntu   {dba, mapr_cluster_node, mapr_dev} 214 days 10 hours ...
        db-es-node-502.colo.domain.local        ubuntu   {}                                 536 days 14 hours ...
        db-phbooth-prod-1.domain.local          ubuntu   {musiceng}                         309 days 01 hours ...
        db-sass-1.domain.local                  ubuntu   {musiceng}                         683 days 11 hours ...
        db-es-node-504.colo.domain.local        centos   {}                                 536 days 14 hours ...
        db-acr-prod-1.domain.local              ubuntu   {}                                 248 days 08 hours ...
        db-bigdata-dev-en-501.colo.domain.local ubuntu   {dba, mapr_dev}                    413 days 13 hours ...
        
#>

[CmdletBinding(
    DefaultParameterSetName = "Name",
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
param(
    [Parameter(
        ParameterSetName = "Name",
        Position = 0,
        Mandatory=$False,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Node name(s), separated with commas"
    )]
    [Alias("ComputerName","Hostname","FQDN","DNSHostName")]
    [string[]]$Name,

    [Parameter(
        Mandatory=$False,
        HelpMessage = "Platform for search (windows, ubuntu, redhat, all)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Windows","Ubuntu",'RedHat',"Linux","All")]
    [string]$Platform = "All",

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Physical, Virtual, or All"
    )]
    [ValidateSet("All","Physical","Virtual")]
    [string] $Architecture = "All",

    [Parameter(
        ParameterSetName = "Name",
        Mandatory=$False,
        HelpMessage = "Use 'knife node search' instead of 'knife node show'"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Search","Show")]
    [string] $Method = "Search",

    [Parameter(
        ParameterSetName = "Name",
        Mandatory=$False,
        HelpMessage = "Search field (Name, FQDN) - ignored if method is 'Show'"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Name","FQDN")]
    [string] $SearchField = "Name",

    [Parameter(
        ParameterSetName = "Name",
        Mandatory=$false,
        HelpMessage = "Case for search text (ForceUpper, ForceLower, NoChange)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("ForceUpper","ForceLower","NoChange")]
    [string] $Case = "ForceLower",

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Default, Full or Boolean output"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Basic","Full","Boolean")]
    [string]$OutputType = "Basic",

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Run as PSJob"
    )]
    [Switch] $AsJob,

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Look for knife.rb (useful if not in standard 'c:\users\jbloggs\.chef')"
    )]
    [Alias("FindKnife")]
    [Switch] $FindKnifePath,

    [Parameter(
        Mandatory=$False,
        HelpMessage="Suppress non-verbose/non-error console output"
    )]
    [Switch]$SuppressConsoleOutput

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "05.00.0000"

    # Show our settings
    $SOurce = $PSCmdlet.ParameterSetName
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("Name")) -and (-not $Name)
    $CurrentParams = $PSBoundParameters
    $MyInvocation.MyCommand.Parameters.keys | Where {$CurrentParams.keys -notContains $_} | 
        Where {Test-Path variable:$_}| Foreach {
            $CurrentParams.Add($_, (Get-Variable $_).value)
        }
    $CurrentParams.Add("ParameterSetName",$Source)
    $CurrentParams.Add("PipelineInput",$PipelineInput)
    $CurrentParams.Add("ScriptName",$MyInvocation.MyCommand.Name)
    $CurrentParams.Add("ScriptVersion",$Version)
    Write-Verbose "PSBoundParameters: `n`t$($CurrentParams | Format-Table -AutoSize | out-string )"

    # Preferences 
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "Continue"

    #region Look for knife 

    If ($FindKnifePath.IsPresent) {
        Try {
            $Msg =  "Verify/look for path to knife.rb on $Env:ComputerName"
            Write-Verbose $Msg
            $Activity = $Msg
            
            $KnifePath1 = "$env:userprofile\.chef"
            $Knifepath2 = $env:userprofile
            $Knifepath3 = $env:SystemDrive

            # Search the default Chef directory in user's profile
            Write-Progress -Activity $Activity -CurrentOperation $KnifePath1
                
            If (-not ($Knife = (Get-ChildItem -Path "$env:userprofile\.chef" -Filter "knife.rb" -ErrorAction SilentlyContinue -Verbose:$False).FullName)) {
                
                # Search the entire profile directory
                Write-Progress -Activity $Activity -CurrentOperation $KnifePath2

                If (-not ($Knife = (Get-ChildItem -Path "$env:userprofile" -Recurse -Filter "knife.rb" -ErrorAction SilentlyContinue -Verbose:$False).FullName | Out-GridView -Title "Please select a file" -OutputMode Single)) {    
                    
                    # Look everywhere    
                    Write-Progress -Activity $Activity -CurrentOperation $KnifePath3

                    If (-not ($Knife = Invoke-Expression -Command "cmd /c where knife.rb" -ErrorAction SilentlyContinue -Verbose:$False)) {
                        $Msg = "'knife.rb' not found on $Env:ComputerName"
                        $Host.UI.WriteErrorLine("ERROR: $Msg")
                        Break
                    }
                }
            }
            If ($Knife) {
                $Msg = "Found '$Knife'"
                Write-Verbose $Msg
                $KnifeParent = (Split-Path -Path $Knife @StdParams)  
                $BackupLocation = Get-Location 
                $Null = Set-Location -Path $KnifeParent @StdParams
            }
        }
        Catch {
            $Msg = "Error checking knife.rb path"
            $ErrorDetails = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
            Break
        }
    }

    #endregion Look for knife 

    #region search details

    Switch ($Source) {
        Name {
            $SearchBy = $SearchField.ToLower()
        }
    }
    If ($Platform) {
        Switch ($Platform) {
            All {$OS = $Null}
            Default {$OS = $Platform.ToLower()}
        }
    }

    #endregion search details

    #region Functions

    #Function to create string for invoke-expression
    Function CreateExpression {
        [cmdletbinding()]
        Param($NodeName,$NameField ="name",$OS,$GetMethod = "search")
        $Params = $NodeName,$NameField,$OS,$GetMethod
        $Count = 0
        $Params | Where-Object {$_} | Foreach-Object {$Count ++}

        If ($Count -gt 0){
            If ($GetMethod -eq "show") {
                If ($NodeName) {[string]$Expr = "knife node show $NodeName -l -F json 2>&1"}
            }
            Else {
                $SearchArr = @()
                If ($NodeName) {
                    Switch ($NameField) {
                        Name {$nodefield = "name"}
                        FQDN {$nodefield = "fqdn"}
                    }
                    $SearchArr += "$nodefield`:$NodeName"
                }
                If ($OS) {
                    If ($OS -eq "linux") {
                        $SearchArr += "os:$OS"
                    }    
                    Else {$SearchArr += "platform:$OS"}
                    
                }
                $SearchStr = "'$($SearchArr -join(" AND "))'"
                $Expr = "knife search node $SearchStr -l -F json 2>&1"
            }
            Write-Output $Expr 
        }
        Else {
            $Msg = "At least one parameter is required"
            #$Host.UI.WriteErrorLine($Msg)
            Write-Verbose $Msg
        }
    }

    #endregion Functions
    
    #region Scriptblock for Invoke-Command or Start-Job
    
    $ScriptBlock = {

        Param($Computer,$Expression,$OutputType,$Method,$Architecture)
            
        #region PSObject for output
        $InitialValue = "Error"
        $OutputTemplate = New-Object PSObject -Property ([ordered] @{
            Name            = $InitialValue
            IsPresent       = $InitialValue
            ChefServer      = $InitialValue
            FQDN            = $InitialValue
            Environment     = $InitialValue
            Location        = $InitialValue
            Platform        = $InitialValue
            IsVirtual       = $InitialValue            
            RunList         = $InitialValue
            Roles           = $InitialValue
            Recipes         = $InitialValue
            Tags            = $InitialValue
            OSName          = $InitialValue
            OSVersion       = $InitialValue
            IPv4Address     = $InitialValue
            Gateway         = $InitialValue
            #SubnetMask      = $InitialValue
            DNSServers       = $InitialValue
            SearchDomains   = $InitialValue
            NIC             = $InitialValue
            #NetConnectionID = $InitialValue
            #MACAddress      = $InitialValue
            Manufacturer    = $InitialValue
            Model           = $InitialValue
            CPU             = $InitialValue
            MemoryGB        = $InitialValue
            HardDisk        = $InitialValue
            TimeZone        = $InitialValue
            NTPServers      = $InitialValue
            Uptime          = $InitialValue
            ChefClient      = $InitialValue
            LogDir          = $InitialValue
            Command         = $Expression
            Messages        = $InitialValue
        })
        
        # Property selection
        $AllProps = $OutputTemplate.PSObject.Properties.Name
        Switch ($OutputType) {
            Full {
                $Select = $AllProps
            }
            Boolean {
                $Props = @('Name','IsPresent')
                $Select = $AllProps | Where-Object {$_ -in $Props}
            }
            Basic {
                $Props = @('Gateway','DNSServers','NIC','SearchDomains','OSName','OSVersion','Manufacturer','Model','CPU','MemoryGB','HardDisk','Timezone')
                $Select = $AllProps | Where-Object {$_ -notin $Props}
            }                    
        }
        
        # Final answer
        $Results = @()
        
        # For proper capitalization
        $TextInfo = (Get-Culture).TextInfo
    
        #endregion PSObject for output

        function Invoke-NativeExpression {
            [cmdletbinding()]
            param (
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
            [string]$Expression
            )
            process{
                $executable,$arguments = $expression -split ' '
                $arguments = $arguments | foreach {"'$_'"}
                $arguments = $arguments -join ' '
                $command = $executable + ' ' + $arguments
                if ($command){
                    #Write-Verbose "Invoking '$command'"
                    Invoke-Expression -command $command
                }
            }
        } #end function

        Try {
            If ($Computer) {
                $OutputTemplate.Name = $Computer
            }
            $StartTime = Get-Date
            $GetJSON = (Invoke-NativeExpression -Expression $Expression -ErrorAction Stop) 
            $GetNode = ($GetJSON | ConvertFrom-Json -ErrorAction Stop) # This stopped working in pipeline
            
            If ($GetNode.Results -eq 0) {
                $Msg = "Node not found"
                $OutputTemplate.IsPresent = $False
                $OutputTemplate.Messages = $Msg
                $Results += $OutputTemplate
            }

            Else {
                Switch ($Method) {
                    Search {$Found = $GetNode.Rows}
                    Show {$Found = $GetNode}
                }

                Foreach ($Node in $Found) {
                        
                    $EndTime = Get-Date
                    $ElapsedTime = $EndTime - $StartTime
                    $Msg = "Node found in $("{0:N}" -f $ElapsedTime.TotalSeconds) seconds"

                    If ($Node.automatic.kernel.name -eq "linux") {$OSPlatform = $Node.automatic.kernel.name}
                    Elseif ($Node.automatic.platform -eq "windows") {$OSPlatform = $Node.automatic.platform}

                    $Output = $OutputTemplate.PSObject.Copy()
                        
                    $Output.Name         = $Node.Name
                    $Output.IsPresent    = $True
                    $Output.Environment  = $Node.chef_environment
                    $Output.Platform     = $Node.Automatic.Platform
                    $Output.FQDN         = $Node.automatic.FQDN
                    $Output.Location     = $Node.automatic.location
                    $Output.IPv4Address  = $node.automatic.ipaddress | Where-Object {$_ -match "\d\."}
                    $Output.RunList      = $Node.run_list 
                    $Output.Uptime       = $Node.automatic.uptime
                    $Output.NTPServers   = $Node.Default.NTP.Servers
                    $Output.Recipes      = $Node.automatic.recipes
                    $Output.Tags         = $Node.normal.tags
                    $Output.ChefClient   = $Node.default.omnibus_updater.version
                    $Output.ChefServer   = $Node.default.chef_client.config.chef_server_url
                    $Output.LogDir       = $Node.default.chef_client.config.log_location
                    $Output.Messages     = $Msg

                    Switch ($OSPlatform){
                        default {
                            $Output.Roles = $Node.automatic.roles
                            If ($Node.automatic.virtualization.role -eq "guest") {
                                $Output.IsVirtual = $True
                            }
                            Else {
                                $Output.IsVirtual = $False
                            }
                        }
                        windows {
                            If ($Node.automatic.kernel.cs_info.hypervisor_present -eq $True) {
                                $Output.IsVirtual = $True
                            }
                            Else {
                                $Output.IsVirtual = $False
                            }
                            $Output.Roles = $Node.normal.roles
                        }
                    }
                    
                    If ($OutputType -eq "Full") {
                        
                        # Common attributes
                        $Output.CPU        = @{Count=$Node.automatic.cpu.total;Cores=$Node.automatic.cpu.cores}
                        $Output.HardDisk   = $Node.automatic.filesystem
                        $Output.Timezone   = $Node.automatic.time.timezone
                        $Output.Gateway    = $Node.automatic.Network.default_gateway

                        # OS-specific attributes
                        Switch ($OSPlatform){

                            default {
                                
                                $Output.OSName       = $Node.Automatic.lsb.description
                                $Output.OSVersion    = $Node.Automatic.platform_version
                                $Output.Manufacturer = $Node.automatic.dmi.system.manufacturer
                                $Output.Model        = $Node.automatic.dmi.system.product_name
                                $Output.MemoryGB     = [math]::round($Node.automatic.memory.total /1gb)
                                
                                # Get all DNS servers
                                $DNSArr = $Node.default.resolver.nameservers
                                $Output.DNSServers = $DNSArr
                                
                                # Get all search domains
                                $SearchDomains = $Node.default.search_path
                                $Output.SearchDomains = $SearchDomains

                                # Variables and arrays for IP/etc
                                $IPAddress = $Gateway = $SubnetMask = $DNS = $Adapter = $AdapterAlias = $MacAddress = @()
                                $AdapterArr = @()
                                $IPArr = @()
                                
                                # Get all NIC interface names
                                $NetProps = (($node.automatic.Network.Interfaces).PSObject.Members | Where-Object {$_.membertype -eq "NoteProperty"}).Name
                                
                                Foreach ($Netprop in $NetProps) {
                                    
                                    $Network = $Node.automatic.Network.interfaces.$NetProp
                                    $IPv4 = ($Network.Addresses | Get-Member -MemberType NoteProperty) | Where-Object {$_.Name -match "\d\."}
                                    $MAC = (($Network.Addresses | Get-Member -MemberType NoteProperty) | Where-Object {$_.Name -match "^\d{2}\:"}).Name
                                    $IPAddress = $IPV4.Name
                                    $SubnetMask = ($Network.Addresses.$($IPv4.Name)).netmask
                                    
                                    # Create new object to return  IP / subnet as a collection
                                    $IPObj = New-Object PSObject 
                                    $IPObj | Add-Member -MemberType NoteProperty -Name IPv4Address -Value $IPAddress
                                    $IPObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
                                    $IPArr += $IPObj

                                    # Create new object to return all adapter info
                                    $AdapterObj = New-Object PSObject 
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name Alias -Value $Netprop
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MAC
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
                                    $AdapterArr += $AdapterObj
                                }

                                $Output.IPv4Address = $IPArr
                                $Output.NIC = $AdapterArr
                            }
                            
                            windows {
                                
                                $Output.OSName       = $Node.Automatic.kernel.os_info.caption
                                $Output.OSVersion    = $Node.Automatic.kernel.os_info.version
                                $Output.Manufacturer = $Node.automatic.kernel.cs_info.manufacturer
                                $Output.Model        = $Node.automatic.kernel.cs_info.model
                                $Output.MemoryGB     = [math]::round($Node.automatic.kernel.cs_info.total_physical_memory /1gb)
                               
                                # Variables and arrays for IP/etc
                                $IPAddress = $Gateway = $SubnetMask = $DNS = $Adapter = $AdapterAlias = $MacAddress = @()
                                $AdapterArr = @()
                                $IPArr = @()
                                $DNSArr = @()

                                # Get all NIC interface names
                                $NetProps = (($node.automatic.Network.Interfaces).PSObject.Members | Where-Object {$_.membertype -eq "NoteProperty"}).Name

                                Foreach ($Netprop in $NetProps) {
                                    
                                    $Network = $Node.automatic.Network.interfaces.$NetProp
                                    $IPv4 = ($Network.Addresses | Get-Member -MemberType NoteProperty)| Where-Object {$_.Name -match "\d\."}
                                    $IPAddress = $IPv4.Name
                                    $SubnetMask = ($Network.Addresses.$($IPv4.Name)).netmask
                                    If ($DNSServers = $Network.configuration.dns_server_search_order) {$DNSArr += $DNSServers}

                                    # Create new object to return  IP / subnet / dns as a collection  
                                    $IPObj = New-Object PSObject 
                                    $IPObj | Add-Member -MemberType NoteProperty -Name IPv4Address -Value $IPAddress
                                    $IPObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
                                    $IPObj | Add-Member -MemberType NoteProperty -Name DNSServers -Value $DNSServers
                                    $IPObj | Add-Member -MemberType NoteProperty -Name DNSSearchOrder -Value $Network.configuration.dns_domain_suffix_search_order
                                    $IPArr += $IPObj
                                    
                                    # Create new object to return all adapter info
                                    $AdapterObj = New-Object PSObject 
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name Alias -Value $Network.instance.net_connection_id
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name Adapter -Value $Network.instance.Name
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $Network.instance.mac_address
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
                                    $AdapterObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
                                    $AdapterArr += $AdapterObj

                               } #end foreach adapter
                               
                               $Output.NIC = $AdapterArr
                               $Output.IPv4Address = $IPArr.IPv4Address
                               $Output.DNSServers = ($DNSArr | Select -Unique)
                               $Output.SearchDomains = ($IPArr.DNSSearchOrder | Select -Unique)
                                
                            }
                        }
                    } #end if output type is full

                    # Add to output array
                    $Results += $Output

                } #end foreach

            } #end if results
        }
        catch {
            $Msg = "Operation failed"
            $ErrorDetails = $_.Exception.Message
            $OutputTemplate.Messages = "$Msg`n$ErrorDetails"
            $Results += $OutputTemplate
        }

        # Return psobject
        Switch ($Architecture) {
            All {}
            Virtual {$Results = $Results | Where-Object {$_.IsVirtual -eq $True}}
            Physical {$Results= $Results | Where-Object {$_.IsVirtual -ne $True}}
        }
        Write-Output ($Results | Select $Select)
        
    } #end scriptblock
    
    #endregion Scriptblock for Invoke-Command or Start-Job

    #region Splats

    # Activity for write-progress
    Switch ($Method) {
        Show {
            $ActivityStr = "knife node show <name>"
            If ($Platform -ne "all") {$ActivityStr += " 'platform:$OS'" }
            $Activity = "Show node ($ActivityStr)"   
        }
        Search {
            
            $ActivityStr = "knife search node '$Searchby`:<name>"
            Switch ($Platform) {
                All {$ActivityStr += "'"}
                Linux {$ActivityStr += " AND os:$OS'"}
                Default {$ActivityStr += " AND platform:$OS'"}
            }
        }
    }
    $Activity = $ActivityStr


    # General purpose splat
    $StdParams = @{}
    $StdParams = @{
        ErrorAction = "Stop"
        Verbose = $False
    }

    # Splat for Invoke-Command or Start-Job
    $Param_GetNode = @{}
    $Param_GetNode = @{
        Scriptblock  = $ScriptBlock
        ArgumentList = $Null
        ErrorAction  = "Stop"
        Verbose      = $False
    }

    # If running as job
    If ($AsJob.IsPresent) {
        $Activity = "$Activity as PSJob"
        $Param_GetNode.Add("Name",$Null)
        $Jobs = @()
    }

    #endregion Splats
    
    # Regular expressions for hostname and FQDN
    #$Hostname = "(?=^.{1,254}$)(^(?:(?!\d+\.|-)[a-z0-9_\-]{1,63}(?<!-)\.?)+(?:[a-z]{2,})$)"
    #$FQDN = "(?!\/\/)([a-z0-9-]*\.){2,}[a-z0-9-]*(?!<\/)"
    #$Hostname = "^([a-zA-Z0-9-])+[*]$"
    # [System.Uri]::CheckHostName($Computer)
    
    # Console output
    $BGColor = $host.UI.RawUI.BackgroundColor
    $Msg = "ACTION: $Activity"
    $FGColor = "Yellow"
    If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
    Else {Write-Verbose $Msg}


}
Process {
    

    If ($CurrentParams.Name) {
    
        # Write-Progress and start time
        $Total = $Name.Count
        $current = 0
        $StartTime = Get-Date 

        Foreach ($Computer in $Name) {
            
            # Write-Progress update
            $Current ++
            $CurrentOp = $Computer
            $percentComplete = ($Current / $Total * 100)
            Write-Progress -Activity $Activity -CurrentOperation $CurrentOp -PercentComplete $percentComplete

            # Console output
            $Msg = "NODENAME: $Computer"
            $FGColor = "Cyan"
            If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
            Else {Write-Verbose $Msg}

            # Check name syntax
            Switch ($Method) {
                Show {
                    If ($Computer -match "\*") {
                        $Msg = "Wildcard name ('$Computer') is incompatible with 'knife node show' - please try 'search' instead"
                        $Host.UI.WriteErrorLine("ERROR: $Msg")
                        Break
                    }
                }
                Search {
                    If (($Computer -notmatch "\.") -and ($Computer -notmatch "\*")) {
                        $Msg = "Computername '$Computer' may not match nodename syntax of FQDN; consider '$Computer* or '$Computer.*'"
                        Write-Warning $Msg
                    }
                }
            }

            # Set the case
            Switch ($Case){
                ForceUpper {$Computer = $Computer.ToUpper()}
                ForceLower {$Computer = $Computer.ToLower()}
                NoChange   {}
            }

            # Create the expression
            $Param_Expression = @{}
            $Param_Expression = @{
                NodeName  = $Computer
                NameField = $SearchField
                GetMethod = $Method
            }
            If ($OS) {
                $Param_Expression.Add("OS",$OS)
            }
            $Expression = CreateExpression @Param_Expression
                
             
            # Create arguments for scriptblock and add to splat
            $ArgumentList = $Computer,$Expression,$OutputType,$Method,$Architecture
            $Param_GetNode.ArgumentList = $ArgumentList

            # Confirm & execute
            $ConfirmMsg = "`n`nExecute the following command"
            If ($AsJob.IsPresent) {$ConfirmMsg += " as a PowerShell job"}
            $ConfirmMsg += ":`n`n`t'$Expression'`n`n"
            
            If ($PSCmdlet.ShouldProcess($Null,$ConfirmMsg)) {
                If ($AsJob.IsPresent) {
                    $Param_GetNode.Name = "GetChef_$Computer"
                    $Invoke = Start-Job @Param_GetNode
                    $Msg = "Created job $($Invoke.ID)"
                    $Jobs += $Invoke
                }
                Else {
                    $Invoke = Invoke-Command @Param_GetNode
                    Write-Output $Invoke
                }
            }
            Else {
                $Msg = "Operation cancelled for '$Computer'"
                $Host.UI.WriteErrorLine($Msg)
            }
                
        } #end for each computer
    
    } #if computer provided

    Else {
        
        $Msg = "Platform: $Platform"
        $FGColor = "Cyan"
        If (-not $SuppressConsoleOutput.IsPresent) {$Host.UI.WriteLine($FGColor,$BGColor,$Msg)}
        Else {Write-Verbose $Msg}
        
        # Create the expression
        $Param_Expression = @{}
        $Param_Expression = @{
            OS  = $OS
            GetMethod = $Method
        }
            
        $Expression = CreateExpression @Param_Expression
        
        # Arguments for scriptblock
        $ArgumentList = $Computer,$Expression,$OutputType,$Method 
        $Param_GetNode.ArgumentList = $ArgumentList

        $CurrentOp = "$Platform nodes"
        Write-Progress -Activity $Activity -CurrentOperation $CurrentOp 

        If ($PSCmdlet.ShouldProcess($Computer,$Activity)) {
            If ($AsJob.IsPresent) {
                $Param_GetNode.Name = "GetChef_$Platform"
                $Invoke = Start-Job @Param_GetNode
                $Msg = "Created job $($Invoke.ID)"
                $Jobs += $Invoke
            }
            Else {
                $Invoke = Invoke-Command @Param_GetNode
            }
        }
        Else {
            $Msg = "Operation cancelled by user"
            $Host.UI.WriteErrorLine($Msg)
        }
    }
       
}
End {

    If ($FindKnifePath.IsPresent) {
        If ($BackupLocation.Path -ne $KnifeParent) {
            Set-Location $BackupLocation -Verbose:$False -ErrorAction SilentlyContinue
        }
    }

    Write-Progress -Activity $Activity -Completed

    If ($AsJob.IsPresent) {
        If ($Jobs.Count -gt 0) {
            $Msg = "$($Jobs.Count) job(s) submitted; run 'Get-Job x | Wait-Job | Receive-Job'"
            Write-Verbose $Msg
            $Jobs | Get-Job @StdParams
        }
        Else {
            $Msg = "No jobs running"
            $Host.UI.WriteErrorLine($Msg)
        }
    }
    
}
} #end Get-PKChefNode



