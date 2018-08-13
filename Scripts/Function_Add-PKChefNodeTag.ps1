#requires -Version 3
Function Add-PKChefNodeTag {
<#
.Synopsis
    Uses knife and invoke-expression to add one or more tags to one or more Chef nodes

.Description
    Uses knife and invoke-expression to add one or more tags to one or more Chef nodes
    Searches for knife from chefdk (required)
    Accepts pipeline input
    Returns a PSObject

.NOTES 
    Name    : Function_Add-PKChefNodeTag.ps1
    Version : 01.00.0000
    Author  : Paula Kingsley
    History:  
        
        ** PLEASE KEEP $VERSION UP TO DATE IN BEGIN BLOCK ** 

        v01.00.0000 - 2017-09-20 - Created script
        
.EXAMPLE
    PS C:\> Add-PKChefNodeTag -NodeName server-666 -Tag patchgroup9 -Verbose
    # Adds a tag to a Chef node

        VERBOSE: PSBoundParameters: 
	
        Key           Value                   
        ---           -----                   
        NodeName      server-666            
        Tag           {patchgroup9}
        Verbose       True                    
        PipelineInput False                   
        ScriptName    Add-PKChefNodeTag
        ScriptVersion 1.0.0

        VERBOSE: server-666
        VERBOSE: 1 matching node(s) found in 5 second(s)
        VERBOSE: server-666.domain.local

        NodeName     : server-666.domain.local
        ChefServer   : https://chef.domain.local/organizations/org
        ExistingTags : {nomonitor-host, nomonitor-service, sqldev}
        NewTags      : {nomonitor-host, nomonitor-service, sqldev, patchgroup9}
        IsSuccessful : True
        Messages     : Created tags patchgroup9 for node server-666.domain.local.

.EXAMPLE
    PS C:\> Add-PKChefNodeTag -NodeName server-666 -Tag patchgroup9 -Verbose

        VERBOSE: PSBoundParameters: 
	
        Key           Value                   
        ---           -----                   
        NodeName      server-666            
        Tag           {patchgroup9}
        Verbose       True                    
        PipelineInput False                   
        ScriptName    Add-PKChefNodeTag
        ScriptVersion 1.0.0                   

        VERBOSE: server-666
        VERBOSE: 1 matching node(s) found in 5 second(s)
        VERBOSE: server-666.domain.local
        ERROR: Specified tag(s) already present on server-666.domain.local

        NodeName     : server-666.domain.local
        ChefServer   : https://chef.domain.local/organizations/org
        ExistingTags : {nomonitor-host, nomonitor-service, sqldev, patchgroup9}
        NewTags      : (n/a)
        IsSuccessful : False
        Messages     : Specified tag(s) already present


#>
[Cmdletbinding()]
Param(
    [Parameter(
        Mandatory = $True,
        Position = 0,
        ValueFromPipeline = $True,
        HelpMessage = "Node name or FQDN"
    )]
    [ValidateNotNullOrEmpty()]
    [String[]]$NodeName,

    [Parameter(
        Mandatory = $True,
        Position = 1,
        ValueFromPipeline = $True,
        HelpMessage = "Tag to add to node"
    )]
    [ValidateNotNullOrEmpty()]
    [String[]]$Tag
)

Begin {

    # Current version (please keep up to date from comment block)
    [version]$Version = "01.00.0000"

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

    # Make sure we can do the things
    If (-not (Get-Command knife -ErrorAction SilentlyContinue)) {
        $Msg = "Knife not found; ensure ChefDK is installed and configured`nhttps://downloads.chef.io/chefdk"
        $Host.UI.WriteErrorLine("ERROR: $Msg")
        Break
    }

    # Helper function from http://www.powershellmagazine.com/2013/01/02/calling-native-commands-from-powershell/
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

    $InitialValue = "Error"
    $OutputTemplate = New-Object PSObject -Property ([ordered] @{
        NodeName     = $InitialValue
        ChefServer   = $InitialValue
        ExistingTags = $InitialValue
        NewTags      = $InitialValue
        IsSuccessful = $InitialValue
        Messages     = $InitialValue
    })


}
Process {

    Foreach ($Name in $NodeName) {
    
        $Msg = $Name
        Write-Verbose $Msg

        If ($Name -match "\.\w") {$SearchName = $Name}
        Else {$SearchName = "$Name.*"}
        $SearchExpression = "knife search node 'name:$SearchName' -l -F json 2>&1"
    
        $StartTime = Get-Date
        $Activity = "Search for Chef node ('$SearchExpression')"
        Write-Progress -Activity $Activity -Status Working -CurrentOperation $Name
        $GetNode = (Invoke-NativeExpression -Expression $SearchExpression @StdParams | ConvertFrom-Json @StdParams)
        $EndTime = Get-Date
        $ElapsedTime = $EndTime - $StartTime
    
        If ($GetNode.Results -eq 0) {
            $Msg = "Node '$Name' not found after $($ElapsedTime.Seconds) second(s)"
            $Host.UI.WriteErrorLine("ERROR: $Msg")
                
            $Output = $OutputTemplate.PSObject.Copy()
            $Output.NodeName = $Name
            $Output.Messages = $Msg
            Write-Output $Output
        }
        Else {
        
            $Msg = "$(($GetNode.Rows -as [array]).count) matching node(s) found in $($ElapsedTime.Seconds) second(s)"
            Write-Verbose $Msg
    
            Foreach ($NodeObj in $GetNode.Rows) {
                    
                $Output = $OutputTemplate.PSObject.Copy()

                $Msg = $NodeObj.Name
                Write-Verbose $Msg
                    
                $Output.NodeName     = $NodeObj.Name
                $Output.ChefServer   = $NodeObj.default.chef_client.config.chef_server_url
                $Output.ExistingTags = $NodeObj.normal.tags
                $Output.Messages     = $Null
            
                $TagArr = @()
                Foreach ($T in $Tag) {
                    If (-not ($Output.ExistingTags -contains $T)) {
                        $TagArr += $T.tolower()
                    }
                }
                If ($TagArr.Count -eq 0) {
                    $Msg = "Specified tag(s) already present on $($NodeObj.Name)"
                    $Host.UI.WriteErrorLine("ERROR: $Msg")
                    $Output.IsSuccessful = $False
                    $Output.NewTags = "(n/a)"
                    $Output.Messages = $Msg
                }
                Else {
                    [switch]$Continue = $True
                    $TagStr = $TagArr -join(" ")
                    $TagExpression = "knife tag create $($NodeObj.Name) $TagStr 2>&1"
                    $Activity = "Add tag to Chef node ('$TagExpression')"
                    Write-Progress -Activity $Activity -Status Working -CurrentOperation $NodeObj.Name
                
                    $TagNode = (Invoke-NativeExpression -Expression $TagExpression @StdParams)

                    If ($TagNode -match "created tags") {
                        $Output.IsSuccessful = $True

                        $GetTagExpression = "knife tag list $($NodeObj.Name) 2>&1"
                        $GetTag = (Invoke-NativeExpression -Expression $GetTagExpression @StdParams)
                        $Output.NewTags = $GetTag
                        $Output.Messages = $TagNode
                    }
                    Else {
                        $Output.IsSuccessful = $False
                        $Output.Messages = $TagNode
                    }
                
                }
                Write-Output $Output

            } #end for each node found
        
        } #end for each node found
    
    } #end for each nodename provided
}

} #end Add-PKChefNodeTag


