<#
.SYNOPSIS
Removes a node from Chef. Optionally stores the current Chef config of the node in a JSON file.

.DESCRIPTION
This function will remove a given node from the Chef server by deleting the node and client object. 
It optionally stores the current Chef config of the node in a JSON-formatted file. The filename for 
the backup can be specified as well, otherwise it will default to '<nodename>_<yyyy-MM-dd_hh-mm-ss>'.

.PARAMETER ChefNodeName
Defines the name of the Chef node (equals the 'node_name' property in Chef).

.PARAMETER Backup
Exports the node's configuration as a JSON-formatted set of data and stores it in a file.
The default backup filename is '<nodename>_<yyyy-MM-dd_hh-mm-ss>.json'.

.PARAMETER BackupFilePath
Defines an alternative filename for the backup.

.EXAMPLE
Unregister-ChefNode -ChefNodeName ops-bastion-1.globix-sc.gracenote.com
Deleted node[ops-bastion-1.globix-sc.gracenote.com]
Deleted client[ops-bastion-1.globix-sc.gracenote.com]

.EXAMPLE
Unregister-ChefNode OPS-PKTEST-501.gracenote.gracenote.com -Backup
Backup successfully created.
Deleted node[OPS-PKTEST-501.gracenote.gracenote.com]
Deleted client[OPS-PKTEST-501.gracenote.gracenote.com]


.EXAMPLE
Unregister-ChefNode ops-bastion-601.gracenote.gracenote.com -Backup -BackupFilePath 20160504_ops-bastion-601.json -Verbose
Loading node configuration for 'ops-bastion-601.gracenote.gracenote.com'...
Saving JSON export to backup file: '20160504_ops-bastion-601.json'...
Backup successfully created.
Deleted node[ops-bastion-601.gracenote.gracenote.com]
Deleted client[ops-bastion-601.gracenote.gracenote.com]

.NOTES
File:       Function_Get-ActiveDirectoryFqdn.ps1
Version:    1.1
Author:     Mario Fischer (mfischer@gracenote.com)
ToDo:       - implement 'quiet' parameter & suppress all output
#>
function Unregister-ChefNode() {
    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            HelpMessage = "Chef node name (case sensitive!)"
        )]
        [String] $ChefNodeName,

        [Parameter(
            Mandatory = $false,
            Position = 1,
            HelpMessage = "Create JSON export of node properties?"
        )]
        [Switch] $Backup = $false,
        
        [ValidateNotNullOrEmpty()]
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            Position = 2,
            HelpMessage = "File path for JSON export of node properties"
        )]
        [String] $BackupFilePath = "${ChefNodeName}_$(get-date -Format yyyy-MM-dd_hh-mm-ss).json"
    )
    begin {
        $ExprOutput = @()
        $ChefItems = @("node", "client")
    }
    process {
        if ($Backup.IsPresent) {
            try {
                Write-Verbose "Loading node configuration for '$ChefNodeName'..."
                $ExprOutput = Invoke-Expression -Command "knife node show -m -F json $ChefNodeName" -ErrorAction Stop 2>&1
                if ($LASTEXITCODE -ne 0) { 
                    if ($LASTEXITCODE -eq 100) { throw "node not found" }
                }
            }
            catch {
                $Msg = "Unable to get node configuration for '$ChefNodeName'"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg ($ErrorDetails).")
                break
            }
            try {
                Write-Verbose "Saving JSON export to backup file: '$BackupFilePath'..."
                $ExprOutput | out-file -FilePath $BackupFilePath -ErrorAction Stop -Force -Encoding ASCII
            }
            catch {
                $Msg = "Writing backup file for '$ChefNodeName' failed"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg ($ErrorDetails).")
                break
            }
            Write-Output "Backup successfully created."
        }
        foreach ($ChefItem in $ChefItems) {
            try {
                Write-Verbose "Deleting $ChefItem object for '$ChefNodeName'..."
                Invoke-Expression -Command "knife $ChefItem delete '$ChefNodeName' -y" -ErrorAction Stop 2>&1
                if ($LASTEXITCODE -ne 0) { throw "execution of 'knife $ChefItem delete' failed" }
            }
            catch {
                $Msg = "Unable to remove $ChefItem object for '$ChefNodeName'"
                $ErrorDetails = $_.Exception.Message
                $Host.UI.WriteErrorLine("ERROR: $Msg ($ErrorDetails).")
                break
            }
        }
    }
}