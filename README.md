# PKChef #

## About ##

This module contains various functions and tools for managing Chef nodes (primarily but not exclusively Windows).

_Functions following the naming convention `Verb-PK*` are self-authored. Several external/handy functions are also included (see the context help within each function for more information, including credits)._

## Prerequisites ##

Computers must:
* be running PowerShell 3.0 or later
* have the [ChefDK](https://downloads.chef.io/chefdk) installed

All functions should have reasonably detailed comment-based help, accessible via `Get-Help`,  e.g.,

* `Get-Help Do-Something`
* `Get-Help Do-Something -Examples`
* `Get-Help Do-Something -ShowWindow`

## Installation ##
Clone/copy into a valid PSModules folder on your computer and run `Import-Module PKChef`

## Functions ##

#### Get-GNOpsChefNode ####
Uses knife and invoke-expression to return details about a Chef node (full, default, or Boolean)

#### Get-PKChefClient ####
Looks for Chef-Client on a Windows server, using Invoke-Command as a job

#### Install-PKChefClient ####
Installs chef-client on a remote machine from a local or downloaded MSI file
using Invoke-Command and a remote job

#### Invoke-PKChefClient ####
Runs chef-client on a remote machine as a job using invoke-command

#### Invoke-PKChefClientDownload ####
Downloads Chef-Client from an internal or public Chef.io url

#### New-PKChefClientConfig ####
Creates new files on a remote computer to register the node with a Chef server on the next chef-client run

#### Remove-PKChefClientService ####
Looks for the chef-client service on a computer and prompts to remove it if found
