# Module PKChef

## About
|||
|---|---|
|**Name** |PKChef|
|**Author** |Paula Kingsley|
|**Type** |Script|
|**Version** |2.8.0|
|**Description**|Various PowerShell tools and functions for managing Chef Windows clients/nodes|
|**Date**|README.md file generated on Monday, August 13, 2018 04:24:46 PM|

This module contains 8 PowerShell functions or commands

All functions should have reasonably detailed comment-based help, accessible via Get-Help ... e.g., 
  * `Get-Help Do-Something`
  * `Get-Help Do-Something -Examples`
  * `Get-Help Do-Something -ShowWindow`

## Prerequisites

Computers must:

  * be running PowerShell 3.0.0 or later

## Installation

Clone/copy entire module directory into a valid PSModules folder on your computer and run `Import-Module PKChef`

## Notes

_All code should be presumed to be written by Paula Kingsley unless otherwise specified (see the context help within each function for more information, including credits)._

## Commands

|**Command**|**Synopsis**|
|---|---|
|**Add-PKChefNodeTag**|Uses knife and invoke-expression to add one or more tags to one or more Chef nodes|
|**Get-PKChefClient**|Looks for Chef-Client on a Windows server, using Invoke-Command as a job|
|**Get-PKChefNode**|Uses knife and invoke-expression to return details about a Chef node (full, default, or Boolean)|
|**Install-PKWindowsChefClient**|Installs chef-client on a remote machine from a local or downloaded MSI file<br/>using Invoke-Command and a remote job|
|**Invoke-PKChefClient**|Runs chef-client on a remote machine as a job using invoke-command|
|**New-PKChefClientConfig**|Creates new files on a remote computer to register the node with a Chef server on the next chef-client run|
|**Remove-PKChefClientService**|Looks for the chef-client service on a computer and prompts to remove it if found|
|**Remove-PKChefNodeTag**|Uses knife and invoke-expression to remove one or more tags to one or more Chef nodes|
