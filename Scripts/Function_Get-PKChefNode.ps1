#requires -Version 3
Function Get-PKChefNode {
<#
.Synopsis
    Uses knife and invoke-expression to return details about a Chef node (full, default, or Boolean)

.Description
    Uses knife and invoke-expression to return details about a Chef node (full, default, or Boolean)
    Returns a PSObject
    Accepts pipeline input
    Can search for knife.rb and allow for selection if -FindKnife is present

.NOTES 
    Name    : Function_Get-PKChefNode.ps1
    Version : 3.0.0
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v1.0.0 - 2016-10-11 - Created script based on old Get-Chefnode
        v2.0.0 - 2016-01-20 - Removed parameter for knife path, changed default to search, other general updates
        v2.1.0 - 2017-03-31 - Added out-gridview -passthru for selection of knife.rb
        v2.2.0 - 2017-06-14 - Added -FindKnife parameter so it will not default to searching 
        v3.0.0 - 2017-06-20 - Changed to use JSON, added more output types, other general improvements


.EXAMPLE
    PS C:\> Get-PKChefnode -Name ops-testvm-3 -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value             
        ---                   -----             
        Name                  {ops-testvm-3}    
        Verbose               True              
        Method                Search            
        SearchField           FQDN              
        Case                  ForceLower        
        OutputType            Default           
        FindKnifePath         False             
        PipelineInput         True              
        ScriptName            Get-PKChefNode 
        ScriptVersion         3.0.0             


        VERBOSE: Invoke command: 'knife search node 'fqdn:ops-testvm-3.*' -l -F json 2>&1'
        VERBOSE: 1 matching node(s) found in 4 second(s)
        VERBOSE: ops-testvm-3.internal.domain.com

        Name        : ops-testvm-3.internal.domain.com
        IsPresent   : True
        ChefServer  : https://chef.internal.domain.com/organizations/PK
        FQDN        : ops-testvm-3.internal.domain.com
        Environment : constantinople
        Location    : constantinople
        Platform    : windows
        IPAddress   : 10.11.178.23
        RunList     : {recipe[role_base-chef], recipe[role_base-baremetal], recipe[role_base-os], recipe[role_base-monitoring]...}
        Roles       : {base-chef, base-baremetal, base-os, base-monitoring}
        Recipes     : {role_base-chef, role_base-chef::default, role_base-baremetal, role_base-baremetal::default...}
        Tags        : {nomonitor-host, nomonitor-service}
        Uptime      : 12 days 08 hours 25 minutes 07 seconds
        ChefClient  : 12.18.31
        LogDir      : C:/chef/log/client.log
        Messages    : 

.EXAMPLE
    PS C:\> Get-PKChefnode -Name db-sqlprod* -OutputType Boolean -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value             
        ---                   -----             
        Name                  {db-sqlprod*}   
        OutputType            Boolean           
        Verbose               True              
        Method                Search            
        SearchField           FQDN              
        Case                  ForceLower        
        FindKnifePath         False             
        SuppressConsoleOutput False             
        ParameterSetName      __AllParameterSets
        PipelineInput         True              
        ScriptName            Get-PKChefNode 
        ScriptVersion         3.0.0             


        VERBOSE: Invoke command: 'knife search node 'fqdn:db-delph-trg*.*' -l -F json 2>&1'
        VERBOSE: 15 matching node(s) found in 5 second(s)
        VERBOSE: db-sqlprod-14.internal.domain.com
        VERBOSE: db-sqlprod-8.internal.domain.com
        VERBOSE: db-sqlprod-6.internal.domain.com
        VERBOSE: db-sqlprod-7.internal.domain.com
        VERBOSE: db-sqlprod-5.internal.domain.com
        VERBOSE: db-sqlprod-10.internal.domain.com
        VERBOSE: db-sqlprod-9.internal.domain.com
        VERBOSE: db-sqlprod-1.internal.domain.com
        VERBOSE: db-sqlprod-3.internal.domain.com
        VERBOSE: db-sqlprod-15.internal.domain.com
        VERBOSE: db-sqlprod-4.internal.domain.com
        VERBOSE: db-sqlprod-11.internal.domain.com
        VERBOSE: db-sqlprod-13.internal.domain.com
        VERBOSE: db-sqlprod-12.internal.domain.com
        VERBOSE: db-sqlprod-2.internal.domain.com

        Name                                    IsPresent
        ----                                    ---------
        db-sqlprod-14.internal.domain.com        True
        db-sqlprod-8.internal.domain.com         True
        db-sqlprod-6.internal.domain.com         True
        db-sqlprod-7.internal.domain.com         True
        db-sqlprod-5.internal.domain.com         True
        db-sqlprod-10.internal.domain.com        True
        db-sqlprod-9.internal.domain.com         True
        db-sqlprod-1.internal.domain.com         True
        db-sqlprod-3.internal.domain.com         True
        db-sqlprod-15.internal.domain.com        True
        db-sqlprod-4.internal.domain.com         True
        db-sqlprod-11.internal.domain.com        True
        db-sqlprod-13.internal.domain.com        True
        db-sqlprod-12.internal.domain.com        True
        db-sqlprod-2.internal.domain.com         True


.EXAMPLE
    PS C:\> Get-ADComputer ops-testvm-3 | Get-PKChefNode -OutputType Full -FindKnifePath -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key                   Value             
        ---                   -----             
        OutputType            Full              
        FindKnifePath         True              
        Verbose               True              
        Name                                    
        Method                Search            
        SearchField           FQDN              
        Case                  ForceLower        
        PipelineInput         True              
        ScriptName            Get-PKChefNode 
        ScriptVersion         3.0.0             


        VERBOSE: Verify/look for path to knife.rb on WORKSTATION17
        VERBOSE: Found 'C:\Users\jbloggs\Dropbox\.chef\knife.rb'
        VERBOSE: Invoke command: 'knife search node 'fqdn:ops-testvm-3.*' -l -F json 2>&1'
        VERBOSE: 1 matching node(s) found in 4 second(s)
        VERBOSE: ops-testvm-3.internal.domain.com

        Name            : ops-testvm-3.internal.domain.com
        IsPresent       : True
        ChefServer      : https://chef.internal.domain.com/organizations/PK
        FQDN            : ops-testvm-3.internal.domain.com
        Environment     : constantinople
        Location        : constantinople
        Platform        : windows
        RunList         : {recipe[role_base-chef], recipe[role_base-baremetal], 
                          recipe[role_base-os], recipe[role_base-monitoring]...}
        Roles           : {base-chef, base-baremetal, base-os, base-monitoring}
        Recipes         : {role_base-chef, role_base-chef::default, 
                          role_base-baremetal, role_base-baremetal::default...}
        Tags            : {nomonitor-host, nomonitor-service}
        OSName          : Microsoft Windows Server 2012 R2 Datacenter
        OSVersion       : 6.3.9600
        IPAddress       : 10.11.13.14
        Gateway         : 10.11.13.1
        SubnetMask      : 255.255.254.0
        DNS             : {10.11.142.250, 10.8.142.250}
        AdapterName     : vmxnet3 Ethernet Adapter
        NetConnectionID : Ethernet0
        MACAddress      : 00:50:56:96:B6:CF
        Manufacturer    : VMware, Inc.
        Model           : VMware Virtual Platform
        IsVirtual       : True
        CPU             : {Count, Cores}
        MemoryGB        : 8
        HardDisk        : @{C:=; D:=}
        TimeZone        : Pacific Daylight Time
        Uptime          : 6 hours 40 minutes 28 seconds
        ChefClient      : 12.18.31
        LogDir          : C:/chef/log/client.log
        Messages        : 

.EXAMPLE
    PS C:\>Get-PKChefNode -Name ops-bastion-2,foo
        ERROR: Node 'foo' not found

        Name        : ops-bastion-2.internal.domain.com
        IsPresent   : True
        ChefServer  : https://chef.internal.domain.com/organizations/PK
        FQDN        : ops-bastion-2.internal.domain.com
        Environment : constantinople
        Location    : constantinople
        Platform    : linux
        IPAddress   : 10.11.178.16
        RunList     : {role[base-chef], role[base-os], role[base-baremetal], role[base-monitoring]...}
        Roles       : 
        Recipes     : {role_base-chef, role_base-chef::default, role_base-os, role_base-os::default...}
        Tags        : {}
        Uptime      : 118 days 03 hours 55 minutes 22 seconds
        ChefClient  : 12.18.31
        LogDir      : /var/log/chef/client.log
        Messages    : 

        Name        : foo
        IsPresent   : False
        ChefServer  : Error
        FQDN        : Error
        Environment : Error
        Location    : Error
        Platform    : Error
        IPAddress   : Error
        RunList     : Error
        Roles       : Error
        Recipes     : Error
        Tags        : Error
        Uptime      : Error
        ChefClient  : Error
        LogDir      : Error
        Messages    : Node 'foo' not found


#>

[CmdletBinding()]
param(
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Node name(s), separated with commas"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("ComputerName","Hostname","FQDN","DNSHostName")]
    [string[]]$Name,

    [Parameter(
        Mandatory=$False,
        HelpMessage = "Use 'knife node search' instead of 'knife node show'"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Search","Show")]
    [string] $Method = "Search",

    [Parameter(
        Mandatory=$False,
        HelpMessage = "Search field (Name or FQDN) - ignored if method is 'Show'"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Name","FQDN")]
    [string] $SearchField = "Name",

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Case for nodename (ForceUpper, ForceLower, NoChange)"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("ForceUpper","ForceLower","NoChange")]
    [string] $Case = "ForceLower",

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Default, Full or Boolean"
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Default","Full","Boolean")]
    [string]$OutputType = "Default",

    [Parameter(
        Mandatory=$false,
        HelpMessage = "Look for knife.rb (useful if not in standard 'c:\users\jbloggs\.chef')"
    )]
    [Alias("FindKnife")]
    [Switch] $FindKnifePath

)
Begin {
    
    # Current version (please keep up to date from comment block)
    [version]$Version = "3.0.0"

    # Detect pipeline input
    $PipelineInput = (-not $PSBoundParameters.ContainsKey("Name")) -and (-not $Name)
   
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

    # Helper function
    # From http://www.powershellmagazine.com/2013/01/02/calling-native-commands-from-powershell/
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
                Write-Verbose "Invoking '$command'"
                Invoke-Expression -command $command
            }
        }
    } #end function

    $Results = @()
    $InitialValue = "Error"
    
    Switch ($OutputType) {
        Boolean {}
        Default {
            $OutputTemplate = New-Object PSObject -Property ([ordered] @{
                Name        = $InitialValue
                IsPresent   = $InitialValue
                ChefServer  = $InitialValue
                FQDN        = $InitialValue
                Environment = $InitialValue
                Location    = $InitialValue
                Platform    = $InitialValue
                IPAddress   = $InitialValue
                RunList     = $InitialValue
                Roles       = $InitialValue
                Recipes     = $InitialValue
                Tags        = $InitialValue
                Uptime      = $InitialValue
                ChefClient  = $InitialValue
                LogDir      = $InitialValue
                Messages    = $InitialValue
            })
        
        }
        Full {
            $OutputTemplate = New-Object PSObject -Property ([ordered] @{
                Name            = $InitialValue
                IsPresent       = $InitialValue
                ChefServer      = $InitialValue
                FQDN            = $InitialValue
                Environment     = $InitialValue
                Location        = $InitialValue
                Platform        = $InitialValue
                RunList         = $InitialValue
                Roles           = $InitialValue
                Recipes         = $InitialValue
                Tags            = $InitialValue
                OSName          = $InitialValue
                OSVersion       = $InitialValue
                IPAddress       = $InitialValue
                Gateway         = $InitialValue
                SubnetMask      = $InitialValue
                DNS             = $InitialValue
                AdapterName     = $InitialValue
                NetConnectionID = $InitialValue
                MACAddress      = $InitialValue
                Manufacturer    = $InitialValue
                Model           = $InitialValue
                IsVirtual       = $InitialValue
                CPU             = $InitialValue
                MemoryGB        = $InitialValue
                HardDisk        = $InitialValue
                TimeZone        = $InitialValue
                Uptime          = $InitialValue
                ChefClient      = $InitialValue
                LogDir          = $InitialValue
                Messages        = $InitialValue
            })
        }
    } # end switch for output type

}
Process {
    
    $Total = $Name.Count
    $current = 0
    $StartTime = Get-Date 

    Foreach ($Computer in $Name) {
        
        $Current ++
        $CurrentOp = $Computer

        Switch ($SearchField) {
            Name {
                If ($Computer -notmatch ".") {
                    $Msg = "Computername '$Computer' may not match nodename syntax of FQDN"
                    Write-Warning $Msg
                }
                $Case = "ForceLower"
            }
            FQDN {
                If ($Computer -match ".") {
                    $Computer = $Computer.Split(".")[0]
                }
            }
        }
        Switch ($Case){
            ForceUpper {$Computer = $Computer.ToUpper()}
            ForceLower {$Computer = $Computer.ToLower()}
            NoChange   {}
        }
        Switch ($Method) {
            Show {
                $Expression = "knife node show $Computer -l -F json 2>&1"
                $Activity = "Get Chef node ('knife node show')"
            }
            Search {
                $Expression = "knife search node '$($SearchField.tolower())`:$($Computer).*' -l -F json 2>&1"
                $Activity = "Search for Chef node ('knife search node')"
            }
        }
        $percentComplete = ($Current / $Total * 100)
        Write-Progress -Activity $Activity -CurrentOperation $CurrentOp -PercentComplete $percentComplete

        $Msg = "Invoke command: '$Expression'"
        Write-Verbose $Msg

        Try {
            $GetNode = (Invoke-NativeExpression -Expression $Expression @StdParams | ConvertFrom-Json @StdParams)
            
            If ($GetNode.Results -eq 0) {

                $Msg = "Node '$Computer' not found"
                $Host.UI.WriteErrorLine("ERROR: $Msg")
                
                $Output = $OutputTemplate.PSObject.Copy()
                $Output.Name = $Computer
                $Output.IsPresent = $False
                $Output.Messages = $Msg
                $Results += $Output
            }

            Else {

                $EndTime = Get-Date
                $ElapsedTime = $EndTime - $StartTime

                Switch ($Method) {
                    Search {$Found = $GetNode.Rows}
                    Show {$Found = $GetNode}
                }

                $Msg = "$(($Found -as [array]).count) matching node(s) found in $($ElapsedTime.Seconds) second(s)"
                Write-Verbose $Msg

                Foreach ($Node in $Found) {
                    
                    $Output = $OutputTemplate.PSObject.Copy()

                    #$Roles = $Node.automatic.recipes -match "role_" | Foreach-Object {$_.Split("::")[0]} | Select -Unique
                    $Roles = $Node.normal.roles

                    $Msg = $Node.Name
                    Write-Verbose $Msg
                    
                    $Output.Name         = $Node.Name
                    $Output.IsPresent    = $True
                    $Output.Environment  = $Node.chef_environment
                    $Output.Platform     = $Node.automatic.os
                    $Output.FQDN         = $Node.automatic.FQDN
                    $Output.Location     = $Node.automatic.location
                    $Output.IPAddress    = $node.automatic.ipaddress
                    $Output.RunList      = $Node.run_list 
                    $Output.Uptime       = $Node.automatic.uptime
                    $Output.Roles        = $Roles
                    $Output.Recipes      = $Node.automatic.recipes
                    $Output.Tags         = $Node.normal.tags
                    $Output.ChefClient   = $Node.default.omnibus_updater.version
                    $Output.ChefServer   = $Node.default.chef_client.config.chef_server_url
                    $Output.LogDir       = $Node.default.chef_client.config.log_location
                    $Output.Messages     = $Null
                    
                    If ($OutputType -eq "Full") {
                        
                        $Network = $node.automatic.Network.Interfaces | Select -ExpandProperty *
                        
                        $Output.IPAddress       = &{$Network.configuration.ip_address | Where {$_ -match "\d\."}}
                        $Output.Gateway         = &{$Network.configuration.default_ip_gateway | Where {$_ -match "\d\."}}
                        $Output.SubnetMask      = &{$Network.configuration.ip_subnet | Where {$_ -match "\d\."}}
                        $Output.DNS             = $Network.configuration.dns_server_search_order
                        $Output.AdapterName     = $Network.instance.name
                        $Output.NetConnectionID = $Network.instance.net_connection_id
                        $Output.MACAddress      = $Network.instance.mac_address
                        $Output.OSName          = $Node.Automatic.kernel.os_info.caption
                        $Output.OSVersion       = $Node.Automatic.kernel.os_info.version
                        $Output.Manufacturer    = $Node.automatic.kernel.cs_info.manufacturer
                        $Output.Model           = $Node.automatic.kernel.cs_info.model
                        $Output.IsVirtual       = $Node.automatic.kernel.cs_info.hypervisor_present
                        $Output.CPU             = @{Count=$Node.automatic.cpu.total;Cores=$Node.automatic.cpu.cores}
                        $Output.MemoryGB        = [math]::round($Node.automatic.kernel.cs_info.total_physical_memory /1gb)
                        $Output.HardDisk        = $Node.automatic.filesystem
                        $Output.Timezone        = $Node.automatic.time.timezone
                    }
                    $Results += $Output
                }
            }
        }
        catch {
            $Msg = "Operation failed"
            $ErrorDetails = $_.Exception.Message
            $Host.UI.WriteErrorLine("ERROR: $Msg`n$ErrorDetails")
            $Output.Messages = "$Msg`n$ErrorDetails"
            $Results += $Output
        }

  } #end for each computer

}
End {

    If ($FindKnifePath.IsPresent) {
        If ($BackupLocation.Path -ne $KnifeParent) {
            Set-Location $BackupLocation -Verbose:$False -ErrorAction SilentlyContinue
        }
    }
    Write-Progress -Activity $Activity -Completed
    If ($OutputType -eq "Boolean") {$Results = $Results | Select Name,IsPresent}
    Write-Output $Results
}
} #end Get-PKChefNode


