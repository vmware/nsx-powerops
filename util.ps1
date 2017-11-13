# Utilities module:
# - Menu system
# - Connection profile handling
# - Misc reusable functions

$script:yesnochoices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
$script:yesnochoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
$script:yesnochoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

function ReleaseObject {

    # Used to release and GC com objects - need to properly clean up excel process.
    param (
        $Obj
    )

    Try {
        $intRel = 0
        Do { 
            $intRel = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Obj)
        } While ($intRel -gt  0)
    }
    Catch {
        throw "Error releasing object: $_"
    }
    Finally {
        [System.GC]::Collect()
       
    }
}
function out-event { 
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline=$true)]
            [string]$message,
        [Parameter()]        
            [ValidateSet("information", "warning", "error")]
            [string]$entrytype = "information",
        [Parameter()]
            [switch]$WriteToEventLog
    )
    #Simple logging/output function
    if ( $WriteToEventLog ) { 
        Write-EventLog -Message $message -EntryType $entrytype -ErrorAction Ignore
    }    
    switch ( $entrytype ) {
        "information" { write-host $message } 
        "warning" { write-warning $message } 
        "error" { write-error $message } 
    }
}

function Show-MenuV2 { 
    
    <#
    .SYNOPSIS
    Displays a menu that provides nesting of menu items, arbitrary script
    block execution, status handling input handling

    .DESCRIPTION
    Provides a simple template based menu function.  The user defines a series
    of 'MenuItems' - hashtables of an expected format (see examples for detail)
    - that allow a menu of choices consisting of nested menus, or individual 
    items that execute an arbitrary scriptblock to be shown to the user.

    Menuitems have an enabled property that can be toggled at runtime, 
    allowing code executed in one menuitem to influence another.

    Simple Header and subheader value and color properties allow the menu to
    be customised at runtime, and a footer property allows the user to define 
    a scriptblock that returns a string that is executed every time the menu is 
    redrawn that allows for a simple feedback loop of 'state' if required.

    .EXAMPLE

    #Defines a simple menu consisting of a Header and subheader

    $MainHeader = "Menu Test Header"
    $Subheader = "Menu Test SubHeader"

    $Configuration = @{ 
        "Script" = { show-menu -menu $Configuration | out-null };
        "Status" = "EnabledInvalid";
        "StatusText" = "Not completed"
        "Name" = "Configuration";
        "HelpText" = "Nothing"
        "Items" = @( 
            @{
                "Enabled" = $true;
                "Status" = "UnselectedInvalid";
                "StatusText" = "UNSELECTED"
                "Name" = "Enable Processing";
                "Script" = { 
                    $Processing.Enabled = $true
                    $script:Configured = $true
                    return "Processing Enabled"
                } 
            }
        )
    }

    $Processing = @{ 
        "Script" = { show-menu -menu $Processing | out-null };
        "Status" = "Disabled";
        "Name" = "Processing";
        "HelpText" = "Need to enable me first"
        "Items" = @( 
            @{
                "Enabled" = $true;
                "Name" = "get-date";
                "Script" = { $script:CurrentDate = get-date } 
            }
        )
    }

    $rootmenu = @{ 
        "Name" = "Root Menu";
        "Status"= "MenuInvalid"
        "Items" = @( 
            $Configuration,
            $Processing
        )
    }

    $Footer = { 
        "Configured : $($Configured)`nCurrent Date : $($CurrentDate)"
    }

    show-menu -menu $rootmenu

    #>

    [CmdletBinding()]
    param (
        [string]$MainHeader=$MainHeader,
        [string]$Subheader=$Subheader,
        [hashtable]$menu,
        [string]$HeaderColor="Green",
        [string]$SubheaderColor="Green",
        [string]$MenuItemColor="White",
        [string]$FooterColor="Green",
        [string]$FooterTextColor="Green",
        [string]$MenuTitleColor="Yellow",
        [string]$MenuEnabledItemColor="White",
        [string]$MenuDisabledItemColor="DarkGray",
        [string]$MenuItemSelectedColor="DarkGreen",
        [string]$MenuItemIncompleteColor="Yellow",
        [string]$PromptColor="Yellow",
        [string]$ScriptStatusTextColor = "DarkGreen"
    )

    if ( $memu.items.count -gt 10 ) { throw "Too many items in menu - whinge at bradford. "}
    if ( -not ($menu.Name -and $menu.MainHeader -and $Menu.SubHeader -and $menu.Footer -and ($menu.Footer -is [ScriptBlock]) )) { throw "Specified menu object is not valid" }
    if ( $menu.status -and ($menu.status -isnot [scriptblock]) ) { throw "Specified menu object has an invalid status type: $($menu.status.gettype())"}
    if ( $menu.statustext -and ($menu.statustext -isnot [scriptblock]) ) { throw "Specified menu object has an invalid statustext type: $($menu.statustext.gettype())"}
    
    $keyvalid = $false
    $status = ""
    $statuscolor = "white"
    if ( -not $script:breadcrumb ) {
        $script:breadcrumb = New-Object System.Collections.Arraylist
    }
    $script:breadcrumb.add($menu.Name) | out-null

    while ( -not $menuexit ) { 

        $ConsoleWidth = (Get-host).ui.RawUI.windowsize.width

        clear-host
        write-host -foregroundcolor $HeaderColor ( "*" * $ConsoleWidth )  
        write-host -foregroundcolor $HeaderColor $Menu.MainHeader
        if ( $subheader) { 
            write-host -foregroundcolor $SubheaderColor $Menu.subheader 
        }
        write-host -foregroundcolor $HeaderColor ( "*" * $ConsoleWidth + "`n" )  
        write-host -foregroundcolor $MenuTitleColor "$($breadcrumb -join(" > "))`n"
        for ( $index=0; $index -lt ($menu.items.count ); $index++ ) { 

            $BaseItemText = $menu.items[$index].Name
            $Column2Width = 40
            $Column1Width = $ConsoleWidth - $Column2Width - 10

            switch ( $menu.items[$index].Status.invoke() ) {

                "Disabled" { 
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "DISABLED"
                    }
                    $OutputColor = $MenuDisabledItemColor 
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]" 
                }

                "UnselectedInvalid" { 
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "INVALID"
                    }
                    $OutputColor = $MenuItemColor
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]" 
                }
                
                "UnselectedValid" { 
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "UNSELECTED"
                    }
                    $OutputColor = $MenuItemColor
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]" 
                }
                
                "SelectedValid" {
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "SELECTED"
                    } 
                    $OutputColor = $MenuItemSelectedColor
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]"
                }
                
                "SelectedInvalid" {
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "INVALID"
                    } 
                    $OutputColor = $MenuItemIncompleteColor
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]"
                }
                
                "MenuValid" {
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "VALID"
                    } 
                    $OutputColor = $MenuItemColor
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]"
                }
                
                "MenuInvalid" { 
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "INVALID"
                    }
                    $OutputColor = $MenuItemIncompleteColor
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]"
                }

                "MenuEnabled" { 
                    if ( $menu.items[$index].StatusText ) { 
                        $ItemStatusText = $menu.items[$index].StatusText.invoke()
                    }
                    else {
                        $ItemStatusText = "ENABLED"
                    }
                    $OutputColor = $MenuEnabledItemColor
                    $ItemText = "{0,-$Column1Width }{1,-$Column2Width}" -f "$($index + 1) - $BaseItemText"," [  $ItemStatusText  ]"
                }

                default { throw "Unknown menu item status : $_"}


            }

            #Output the item:
            write-host -foregroundcolor $OutputColor $ItemText

        }
        if ( $menu.footer ) { 
            $FooterString = &$Menu.footer

            write-host -foregroundcolor $FooterColor ( "`n" + "*" * $ConsoleWidth )
            write-host -foregroundcolor $FooterTextColor $Footerstring
            write-host -foregroundcolor $FooterColor ( "*" * $ConsoleWidth + "`n" )
        }

        write-host -foregroundcolor $PromptColor "Enter the number of your choice, h to get item specific help, x to go back or q to quit."
        write-host -foregroundcolor $statuscolor $status

        $key = [console]::ReadKey($true) 
        switch ( $key.keychar.toString() ) {
            "x" { $menuexit = $true }
            "q" { $script:allmenuexit = $true }
            "h" { 
                do { 
                    write-host "Enter Item number to get related help for:"
                    $helpitem = ([console]::ReadKey($true)).keychar.toString()
                    if ( ( 1..$menu.items.count ) -contains $helpitem ) { 
                        $statuscolor = "Yellow"
                        if ( $menu.items[$([int]$helpitem - 1)].HelpText ) { 
                            $status = "`n>>>: $($menu.items[$([int]$helpitem - 1)].HelpText)"
                        }
                        else {
                            $status = "`n>>>: No help available"
                        }
                    }
                } while ( -not ( ( 1..$menu.items.count ) -contains $helpitem ))
            }
            default {
                if ( ( 1..$menu.items.count ) -contains $_ ) { 
                    #Valid selection
                    if ( $menu.items[$($_ - 1)].Status -ne "Disabled" ) { 
                        if ( $menu.items[$($_ - 1)].Interactive ) { 
                            Write-Host -ForegroundColor $ScriptStatusTextColor "You have selected # '$_'. $($menu.items[$($_ - 1)].name)" 
                        }
                        $script:SelectedItemNumber = [int]($_ - 1)
                        $status = &$menu.items[$($_ - 1)].script
                        $statuscolor = "White"
                        if ( $menu.items[$($_ - 1)].Interactive ) { 
                            Write-Host -ForegroundColor $ScriptStatusTextColor "Done.  Hit any key to continue."
                            $key = [console]::ReadKey($true) 
                        }
                    }
                    else { 
                        $statuscolor = "Yellow"
                        $status = "Option not available. $($menu.items[$($_ - 1)].HelpText)"

                    }
                }
                else { 
                    $statuscolor = "Red"
                    $status = "Invalid choice $_"
                }
            }
        }

        if ( $script:allmenuexit ) { return }
    }

    $script:breadcrumb.RemoveAt($breadcrumb.count - 1 )
}

function Remove-ConnectionProfile {
    
    #vSphere Config Menu Item 2
    $ConnectionProfileMenu = @{ 
        "Script" = {}
        "Status" = { "MenuEnabled" } 
        "Name" = "Delete Connection Profile"
        "HelpText" = "Deletes an existing connection profile"
        "MainHeader" = $MainHeader
        "Subheader" = $Subheader
        "Footer" = $footer
        "Items" = New-Object System.Collections.Arraylist
    }
    foreach ( $profilename in $Config.Profiles.Keys ) {
        $ConnectionProfileMenu.Items.Add(
            @{ 
                "Name" = $ProfileName; "Status" = {"UnselectedValid"}; "StatusText" = {"Select to Delete"}; "Script" = { 
                    $Config.Profiles.Remove($ConnectionProfileMenu.Items[$SelectedItemNumber].name)
                    if ( $ConnectionProfileMenu.Items[$SelectedItemNumber].name -eq $config.DefaultProfile ){
                        $Config.DefaultProfile = ''
                    }
                    Save-Config
                    #Exit the menu
                    set-variable -scope 1 -name menuexit -value $true
                    "Removed Connection Profile $ProfileName"
                }
            } 
        ) | out-null
    }
    show-menuv2 -menu $ConnectionProfileMenu | out-null
}

function Set-DefaultConnectionProfile {
    
    $ConnectionProfileMenu = @{ 
        "Script" = {}
        "Status" = { "MenuEnabled" }
        "Name" = "Set Default Connection Profile"
        "HelpText" = "Sets an existing connection profile as default"
        "MainHeader" = $MainHeader
        "Subheader" = $Subheader
        "Footer" = $footer
        "Items" = New-Object System.Collections.Arraylist
    }
    foreach ( $profilename in $Config.Profiles.Keys ) {
        $ConnectionProfileMenu.Items.Add(
            @{ 
                "Name" = $ProfileName
                "Status" = {
                    if ($ProfileName -eq $config.DefaultProfile) {
                        "SelectedValid"
                    } 
                    else { 
                        "UnselectedValid"
                    }
                }
                "StatusText" = {
                    if ($ProfileName -eq $config.DefaultProfile) { 
                        "Default" 
                    }
                    else {
                        "Select"
                    }
                }
                "Script" = { 
                    $Config.DefaultProfile = $ConnectionProfileMenu.Items[$SelectedItemNumber].name
                    Save-Config
                    #Exit the menu
                    set-variable -scope 1 -name menuexit -value $true
                    "Set Default Connection Profile $ProfileName"
                }
            } 
        ) | out-null
    }
    show-menuv2 -menu $ConnectionProfileMenu | out-null
}

function Get-ProfileConnection {

    param ( 
        [string]$profileName=$config.DefaultProfile
    )

    write-host -foregroundcolor cyan "Using connection profile $profileName"

    $nsxserver = $config.profiles.$profileName.NsxServer
    $nsxusername = $config.profiles.$profileName.NsxUsername
    $viusername = $config.profiles.$profileName.viusername
    $nsxusername = $config.profiles.$profileName.NsxUsername

    if ( $config.profiles.$profileName.nsxpassword ) { 
        $nsxcred = New-Object System.Management.Automation.PSCredential $nsxusername, ($config.profiles.$profileName.nsxpassword | convertto-securestring)
    }
    else { 
        $nsxCred = Get-Credential -message "NSX Credentials for $NsxServer" -username $NsxUsername
    }

    if ( $config.profiles.$profileName.vipassword ) { 
        $vicred = New-Object System.Management.Automation.PSCredential $viusername, ($config.profiles.$profileName.vipassword | convertto-securestring)
    }
    else { 
        $viCred = Get-Credential -message "vCenter Credentials" -username $viusername
    }
    
    $conn = Connect-NsxServer -DefaultConnection:$false -ViDefaultConnection:$false -server $nsxserver -cred $nsxCred -vicred $viCred -ViWarningAction Ignore

    $conn        
}

function Get-ProfileEsxiCreds {

    param ( 
        [string]$profileName=$config.DefaultProfile
    )


    if ( $config.profiles.$profileName.defaultHostUserName ) {

        write-host -foregroundcolor cyan "Using ESXi credentials from connection profile $profileName"
        $username = $config.profiles.$profileName.defaultHostUserName
        $password = $config.profiles.$profileName.defaultHostPassword
        if ( $password ) { 
            $cred = New-Object System.Management.Automation.PSCredential $username, ($password | convertto-securestring)
        }
        else {
            $cred = New-Object System.Management.Automation.PSCredential $username, (New-Object System.Security.SecureString)
        }
    }
    else { 
        write-host -foregroundcolor Yellow "No ESXi credentials saved in connection profile $profileName"
        $cred = Get-Credential -message "Default ESXi Host Credentials"
    }
    
    $cred        
}

function Get-ProfileControllerCreds {

    param ( 
        [string]$profileName=$config.DefaultProfile
    )


    if ( $config.profiles.$profileName.ctrlpassword ) {

        write-host -foregroundcolor cyan "Using NSX Controller credentials from connection profile $profileName"
        $username = "admin"
        $password = $config.profiles.$profileName.ctrlpassword
        $cred = New-Object System.Management.Automation.PSCredential $username, ($password | convertto-securestring)
    }
    else { 
        write-host -foregroundcolor Yellow "No NSX Controller credentials saved in connection profile $profileName"
        $cred = Get-Credential -message "NSX Controller Credentials" -username "admin"
    }
    
    $cred        
}

function Save-Config {
    
    $configfile = 'config.ps1'
    if ( test-path $configfile ) { 

        $message  = "Existing config found on disk."
        $question = "Update with current config?"
        $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)
    
    }    
    else { $decision = 0 } 
    if ($decision -eq 0) {

        $outobj = [pscustomobject]@{
        
            '_configdate' = get-date -format yyyy_M_d_HH_mm
            "config" = $Config
        }
        
        $outobj | convertto-pson | set-content $configfile
        "Saved current config to $configfile"
    }
}

function Read-Config {

    $configfile = "$MyDirectory\config.ps1"
    write-progress -Activity "Loading from Config $($inobj._configdate) in file $configfile"
    
    if ( test-path $configfile ) { 
        try { 

            $inobj =  & $configfile
            $script:Config = $inobj.config
            write-progress -Activity "Loading from Config $($inobj._configdate) in file $configfile" -Completed
        }
        catch {
            throw "An error occured loading config from $configfile.  $_"
        }
    }
}

function New-ConnectionProfile {

    Read-Config | out-null

    $nsxserver = read-hostwithdefault -default $default_nsxserver "Enter NSX server address"
    $nsxusername = read-hostwithdefault -default $default_nsxusername "Enter NSX username"
    $nsxpassword = read-host -assecurestring "Enter NSX password"
    $viusername = read-hostwithdefault -default $default_viusername "Enter vCenter username"
    $vipassword = read-host -assecurestring "Enter vCenter Password"
    $nsxcred = New-Object System.Management.Automation.PSCredential $nsxusername, $nsxpassword
    $vicred = New-Object System.Management.Automation.PSCredential $viusername, $vipassword

    try { 
        $NsxConnection  = Connect-NsxServer -nsxserver $nsxserver -Credential $nsxcred -viCred $vicred -VIDefaultConnection:$false -DefaultConnection:$false -erroraction Stop -ViWarningAction ignore

        #Get NSX details.
        $NewProfile = @{
            "NsxServer" = $nsxserver
            "nsxusername" = $nsxusername            
            "viusername" = $viusername
        }

        Do { 
            $ProfileName = Read-hostwithdefault -default $nsxserver "Enter a unique connection profile name." 
        } while ( ($Config.Profiles) -and ($Config.Profiles.Contains($ProfileName) ))

        $message  = "Passwords can be securely saved to disk, but will be accessible to anyone logged onto this machine as the current user.  Interactive plugins will prompt for password if its not saved as part of the connection profile, but scheduled plugins will not be able to use this connection profile if passwords are not saved."
        $question = "Save passwords?"
        $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)

        if ($decision -eq 0) {
            $NewProfile.Add("nsxpassword",$($nsxpassword | ConvertFrom-SecureString )) 
            $NewProfile.Add("vipassword", $($vipassword | ConvertFrom-SecureString))

            #Controller Details
            $message  = "Some plugins such as the healthcheck plugin require ssh connectivity to the NSX controllers.  It is not mandatory to include these credentials in a connection profile.  Any plugin that requires them will prompt interactively for them if they arent included in the selected connection profile."
            $question = "Enter NSX Controller Credentials?"
            $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)

            if ($decision -eq 0) {
                $ctrlpassword = read-host -assecurestring "Enter NSX Controller Password"
                $NewProfile.Add("ctrlpassword",$($ctrlpassword | ConvertFrom-SecureString )) 
            }

            #Host Details
            $message  = "Some plugins such as the healthcheck plugin require ssh connectivity to ESXi Hosts.  It is not mandatory to include these credentials in a connection profile.  Any plugin that requires them will prompt interactively for them if they arent included in the selected connection profile."
            $question = "Enter ESXi Host Credentials?"
            $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)

            if ($decision -eq 0) {
                $hostusername = read-host "Enter ESXi Host Username"
                $hostpassword = read-host -assecurestring "Enter ESXi Host Password"
                $NewProfile.Add("defaultHostUserName", $hostusername)
                try {
                    $NewProfile.Add("defaultHostPassword",$($hostpassword | ConvertFrom-SecureString ))
                }
                catch {
                    $NewProfile.Add("defaultHostPassword","")
                }
            }
        }

        if ( $Config.Profiles) { 
            $script:Config.Profiles.Add($ProfileName, $NewProfile)
        }
        else {
            $script:Config = @{
                "Profiles" = @{}
            }
            $script:Config.Profiles.Add($ProfileName, $NewProfile)
        }

        $message  = "The default connection profile populates the default connection details for all interactive plugins."
        $question = "Set this profile as the default?"
        $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)

        if ($decision -eq 0) {
            $Config.DefaultProfile = $ProfileName

        }
        Save-Config | out-null

    }
    catch {

        "Failed creating connection profile.  $_"
    }
}

function read-hostwithdefault { 

    param(

        [string]$Default,
        [string]$Prompt
    )
    
    if ($default) {
        $response = read-host -prompt "$Prompt [$Default]"
        if ( $response -eq "" ) {
            $Default
        }
        else {
            $response
        }
    }
    else { 
        read-host -prompt $Prompt
    }
}

function ConvertTo-PSON {
    <#
    .SYNOPSIS
    creates a powershell object-notation script that generates the same object data
    .DESCRIPTION
    This produces 'PSON', the powerShell-equivalent of JSON from any object you pass to it. It isn't suitable for the huge objects produced by some of the cmdlets such as Get-Process, but fine for simple objects
    .EXAMPLE
    $array=@()
    $array+=Get-Process wi* |  Select-Object Handles,NPM,PM,WS,VM,CPU,Id,ProcessName 
    ConvertTo-PSON $array

    .PARAMETER Object 
    the object that you want scripted out
    .PARAMETER Depth
    The depth that you want your object scripted to
    .PARAMETER Nesting Level
    internal use only. required for formatting
    #>
    
    #Been looking for this for some time ;)
    #From https://raw.githubusercontent.com/Phil-Factor/ConvertToPSON/master/ConvertTo-PSON.ps1

    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        $inputObject,
        [parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
        [int]$depth = 16,
        [parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
        [int]$NestingLevel = 1,
        [parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
        [int]$XMLAsInnerXML = 0
    )
    
    BEGIN { }
    PROCESS
    {
        If ($inputObject -eq $Null) { $p += '$Null'; return $p } # if it is null return null
        $padding = [string]'  ' * $NestingLevel # lets just create our left-padding for the block
        $ArrayEnd = 0; #until proven false
        try
        {
            $Type = $inputObject.GetType().Name # we start by getting the object's type
            if ($Type -ieq 'Object[]') { $Type = "$($inputObject.GetType().BaseType.Name)" } # see what it really is
            if ($depth -ilt $NestingLevel) { $Type = 'OutOfDepth' } #report the leaves in terms of object type
            elseif ($Type -ieq 'XmlDocument' -or $Type -ieq 'XmlElement')
            {
                if ($XMLAsInnerXML -ne 0) { $Type = 'InnerXML' }
                else
                { $Type = 'XML' }
            } # convert to PS Alias
            # prevent these values being identified as an object
            if (@('boolean', 'byte', 'char', 'datetime', 'decimal', 'double', 'float', 'single', 'guid', 'int', 'int32',
            'int16', 'long', 'int64', 'OutOfDepth', 'RuntimeType', 'PSNoteProperty', 'regex', 'sbyte', 'string',
            'timespan', 'uint16', 'uint32', 'uint64', 'uri', 'version', 'void', 'xml', 'datatable', 'Dictionary`2'
            'SqlDataReader', 'datarow', 'ScriptBlock', 'type') -notcontains $type)
            {
                if ($Type -ieq 'OrderedDictionary') { $Type = 'HashTable' }
                elseif ($Type -ieq 'List`1') { $Type = 'Array' }
                elseif ($Type -ieq 'PSCustomObject') { $Type = 'PSObject' } #
                elseif ($inputObject -is "Array") { $Type = 'Array' } # whatever it thinks it is called
                elseif ($inputObject -is "HashTable") { $Type = 'HashTable' } # for our purposes it is a hashtable
                elseif ($inputObject -is "Generic") { $Type = 'DotNotation' } # for our purposes it is a hashtable
                #elseif ((gm -inputobject $inputObject -membertype Methods | Select name|where name -like 'GetEnumerator') -ne $null) { $Type = 'HashTable' }
                elseif (($inputObject | gm -membertype Properties | Select name | Where name -like 'Keys') -ne $null) { $Type = 'DotNotation' } #use dot notation
                elseif (($inputObject | gm -membertype Properties | Select name).count -gt 1) { $Type = 'Object' }
            }
            write-verbose "$($padding)Type:='$Type', Object type:=$($inputObject.GetType().Name), BaseName:=$($inputObject.GetType().BaseType.Name) $NestingLevel "
            switch ($Type)
            {
                'ScriptBlock'{ "[$type] {$($inputObject.ToString())}" }
                'InnerXML'        { "[$type]@'`r`n" + ($inputObject.OuterXMl) + "`r`n'@`r`n" } # just use a 'here' string
                'DateTime'   { "[datetime]'$($inputObject.ToString('s'))'" } # s=SortableDateTimePattern (based on ISO 8601) local time
                'Boolean'    {
                    "[bool] $(&{
                        if ($inputObject -eq $true) { "`$True" }
                        Else { "`$False" }
                    })"
                }
                'string'     {
                    if ($inputObject -match '[\r\n]') { "@'`r`n$inputObject`r`n'@" }
                    else { "'$($inputObject -replace '''', '''''')'" }
                }
                'Char'       { [int]$inputObject }
                { @('byte', 'decimal', 'double', 'float', 'single', 'int', 'int32', 'int16', 'long', 'int64', 'sbyte', 'uint16', 'uint32', 'uint64') -contains $_ }
                { "$inputObject" } # rendered as is without single quotes
                'PSNoteProperty' { "$(ConvertTo-PSON -inputObject $inputObject.Value -depth $depth -NestingLevel ($NestingLevel))" }
                'Array'      { "`r`n$padding@(" + ("$($inputObject | ForEach { $ArrayEnd = 1; ",$(ConvertTo-PSON -inputObject $_ -depth $depth -NestingLevel ($NestingLevel + 1))" })".Substring($ArrayEnd)) + "`r`n$padding)" }
                'HashTable'  { "`r`n$padding@{" + ("$($inputObject.GetEnumerator() | ForEach { $ArrayEnd = 1; "; '$($_.Name)' = " + (ConvertTo-PSON -inputObject $_.Value -depth $depth -NestingLevel ($NestingLevel + 1)) })".Substring($ArrayEnd) + "`r`n$padding}") }
                'PSObject'   { "`r`n$padding[pscustomobject]@{" + ("$($inputObject.PSObject.Properties | ForEach { $ArrayEnd = 1; "; '$($_.Name)' = " + (ConvertTo-PSON -inputObject $_ -depth $depth -NestingLevel ($NestingLevel + 1)) })".Substring($ArrayEnd) + "`r`n$padding}") }
                'Dictionary' { "`r`n$padding@{" + ($inputObject.item | ForEach { $ArrayEnd = 1; '; ' + "'$_'" + " = " + (ConvertTo-PSON -inputObject $inputObject.Value[$_] -depth $depth -NestingLevel $NestingLevel+1) }) + '}' }
                'DotNotation'{ "`r`n$padding@{" + ("$($inputObject.Keys | ForEach { $ArrayEnd = 1; ";  $_ =  $(ConvertTo-PSON -inputObject $inputObject.$_ -depth $depth -NestingLevel ($NestingLevel + 1))" })".Substring($ArrayEnd) + "`r`n$padding}") }
                'Dictionary`2'{ "`r`n$padding@{" + ("$($inputObject.GetEnumerator() | ForEach { $ArrayEnd = 1; "; '$($_.Key)' = " + (ConvertTo-PSON -inputObject $_.Value -depth $depth -NestingLevel ($NestingLevel + 1)) })".Substring($ArrayEnd) + "`r`n$padding}") }
                'Object'     { "`r`n$padding@{" + ("$($inputObject | Get-Member -membertype properties | Select-Object name | ForEach { $ArrayEnd = 1; ";  $($_.name) =  $(ConvertTo-PSON -inputObject $inputObject.$($_.name) -depth $NestingLevel -NestingLevel ($NestingLevel + 1))" })".Substring($ArrayEnd) + "`r`n$padding}") }
                'XML'        { "`r`n$padding@{" + ("$($inputObject | Get-Member -membertype properties | where name -ne 'schema' | Select-Object name | ForEach { $ArrayEnd = 1; ";  $($_.name) =  $(ConvertTo-PSON -inputObject $inputObject.$($_.name) -depth $depth -NestingLevel ($NestingLevel + 1))" })".Substring($ArrayEnd) + "`r`n$padding}") }
                'Datatable'  { "`r`n$padding@{" + ("$($inputObject.TableName)=`r`n$padding @(" + "$($inputObject | ForEach { $ArrayEnd = 1; ",$(ConvertTo-PSON -inputObject $_ -depth $depth -NestingLevel ($NestingLevel + 1))" })".Substring($ArrayEnd) + "`r`n$padding  )`r`n$padding}") }
                'DataRow'    { "`r`n$padding@{" + ("$($inputObject | Get-Member -membertype properties | Select-Object name | ForEach { $ArrayEnd = 1; "; $($_.name)=  $(ConvertTo-PSON -inputObject $inputObject.$($_.name) -depth $depth -NestingLevel ($NestingLevel + 1))" })".Substring($ArrayEnd) + "}") }
                default { "'$inputObject'" }
            }
        }
        catch
        {
            write-error "Error'$($_)' in script $($_.InvocationInfo.ScriptName) $($_.InvocationInfo.Line.Trim()) (line $($_.InvocationInfo.ScriptLineNumber)) char $($_.InvocationInfo.OffsetInLine) executing $($_.InvocationInfo.MyCommand) on $type object '$($inputObject.Name)' Class: $($inputObject.GetType().Name) BaseClass: $($inputObject.GetType().BaseType.Name) "
        }
        finally { }
    }
    END { }
}

function New-PowerOpsScheduledJob {
    
    param (
        $profilename,
        $ScheduledTaskBaseName = "Nsx-PowerOps"
    )

    $CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    if ( -not ( ([Security.Principal.WindowsPrincipal]$CurrentUser).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) { 
        Write-Event -EntryType warning "Scheduled tasks can only be created when running as Administrator.  Run PowerOps in an elevated PowerShell host to create a scheduled task."
        return
    }

    $CurrentUserPassword = Read-Host -AsSecureString "Enter password for $($currentUser.Name) for scheduled task credentials"

    write-progress -Activity "Creating Scheduled Task" -CurrentOperation "Using authentication profile: $profilename"

    #Credential is required due to the use of convertto-securestring to import encrypted passwords from file, rather
    #than being needed to allow the task to run itself...
    $taskCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $($CurrentUser.Name), $CurrentUserPassword

    #Its all in this line...
    # 1 - Command needs to be a scriptblock.  You cant create one with the normal {} otherwise variable expansion is supressed within the braces.
    # 2 - the & is PoSHes call function.  Run this Sh1t rather than treat it as a string object.
    # 3 - The actual scriptnames may contain spaces, and the quotes enclosing them need to be escaped so that they get passed to the actual command block in the resulting task.  The $ before the False needs to be escaped as well so it ends up there too.
    # 4 - It seems so simple now Im explaining it to myself... :|  Hours...
    # 5 - If you are trying to TS this crap:
    #   - $job = Get-ScheduledJob; $job.command looks like this : & "C:\Path\To\Nsx-PowerOps.ps1" -interactive:$False -profile profile-01
    #   - $result = $job.Run() to attempt exec.
    #   - $result.ChildJobs.jobstateinfo and  $result.ChildJobs.Error are quite enlightening and cant be seen from the Tasks UI...
    $command = [ScriptBlock]::Create("& `"$PowerOps`" -NonInteractive -ConnectionProfile $profilename")

    #Then create it, which is easy...
    try { 
        $trigger =  New-JobTrigger -Weekly -At $TaskTimeOfDay -DaysOfWeek $TaskDayOfWeek
        $job = Register-ScheduledJob -ScriptBlock $command -Trigger $trigger -Name $("$ScheduledTaskBaseName-$profilename") -credential $taskCred -ErrorAction Stop
        
        # Create the event log source we will need to log with.
        New-EventLog -LogName Application -Source $EventLogSource -ErrorAction Ignore

        # Create the systemprofile Desktop directory that is required for Excel/Visio to run without a logged in user.
        # See https://serverfault.com/questions/266794/when-ran-as-a-scheduled-task-cannot-save-an-excel-workbook-when-using-excel-app
         
        new-item -ItemType Directory "C:\Windows\System32\config\systemprofile\Desktop" -ErrorAction ignore
        new-item -ItemType Directory "C:\Windows\SysWOW64\config\systemprofile\Desktop" -ErrorAction ignore
    }
    catch {
        Write-event -EntryType warning "Scheduled task creation failed with the following error: $_"
    }
    write-progress -Activity "Creating Scheduled Task" -CurrentOperation "Using authentication profile: $profilename" -Completed
    
}

function Get-PowerOpsScheduledJob { 

    param (
        $profilename,
        $ScheduledTaskBaseName = "Nsx-PowerOps"
    )

    Get-ScheduledJob -Name "$ScheduledTaskBaseName-$profilename" -ErrorAction Ignore
}

function Remove-PowerOpsScheduledJob { 
    
    param (
        $profilename,
        $ScheduledTaskBaseName = "Nsx-PowerOps"
    )

    try { 
        $Task = Get-ScheduledJob -Name "$ScheduledTaskBaseName-$profilename"
        $Task | Unregister-ScheduledJob
    }catch { 
        return $false
    }
}

function Get-EnableScheduledTaskMenu { 

    #vSphere Config Menu Item 2
    $ConnectionProfileMenu = @{ 
        "Script" = {}
        "Status" = { "MenuEnabled" } 
        "Name" = "Enable/Disable PowerOps Scheduled Documentation Task"
        "MainHeader" = $MainHeader
        "Subheader" = $Subheader
        "Footer" = { "Select the connection profile to toggle automatic document creation for.  Job will be scheduled weekly at $TaskTimeOfDay $TaskTimeofWeek." }
        "Items" = New-Object System.Collections.Arraylist
    }
    foreach ( $profilename in $Config.Profiles.Keys ) {
        $ConnectionProfileMenu.Items.Add(
            @{ 
                "Name" = $ProfileName
                "Status" = {
                    if ( Get-PowerOpsScheduledJob -profilename $BaseItemText ) {
                        "SelectedValid"
                    }
                    else { 
                        "UnselectedValid"
                    }
                }
                "StatusText" = {
                    if ( Get-PowerOpsScheduledJob -profilename $BaseItemText ) {
                        "Enabled - Select to Disable"
                    }
                    else { 
                        "Not Enabled - Select to Enable"
                    }
                }
                "Script" = { 
                    if ( Get-PowerOpsScheduledJob -profilename $ConnectionProfileMenu.Items[$SelectedItemNumber].name ) {
                        Remove-PowerOpsScheduledJob -profilename $ConnectionProfileMenu.Items[$SelectedItemNumber].name
                    }
                    else {
                        New-PowerOpsScheduledJob -profilename $ConnectionProfileMenu.Items[$SelectedItemNumber].name
                    }
                }
            } 
        ) | out-null
    }
    show-menuv2 -menu $ConnectionProfileMenu -FooterTextColor "Yellow"| out-null
    
}


