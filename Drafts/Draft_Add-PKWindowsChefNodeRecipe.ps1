break
#requires -Version 3
Function Add-PKWindowsChefNodeRecipe {
[Cmdletbinding()]
Param($Recipe,$NodeName)


$Recipe = 'recipe[gnops_sql::2014_server]'
$NodeName = "ce-agiledev-1.gracenote.gracenote.com"

$ScriptBlock = {
    
    Param($NodeName,$Recipe)
    $Node = $Using:NodeName
    $Add = $Using:Recipe
    $Add = Invoke-Expression -Command "knife node run_list add $Node '$Add' 2>&1"
    Invoke-GNOpsWindowsChefClient -ComputerName $Node 
    
    #$Run = Invoke-Command -ComputerName $Node -AsJob - -ScriptBlock {"chef-client"}

}

}


