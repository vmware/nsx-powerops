function Send-Email ($ConnectionProfile){
    #dot source our utils script.
    . $myDirectory\util.ps1
    Read-Config | out-null
    $DefaultNSXConnection = $NsxConnection
    #$currentConnectionProfile = $(if(!$DefaultNSXConnection){"N/A"} else {foreach($key in $config.profiles.GetEnumerator() | ?{$_.value.NSXServer -eq $DefaultNSXConnection.Server}){$key.name}})
    #$currentConnectionProfile = "email-test"
    [String]$currentConnectionProfile = $ConnectionProfile
    #$fromEmailAddress = Read-Host -Prompt "Enter the Email address that needs to appear in From"
    #$toEmailAddress = Read-Host -Prompt "Enter the destination Email address"
    #$smtpUserName = Read-Host -Prompt "[Optional] Enter username if required by SMTP server"
    #if ($smtpUserName) {$smptUserPassword = Read-Host -AsSecureString "Enter password for $smtpUsername"}
    $fromEmailAddress = $($Config.Profiles["$currentConnectionProfile"].fromEmailAddress)
    $toEmailAddress = $($Config.Profiles["$currentConnectionProfile"].toEmailAddress)
    $smtpUserName = $($Config.Profiles["$currentConnectionProfile"].smtpUserName)
    $smptUserPassword = $($Config.Profiles["$currentConnectionProfile"].smptUserPassword)
    $date= Get-Date -format d
    $Subject = "NSX-PowerOps Auto Generated Documents on $date"

    $body = "Auto generated files"
    #$documentLocation = $currentdocumentpath
    #$documentLocation = "C:\NSX-PowerOps\NSX-PowerOps-DFW2Excel2\nsx-powerops\Report\2017-11-21_15-21\"

    #$smtpServer = Read-Host -Prompt "Enter the SMTP server address"
    $smtpServer = $($Config.Profiles["$currentConnectionProfile"].smtpServer)

    $zipFileLocation = $DocumentLocation+".zip"
    Write-host "Zip file name is: $zipFileLocation"
    Compress-Archive -Path $DocumentLocation -DestinationPath $zipFileLocation

    write-host "To email is: $toEmailAddress"
    write-host "smtpServer is: $smtpServer"

    try { 
        Write-Verbose "[TRY] Sending a test email" -Verbose
        send-mailmessage -from $fromEmailAddress -to $toEmailAddress -subject $Subject -priority  High -dno onSuccess, onFailure -smtpServer  $smtpServer -Body $body -Attachments $ZipFileLocation -ErrorAction Stop
    }
    catch {
        throw "Email could not be sent."
    }

    <#
    try { 
        
        #Get NSX details.
        $NewEmailProfile = @{
            "FromEmailAddress" = $fromEmailAddress
            "ToEmailAddress" = $toEmailAddress   
            "SMTPServer" = $smtpServer
            }

        Do { 
            $EmailProfileName = Read-host -default $toEmailAddress "Enter a unique email profile name." 
        } while ( ($Config.emailProfiles) -and ($Config.emailProfiles.Contains($EmailProfileName) ))

        $message  = "Passwords can be securely saved to disk, but will be accessible to anyone logged onto this machine as the current user.  Interactive plugins will prompt for password if its not saved as part of the connection profile, but scheduled plugins will not be able to use this connection profile if passwords are not saved."
        $question = "Save passwords?"
        $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)

        if ($decision -eq 0) {
            $NewEmailProfile.Add("SmtpUserPassword",$($smptUserPassword | ConvertFrom-SecureString )) 
        }

        if ( $Config.EmailProfiles) { 
            $script:Config.EmailProfiles.Add($EmailProfileName, $NewEmailProfile)
        }
        else {
            $script:Config = @{
                "Profiles" = @{}
            }
            $script:Config.EmailProfiles.Add($EmailProfileName, $NewEmailProfile)
        }
        
        $message  = "The default email profile is used when automated documentation is generated."
        $question = "Set this profile as the default?"
        $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)

        if ($decision -eq 0) {
            $Config.DefaultEmailProfile = $EmailProfileName

        }
        Save-Config | out-null

    }
    catch {

        throw "Failed creating email profile:  $_"
    }
    #>
}