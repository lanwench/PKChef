#requires -version 3
Function Remove-PKChefNode {
[cmdletbinding(
    SupportsShouldProcess = $True,
    ConfirmImpact = "High"
)]
Param(
    [Parameter(
        Mandatory=$true,
        ValueFromPipeline = $True,
        ValueFromPipelineByPropertyName = $True,
        HelpMessage = "Node name(s), separated with commas"
    )]
    [ValidateNotNullOrEmpty()]
    [Alias("ComputerName","Hostname","FQDN","DNSHostName")]
    [string[]]$NodeName
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
    #$Output = New-Object PSObject -Property ([ordered]@{
    #    NodeName      = $Node
    #    ChefServer    = $InitialValue
    #    IsDeleted     = $InitialValue
    #    Messages      = $InitialValue
    #})

    $OutputTemplate = New-Object PSObject -Property ([ordered] @{
        Name        = $InitialValue
        IsDeleted   = $InitialValue
        ChefServer  = $InitialValue
        #FQDN        = $InitialValue
        Environment = $InitialValue
        Location    = $InitialValue
        Platform    = $InitialValue
        IPAddress   = $InitialValue
        RunList     = $InitialValue
        Tags        = $InitialValue
        Messages    = $InitialValue
    })

    $Param_WP = @{
        Activity         = "Find and remove Chef node"
        CurrentOperation = $Null
        Status           = "Working"
        PercentComplete  = $Null
    }
    

}
Process {
    
    $Total = $NodeName.Count
    $Current = 0

    Foreach ($Name in $NodeName) {
        
        $Current ++    
        $Msg = $Name
        Write-Verbose Name 

        $SearchExpression = "knife search node 'name:$($Name).*' -l -F json 2>&1"
        $Param_WP.CurrentOperation = "Executing '$SearchExpression'"
        $Param_WP.PercentComplete = ($Current / $Total * 100)
        Write-Progress @Param_WP

        $GetNode = (Invoke-NativeExpression -Expression $SearchExpression @StdParams | ConvertFrom-Json @StdParams)
            
        If ($GetNode.Results -eq 0) {

            $Msg = "Node '$Name' not found"
            $Host.UI.WriteErrorLine("ERROR: $Msg")
                
            $Output = $OutputTemplate.PSObject.Copy()
            $Output.Name = $Name
            $Output.IsDeleted = $False
            $Output.Messages = $Msg
            
            Write-Output $Output
        }

        Else {

            $EndTime = Get-Date
            $ElapsedTime = $EndTime - $StartTime

            $Msg = "$(($GetNode.Rows -as [array]).count) matching node(s) found in $($ElapsedTime.Seconds) second(s)"
            Write-Verbose $Msg

            Foreach ($Node in $GetNode.Rows) {

                $Msg = $Node.Name
                Write-Verbose $Msg
                    
                $Messages = @()    
                $Output = $OutputTemplate.PSObject.Copy()

                $Output.Name         = $Node.Name
                $Output.ChefServer   = $Node.default.chef_client.config.chef_server_url
                $Output.Environment  = $Node.chef_environment
                $Output.Platform     = $Node.automatic.os
                #$Output.FQDN         = $Node.automatic.FQDN
                $Output.Location     = $Node.automatic.location
                $Output.IPAddress    = $node.automatic.ipaddress
                $Output.RunList      = $Node.run_list 
                $Output.Tags         = $Node.normal.tags
                    
                $ConfirmMsg = "`n`n`tRemove node and client '$($Node.Name)' from Chef server`n`t$($Node.default.chef_client.config.chef_server_url)`n`n"
                    
                If ($PSCmdlet.ShouldProcess($Name,$ConfirmMsg)) {
                        
                    $RemoveExpression = "knife node delete $($Node.Name) 2>&1"
                    $Param_WP.CurrentOperation = "Executing '$Expression'"
                    $Param_WP.PercentComplete = ($Current / $Total * 100)

                    $KillNode = (Invoke-NativeExpression -Expression $RemoveExpression @StdParams)

                    If ($KillNode -match "deleted") {
                        $Msg = "Deleted node"

                        $RemoveExpression = "knife client delete $($Node.Name) 2>&1"
                        $KillClient = (Invoke-NativeExpression -Expression $RemoveExpression @StdParams)

                        If ($KillClient -match "deleted") {
                            $Msg = "Deleted node and client"
                            Write-Verbose $Msg
                            $Output.IsDeleted = $True
                        }
                        Else {
                            $Msg = "Deleted node; client deletion failed`n$KillClient"
                            $Host.UI.WriteErrorLine($Msg)
                            $Output.IsDeleted = $False
                        }
                    }
                    Else {
                        $Msg= "Node deletion failed`n$KillNode"
                        $Host.UI.WriteErrorLine($Msg)
                        $Output.IsDeleted = $False
                    }
                    $Output.Messages = $Msg
                }
                Else {
                    $Msg = "Node deletion cancelled by user"
                    $Host.UI.WriteErrorLine($Msg)
                    $Output.IsDeleted = $False
                    $Output.Messages = $Msg
                }

                Write-Output $Output

            } #end for each node found
            
        } #end if node found
            
    } #end for each node name

}

} #end Remove-PKChefNode

<#

$Node = "ops-cassandratest-406.internal.gracenote.com"

# Requires -Version 3
$Scriptblock = {
    Param($NodeName)
    $Node = $Using:NodeName

    $Output = New-Object PSObject -Property ([ordered]@{
        NodeName      = $Node
        ChefServer    = $InitialValue
        NodeDeleted   = $InitialValue
        ClientDeleted = $InitialValue
        Messages      = $InitialValue
    })

    $ErrorMsg = @()
    Try {
        $KillNode = Invoke-Expression "knife node delete $Node" -ErrorAction Stop
        If ($KillNode -match "deleted") {
            $Output.NodeDeleted = $True

            $KillClient = Invoke-Expression "knife client delete $Node" -ErrorAction Stop
            If ($KillClient -match "deleted") {
                $Output.ClientDeleted = $True

            }
            Else {
                $Output.ClientDeleted = $False
                $Output.Messages = $KillClient
            }
        }
        Else {
            $Output.NodeDeleted = $False
            $Output.Messages = $KillNode
        }

    }
    Catch {
        $Output.Messages = $_.Exception.Messages
    }

    Write-Output $Output
}

#>