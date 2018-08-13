#requires -Version 3
Function Get-PKChefKnifeCommands {
[cmdletbinding()]
Param(
    [Parameter(
        Mandatory = $False,
        Position= 0
    )]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("ALL","BOOTSTRAP","CLIENT","CONFIGURE","COOKBOOK","COOKBOOK_SITE","DATA_BAG","EC2","ENVIRONMENT","EXEC","HELP","INDEX","JOB","KNIFE","NODE","NULLCMD","OPSCODE_PRIVATE","OSC","PATH_BASED","RAW","RECIPE","REHASH","ROLE","SEARCH","SERVE","SPORK","SSH","SSL","STATUS","SUPERMARKET","TAG","USER","VAULT","WINDOWS","WINRM","WSMAN")]
    [String]$Command = "All"
)

#region Here-String for commands

$Here_OPSCODE_PRIVATE = @"

** OPSCODE PRIVATE CHEF ORGANIZATION MANAGEMENT COMMANDS **
    knife opc org create ORG_SHORT_NAME ORG_FULL_NAME (options)
    knife opc org delete ORG_NAME
    knife opc org edit ORG
    knife opc org list
    knife opc org show ORGNAME
    knife opc org user add ORG_NAME USER_NAME
    knife opc org user remove ORG_NAME USER_NAME
    knife opc user create USERNAME FIRST_NAME [MIDDLE_NAME] LAST_NAME EMAIL PASSWORD
    knife opc user delete USERNAME [-d]
    knife opc user edit USERNAME
    knife opc user list
    knife opc user password USERNAME [PASSWORD | --enable-external-auth]
    knife opc user show USERNAME

"@

$Here_BOOTSTRAP = @"

** BOOTSTRAP COMMANDS **
    knife bootstrap [SSH_USER@]FQDN (options)
    knife bootstrap windows ssh FQDN (options)
    knife bootstrap windows winrm FQDN (options)

"@

$Here_CLIENT = @"

** CLIENT COMMANDS **
    knife client bulk delete REGEX (options)
    knife client create CLIENTNAME (options)
    knife client delete [CLIENT[,CLIENT]] (options)
    knife client edit CLIENT (options)
    knife client key create CLIENT (options)
    knife client key delete CLIENT KEYNAME (options)
    knife client key edit CLIENT KEYNAME (options)
    knife client key list CLIENT (options)
    knife client key show CLIENT KEYNAME (options)
    knife client list (options)
    knife client reregister CLIENT (options)
    knife client show CLIENT (options)

"@

$Here_CONFIGURE = @"

** CONFIGURE COMMANDS **
    knife configure (options)
    knife configure client DIRECTORY


"@

$Here_COOKBOOK = @"

** COOKBOOK COMMANDS **
    knife cookbook bulk delete REGEX (options)
    Usage: C:/opscode/chefdk/embedded/bin/knife (options)
    knife cookbook delete COOKBOOK VERSION (options)
    knife cookbook download COOKBOOK [VERSION] (options)
    knife cookbook list (options)
    knife cookbook metadata COOKBOOK (options)
    knife cookbook metadata from FILE (options)
    knife cookbook show COOKBOOK [VERSION] [PART] [FILENAME] (options)
    knife cookbook test [COOKBOOKS...] (options)
    knife cookbook upload [COOKBOOKS...] (options)

"@

$Here_COOKBOOK_SITE = @"

** COOKBOOK SITE COMMANDS **
    knife cookbook site download COOKBOOK [VERSION] (options)
    knife cookbook site install COOKBOOK [VERSION] (options)
    knife cookbook site list (options)
    knife cookbook site search QUERY (options)
    knife cookbook site share COOKBOOK [CATEGORY] (options)
    knife cookbook site show COOKBOOK [VERSION] (options)
    knife cookbook site unshare COOKBOOK

"@

$Here_DATA_BAG = @"

** DATA BAG COMMANDS **
    knife data bag create BAG [ITEM] (options)
    knife data bag delete BAG [ITEM] (options)
    knife data bag edit BAG ITEM (options)
    knife data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)
    knife data bag list (options)
    knife data bag show BAG [ITEM] (options)

"@

$Here_EC2 = @"

** EC2 COMMANDS **
    knife ec2 amis ubuntu DISTRO [TYPE] (options)

"@

$Here_ENVIRONMENT = @"

** ENVIRONMENT COMMANDS **
    knife environment compare [ENVIRONMENT..] (options)
    knife environment create ENVIRONMENT (options)
    knife environment delete ENVIRONMENT (options)
    knife environment edit ENVIRONMENT (options)
    knife environment from file FILE [FILE..] (options)
    knife environment list (options)
    knife environment show ENVIRONMENT (options)

"@

$Here_EXEC = @"

** EXEC COMMANDS **
    knife exec [SCRIPT] (options)

"@

$Here_HELP = @"
** HELP COMMANDS **
    knife help [list|TOPIC]


"@

$Here_INDEX = @"

** INDEX COMMANDS **
    knife index rebuild (options)

"@

$Here_JOB = @"

** JOB COMMANDS **
    knife job list
    knife job output <job id> <node> [<node> ...]
    knife job start <command> [<node> <node> ...]
    knife job status <job id>

"@

$Here_KNIFE = @"

** KNIFE COMMANDS **
    Usage: C:/opscode/chefdk/embedded/bin/knife (options)

"@

$Here_NODE = @"

** NODE COMMANDS **
    knife node bulk delete REGEX (options)
    knife node create NODE (options)
    knife node delete [NODE[,NODE]] (options)
    knife node edit NODE (options)
    knife node environment set NODE ENVIRONMENT
    knife node from file FILE (options)
    knife node list (options)
    knife node run_list add [NODE] [ENTRY[,ENTRY]] (options)
    knife node run_list remove [NODE] [ENTRY[,ENTRY]] (options)
    knife node run_list set NODE ENTRIES (options)
    knife node show NODE (options)
    knife node status [<node> <node> ...]

"@

$Here_NULLCMD = @"

** NULL COMMANDS **
    knife null

"@

 $Here_OSC = @"

** OSC COMMANDS **
    knife osc_user create USER (options)
    knife osc_user delete USER (options)
    knife osc_user edit USER (options)
    knife osc_user list (options)
    knife osc_user reregister USER (options)
    knife osc_user show USER (options)
 
 "@

$Here_PATH_BASED = @"

** PATH-BASED COMMANDS **
    knife delete [PATTERN1 ... PATTERNn]
    knife deps PATTERN1 [PATTERNn]
    knife diff PATTERNS
    knife download PATTERNS
    knife edit [PATTERN1 ... PATTERNn]
    knife list [-dfR1p] [PATTERN1 ... PATTERNn]
    knife show [PATTERN1 ... PATTERNn]
    knife upload PATTERNS
    knife xargs [COMMAND]

"@

$Here_RAW = @"

** RAW COMMANDS **
    knife raw REQUEST_PATH

"@

$Here_RECIPE = @"

** RECIPE COMMANDS **
    knife recipe list [PATTERN]

"@

$Here_REHASH = @"

** REHASH COMMANDS **
    knife rehash

"@

$Here_ROLE = @"

** ROLE COMMANDS **
    knife role bulk delete REGEX (options)
    knife role create ROLE (options)
    knife role delete ROLE (options)
    knife role edit ROLE (options)
    knife role env_run_list add [ROLE] [ENVIRONMENT] [ENTRY[,ENTRY]] (options)
    knife role env_run_list clear [ROLE] [ENVIRONMENT]
    knife role env_run_list remove [ROLE] [ENVIRONMENT] [ENTRIES]
    knife role env_run_list replace [ROLE] [ENVIRONMENT] [OLD_ENTRY] [NEW_ENTRY] 
    knife role env_run_list set [ROLE] [ENVIRONMENT] [ENTRIES]
    knife role from file FILE [FILE..] (options)
    knife role list (options)
    knife role run_list add [ROLE] [ENTRY[,ENTRY]] (options)
    knife role run_list clear [ROLE]
    knife role run_list remove [ROLE] [ENTRY]
    knife role run_list replace [ROLE] [OLD_ENTRY] [NEW_ENTRY] 
    knife role run_list set [ROLE] [ENTRIES]
    knife role show ROLE (options)

"@

$Here_SEARCH = @"

** SEARCH COMMANDS **
    knife search INDEX QUERY (options)

"@

$Here_SERVE = @"

** SERVE COMMANDS **
    knife serve (options)

"@

$Here_SPORK = @"

** SPORK COMMANDS **
    knife spork bump COOKBOOK [major|minor|patch|manual]
    knife spork check COOKBOOK (options)
    knife spork data bag create BAG [ITEM] (options)
    knife spork data bag delete BAG [ITEM] (options)
    knife spork data bag edit BAG ITEM (options)
    knife spork data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)
    knife spork delete [COOKBOOKS...] (options)
    knife spork environment check ENVIRONMENT (options)
    knife spork environment create ENVIRONMENT (options)
    knife spork environment delete ENVIRONMENT (options)
    knife spork environment edit ENVIRONMENT (options)
    knife spork environment from file FILENAME (options)
    knife spork info
    knife spork node create NODE (options)
    knife spork node delete NODE (options)
    knife spork node edit NODE (options)
    knife spork node from file FILE (options)
    knife spork node run_list add [NODE] [ENTRY[,ENTRY]] (options)
    knife spork node run_list add [NODE] [ENTRY[,ENTRY]] (options)
    knife spork node run_list set NODE ENTRIES (options)
    knife spork omni COOKBOOK (options)
    knife spork promote ENVIRONMENT COOKBOOK (options)
    knife spork role create ROLE (options)
    knife spork role delete ROLENAME (options)
    knife spork role edit ROLENAME (options)
    knife spork role from file FILENAME (options)
    knife spork upload [COOKBOOKS...] (options)

"@

$Here_SSH = @"

** SSH COMMANDS **
    knife ssh QUERY COMMAND (options)

"@

$Here_SSL = @"

** SSL COMMANDS **
    knife ssl check [URL] (options)
    knife ssl fetch [URL] (options)

"@

$Here_STATUS = @"

** STATUS COMMANDS **
    knife status QUERY (options)

"@

$Here_SUPERMARKET = @"

** SUPERMARKET COMMANDS **
    knife supermarket download COOKBOOK [VERSION] (options)
    knife supermarket install COOKBOOK [VERSION] (options)
    knife supermarket list (options)
    knife supermarket search QUERY (options)
    knife supermarket share COOKBOOK [CATEGORY] (options)
    knife supermarket show COOKBOOK [VERSION] (options)
    knife supermarket unshare COOKBOOK (options)

"@

$Here_TAG = @"

** TAG COMMANDS **
    knife tag create NODE TAG ...
    knife tag delete NODE TAG ...
    knife tag list NODE

"@

$Here_USER = @"

** USER COMMANDS **
    knife user create USERNAME DISPLAY_NAME FIRST_NAME LAST_NAME EMAIL PASSWORD (options)
    knife user delete USER (options)
    knife user edit USER (options)
    knife user key create USER (options)
    knife user key delete USER KEYNAME (options)
    knife user key edit USER KEYNAME (options)
    knife user key list USER (options)
    knife user key show USER KEYNAME (options)
    knife user list (options)
    knife user reregister USER (options)
    knife user show USER (options)

"@

$Here_VAULT = @"

** VAULT COMMANDS **
    knife vault create VAULT ITEM VALUES (options)
    knife vault delete VAULT ITEM (options)
    knife vault download VAULT ITEM PATH (options)
    knife vault edit VAULT ITEM (options)
    knife vault isvault VAULT ITEM (options)
    knife vault itemtype VAULT ITEM (options)
    knife vault list (options)
    knife vault refresh VAULT ITEM
    knife vault remove VAULT ITEM VALUES (options)
    knife vault rotate all keys
    knife vault rotate keys VAULT ITEM (options)
    knife vault show VAULT [ITEM] [VALUES] (options)
    knife vault update VAULT ITEM VALUES (options)

"@

$Here_WINDOWS = @"

** WINDOWS COMMANDS **
    knife windows cert generate FILE_PATH (options)
    knife windows cert install CERT [CERT] (options)
    knife bootstrap windows winrm FQDN (options)
    knife bootstrap windows ssh FQDN (options)
    knife winrm QUERY COMMAND (options)
    knife wsman test QUERY (options)
    knife windows listener create (options)

"@

$Here_WINRM = @"

** WINRM COMMANDS **
    knife winrm QUERY COMMAND (options)

"@

$Here_WSMAN = @"

** WSMAN COMMANDS **
    knife wsman test QUERY (options)
    
"@

$Here_ALL = @"

Available subcommands: (for details, knife SUB-COMMAND --help)

** OPSCODE PRIVATE CHEF ORGANIZATION MANAGEMENT COMMANDS **
    knife opc org create ORG_SHORT_NAME ORG_FULL_NAME (options)
    knife opc org delete ORG_NAME
    knife opc org edit ORG
    knife opc org list
    knife opc org show ORGNAME
    knife opc org user add ORG_NAME USER_NAME
    knife opc org user remove ORG_NAME USER_NAME
    knife opc user create USERNAME FIRST_NAME [MIDDLE_NAME] LAST_NAME EMAIL PASSWORD
    knife opc user delete USERNAME [-d]
    knife opc user edit USERNAME
    knife opc user list
    knife opc user password USERNAME [PASSWORD | --enable-external-auth]
    knife opc user show USERNAME

** BOOTSTRAP COMMANDS **
    knife bootstrap [SSH_USER@]FQDN (options)
    knife bootstrap windows ssh FQDN (options)
    knife bootstrap windows winrm FQDN (options)

** CLIENT COMMANDS **
    knife client bulk delete REGEX (options)
    knife client create CLIENTNAME (options)
    knife client delete [CLIENT[,CLIENT]] (options)
    knife client edit CLIENT (options)
    knife client key create CLIENT (options)
    knife client key delete CLIENT KEYNAME (options)
    knife client key edit CLIENT KEYNAME (options)
    knife client key list CLIENT (options)
    knife client key show CLIENT KEYNAME (options)
    knife client list (options)
    knife client reregister CLIENT (options)
    knife client show CLIENT (options)

** CONFIGURE COMMANDS **
    knife configure (options)
    knife configure client DIRECTORY

** COOKBOOK COMMANDS **
    knife cookbook bulk delete REGEX (options)
    Usage: C:/opscode/chefdk/embedded/bin/knife (options)
    knife cookbook delete COOKBOOK VERSION (options)
    knife cookbook download COOKBOOK [VERSION] (options)
    knife cookbook list (options)
    knife cookbook metadata COOKBOOK (options)
    knife cookbook metadata from FILE (options)
    knife cookbook show COOKBOOK [VERSION] [PART] [FILENAME] (options)
    knife cookbook test [COOKBOOKS...] (options)
    knife cookbook upload [COOKBOOKS...] (options)

** COOKBOOK SITE COMMANDS **
    knife cookbook site download COOKBOOK [VERSION] (options)
    knife cookbook site install COOKBOOK [VERSION] (options)
    knife cookbook site list (options)
    knife cookbook site search QUERY (options)
    knife cookbook site share COOKBOOK [CATEGORY] (options)
    knife cookbook site show COOKBOOK [VERSION] (options)
    knife cookbook site unshare COOKBOOK

** DATA BAG COMMANDS **
    knife data bag create BAG [ITEM] (options)
    knife data bag delete BAG [ITEM] (options)
    knife data bag edit BAG ITEM (options)
    knife data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)
    knife data bag list (options)
    knife data bag show BAG [ITEM] (options)

** EC2 COMMANDS **
    knife ec2 amis ubuntu DISTRO [TYPE] (options)

** ENVIRONMENT COMMANDS **
    knife environment compare [ENVIRONMENT..] (options)
    knife environment create ENVIRONMENT (options)
    knife environment delete ENVIRONMENT (options)
    knife environment edit ENVIRONMENT (options)
    knife environment from file FILE [FILE..] (options)
    knife environment list (options)
    knife environment show ENVIRONMENT (options)

** EXEC COMMANDS **
    knife exec [SCRIPT] (options)

** HELP COMMANDS **
    knife help [list|TOPIC]

** INDEX COMMANDS **
    knife index rebuild (options)

** JOB COMMANDS **
    knife job list
    knife job output <job id> <node> [<node> ...]
    knife job start <command> [<node> <node> ...]
    knife job status <job id>

** KNIFE COMMANDS **
    Usage: C:/opscode/chefdk/embedded/bin/knife (options)

** NODE COMMANDS **
    knife node bulk delete REGEX (options)
    knife node create NODE (options)
    knife node delete [NODE[,NODE]] (options)
    knife node edit NODE (options)
    knife node environment set NODE ENVIRONMENT
    knife node from file FILE (options)
    knife node list (options)
    knife node run_list add [NODE] [ENTRY[,ENTRY]] (options)
    knife node run_list remove [NODE] [ENTRY[,ENTRY]] (options)
    knife node run_list set NODE ENTRIES (options)
    knife node show NODE (options)
    knife node status [<node> <node> ...]

** NULL COMMANDS **
    knife null

** OSC COMMANDS **
    knife osc_user create USER (options)
    knife osc_user delete USER (options)
    knife osc_user edit USER (options)
    knife osc_user list (options)
    knife osc_user reregister USER (options)
    knife osc_user show USER (options)

** PATH-BASED COMMANDS **
    knife delete [PATTERN1 ... PATTERNn]
    knife deps PATTERN1 [PATTERNn]
    knife diff PATTERNS
    knife download PATTERNS
    knife edit [PATTERN1 ... PATTERNn]
    knife list [-dfR1p] [PATTERN1 ... PATTERNn]
    knife show [PATTERN1 ... PATTERNn]
    knife upload PATTERNS
    knife xargs [COMMAND]

** RAW COMMANDS **
    knife raw REQUEST_PATH

** RECIPE COMMANDS **
    knife recipe list [PATTERN]

** REHASH COMMANDS **
    knife rehash

** ROLE COMMANDS **
    knife role bulk delete REGEX (options)
    knife role create ROLE (options)
    knife role delete ROLE (options)
    knife role edit ROLE (options)
    knife role env_run_list add [ROLE] [ENVIRONMENT] [ENTRY[,ENTRY]] (options)
    knife role env_run_list clear [ROLE] [ENVIRONMENT]
    knife role env_run_list remove [ROLE] [ENVIRONMENT] [ENTRIES]
    knife role env_run_list replace [ROLE] [ENVIRONMENT] [OLD_ENTRY] [NEW_ENTRY] 
    knife role env_run_list set [ROLE] [ENVIRONMENT] [ENTRIES]
    knife role from file FILE [FILE..] (options)
    knife role list (options)
    knife role run_list add [ROLE] [ENTRY[,ENTRY]] (options)
    knife role run_list clear [ROLE]
    knife role run_list remove [ROLE] [ENTRY]
    knife role run_list replace [ROLE] [OLD_ENTRY] [NEW_ENTRY] 
    knife role run_list set [ROLE] [ENTRIES]
    knife role show ROLE (options)

** SEARCH COMMANDS **
    knife search INDEX QUERY (options)

** SERVE COMMANDS **
    knife serve (options)

** SPORK COMMANDS **
    knife spork bump COOKBOOK [major|minor|patch|manual]
    knife spork check COOKBOOK (options)
    knife spork data bag create BAG [ITEM] (options)
    knife spork data bag delete BAG [ITEM] (options)
    knife spork data bag edit BAG ITEM (options)
    knife spork data bag from file BAG FILE|FOLDER [FILE|FOLDER..] (options)
    knife spork delete [COOKBOOKS...] (options)
    knife spork environment check ENVIRONMENT (options)
    knife spork environment create ENVIRONMENT (options)
    knife spork environment delete ENVIRONMENT (options)
    knife spork environment edit ENVIRONMENT (options)
    knife spork environment from file FILENAME (options)
    knife spork info
    knife spork node create NODE (options)
    knife spork node delete NODE (options)
    knife spork node edit NODE (options)
    knife spork node from file FILE (options)
    knife spork node run_list add [NODE] [ENTRY[,ENTRY]] (options)
    knife spork node run_list add [NODE] [ENTRY[,ENTRY]] (options)
    knife spork node run_list set NODE ENTRIES (options)
    knife spork omni COOKBOOK (options)
    knife spork promote ENVIRONMENT COOKBOOK (options)
    knife spork role create ROLE (options)
    knife spork role delete ROLENAME (options)
    knife spork role edit ROLENAME (options)
    knife spork role from file FILENAME (options)
    knife spork upload [COOKBOOKS...] (options)

** SSH COMMANDS **
    knife ssh QUERY COMMAND (options)

** SSL COMMANDS **
    knife ssl check [URL] (options)
    knife ssl fetch [URL] (options)

** STATUS COMMANDS **
    knife status QUERY (options)

** SUPERMARKET COMMANDS **
    knife supermarket download COOKBOOK [VERSION] (options)
    knife supermarket install COOKBOOK [VERSION] (options)
    knife supermarket list (options)
    knife supermarket search QUERY (options)
    knife supermarket share COOKBOOK [CATEGORY] (options)
    knife supermarket show COOKBOOK [VERSION] (options)
    knife supermarket unshare COOKBOOK (options)

** TAG COMMANDS **
    knife tag create NODE TAG ...
    knife tag delete NODE TAG ...
    knife tag list NODE

** USER COMMANDS **
    knife user create USERNAME DISPLAY_NAME FIRST_NAME LAST_NAME EMAIL PASSWORD (options)
    knife user delete USER (options)
    knife user edit USER (options)
    knife user key create USER (options)
    knife user key delete USER KEYNAME (options)
    knife user key edit USER KEYNAME (options)
    knife user key list USER (options)
    knife user key show USER KEYNAME (options)
    knife user list (options)
    knife user reregister USER (options)
    knife user show USER (options)

** VAULT COMMANDS **
    knife vault create VAULT ITEM VALUES (options)
    knife vault delete VAULT ITEM (options)
    knife vault download VAULT ITEM PATH (options)
    knife vault edit VAULT ITEM (options)
    knife vault isvault VAULT ITEM (options)
    knife vault itemtype VAULT ITEM (options)
    knife vault list (options)
    knife vault refresh VAULT ITEM
    knife vault remove VAULT ITEM VALUES (options)
    knife vault rotate all keys
    knife vault rotate keys VAULT ITEM (options)
    knife vault show VAULT [ITEM] [VALUES] (options)
    knife vault update VAULT ITEM VALUES (options)

** WINDOWS COMMANDS **
    knife windows cert generate FILE_PATH (options)
    knife windows cert install CERT [CERT] (options)
    knife bootstrap windows winrm FQDN (options)
    knife bootstrap windows ssh FQDN (options)
    knife winrm QUERY COMMAND (options)
    knife wsman test QUERY (options)
    knife windows listener create (options)

** WINRM COMMANDS **
    knife winrm QUERY COMMAND (options)

** WSMAN COMMANDS **
    knife wsman test QUERY (options)


"@

#endregion Herestring

$Commands = "ALL","BOOTSTRAP","CLIENT","CONFIGURE","COOKBOOK","COOKBOOK_SITE","DATA_BAG","EC2","ENVIRONMENT","EXEC","HELP","INDEX","JOB","KNIFE","NODE","NULLCMD","OPSCODE_PRIVATE","OSC","PATH_BASED","RAW","RECIPE","REHASH","ROLE","SEARCH","SERVE","SPORK","SSH","SSL","STATUS","SUPERMARKET","TAG","USER","VAULT","WINDOWS","WINRM","WSMAN"

Switch ($Command) {
    ALL {
        $Msg = 'Return help output for knife ALL'
        Write-Verbose $Msg
        Write-Output $Here_ALL
    }
    BOOTSTRAP {
        $Msg = 'Return help output for knife BOOTSTRAP'
        Write-Verbose $Msg
        Write-Output $Here_BOOTSTRAP
    }
    CLIENT {
        $Msg = 'Return help output for knife CLIENT'
        Write-Verbose $Msg
        Write-Output $Here_CLIENT
    }
    CONFIGURE {
        $Msg = 'Return help output for knife CONFIGURE'
        Write-Verbose $Msg
        Write-Output $Here_CONFIGURE
    }
    COOKBOOK {
        $Msg = 'Return help output for knife COOKBOOK'
        Write-Verbose $Msg
        Write-Output $Here_COOKBOOK
    }
    COOKBOOK_SITE {
        $Msg = 'Return help output for knife COOKBOOK_SITE'
        Write-Verbose $Msg
        Write-Output $Here_COOKBOOK_SITE
    }
    DATA_BAG {
        $Msg = 'Return help output for knife DATA_BAG'
        Write-Verbose $Msg
        Write-Output $Here_DATA_BAG
    }
    EC2 {
        $Msg = 'Return help output for knife EC2'
        Write-Verbose $Msg
        Write-Output $Here_EC2
    }
    ENVIRONMENT {
        $Msg = 'Return help output for knife ENVIRONMENT'
        Write-Verbose $Msg
        Write-Output $Here_ENVIRONMENT
    }
    EXEC {
        $Msg = 'Return help output for knife EXEC'
        Write-Verbose $Msg
        Write-Output $Here_EXEC
    }
    HELP {
        $Msg = 'Return help output for knife HELP'
        Write-Verbose $Msg
        Write-Output $Here_HELP
    }
    INDEX {
        $Msg = 'Return help output for knife INDEX'
        Write-Verbose $Msg
        Write-Output $Here_INDEX
    }
    JOB {
        $Msg = 'Return help output for knife JOB'
        Write-Verbose $Msg
        Write-Output $Here_JOB
    }
    KNIFE {
        $Msg = 'Return help output for knife KNIFE'
        Write-Verbose $Msg
        Write-Output $Here_KNIFE
    }
    NODE {
        $Msg = 'Return help output for knife NODE'
        Write-Verbose $Msg
        Write-Output $Here_NODE
    }
    NULLCMD {
        $Msg = 'Return help output for knife NULLCMD'
        Write-Verbose $Msg
        Write-Output $Here_NULLCMD
    }
    OPSCODE_PRIVATE {
        $Msg = 'Return help output for knife OPSCODE_PRIVATE'
        Write-Verbose $Msg
        Write-Output $Here_OPSCODE_PRIVATE
    }
    OSC {
        $Msg = 'Return help output for knife OSC'
        Write-Verbose $Msg
        Write-Output $Here_OSC
    }
    PATH_BASED {
        $Msg = 'Return help output for knife PATH_BASED'
        Write-Verbose $Msg
        Write-Output $Here_PATH_BASED
    }
    RAW {
        $Msg = 'Return help output for knife RAW'
        Write-Verbose $Msg
        Write-Output $Here_RAW
    }
    RECIPE {
        $Msg = 'Return help output for knife RECIPE'
        Write-Verbose $Msg
        Write-Output $Here_RECIPE
    }
    REHASH {
        $Msg = 'Return help output for knife REHASH'
        Write-Verbose $Msg
        Write-Output $Here_REHASH
    }
    ROLE {
        $Msg = 'Return help output for knife ROLE'
        Write-Verbose $Msg
        Write-Output $Here_ROLE
    }
    SEARCH {
        $Msg = 'Return help output for knife SEARCH'
        Write-Verbose $Msg
        Write-Output $Here_SEARCH
    }
    SERVE {
        $Msg = 'Return help output for knife SERVE'
        Write-Verbose $Msg
        Write-Output $Here_SERVE
    }
    SPORK {
        $Msg = 'Return help output for knife SPORK'
        Write-Verbose $Msg
        Write-Output $Here_SPORK
    }
    SSH {
        $Msg = 'Return help output for knife SSH'
        Write-Verbose $Msg
        Write-Output $Here_SSH
    }
    SSL {
        $Msg = 'Return help output for knife SSL'
        Write-Verbose $Msg
        Write-Output $Here_SSL
    }
    STATUS {
        $Msg = 'Return help output for knife STATUS'
        Write-Verbose $Msg
        Write-Output $Here_STATUS
    }
    SUPERMARKET {
        $Msg = 'Return help output for knife SUPERMARKET'
        Write-Verbose $Msg
        Write-Output $Here_SUPERMARKET
    }
    TAG {
        $Msg = 'Return help output for knife TAG'
        Write-Verbose $Msg
        Write-Output $Here_TAG
    }
    USER {
        $Msg = 'Return help output for knife USER'
        Write-Verbose $Msg
        Write-Output $Here_USER
    }
    VAULT {
        $Msg = 'Return help output for knife VAULT'
        Write-Verbose $Msg
        Write-Output $Here_VAULT
    }
    WINDOWS {
        $Msg = 'Return help output for knife WINDOWS'
        Write-Verbose $Msg
        Write-Output $Here_WINDOWS
    }
    WINRM {
        $Msg = 'Return help output for knife WINRM'
        Write-Verbose $Msg
        Write-Output $Here_WINRM
    }
    WSMAN {
        $Msg = 'Return help output for knife WSMAN'
        Write-Verbose $Msg
        Write-Output $Here_WSMAN
    }

}


<#

$TextInfo = (Get-Culture).TextInfo

$Commands | Foreach-Object {
    #$TextInfo.ToTitleCase($_.ToLower())
    $TextInfo.ToLower($_)
}


((Get-Variable here*).Name) | foreach-Object {    
$Label = $($_-Replace("here_",$Null))
"$Label {
    `$Msg = 'Return help output for knife command '$($TextInfo.ToLower($Label))''
    Write-Verbose `$Msg
    Write-Output `$$_
}"
} | Clip

#>

}


