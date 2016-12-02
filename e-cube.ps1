# *-------------------------------------------* #
# ********************************************* #
#      VMware NSX e-Cube by @thisispuneet       #
# This script automate NSX-v day 2 Operations   #
# and help build the env networking documents   #
# ********************************************* #
# *-------------------------------------------* #
#               Version: 1.0.4                  #
# *-------------------------------------------* #

# Import PowerNSX Module
import-module PowerNSX

function printMainMenu{
    Write-Host "   1) Install PowerNSX"
    Write-Host "   2) Connect NSX Manager and vCenter"
    Write-Host "   3) Show Documentation Menu"
    Write-Host "   4) Show Health Check Menu"
    Write-Host "   0) Exit E-Cube"
}

function printDocumentationMenu{
    Write-Host "`n *********************************************************"
    Write-Host " **              e-Cube Documentation Menu              **"
    Write-Host " *********************************************************"
    Write-Host " *                                                       *"
    Write-Host " * Enviornment Documentation                             *"
    Write-Host " * |_ 1) Document all NSX Components                     *"
    Write-Host " * |_ 2) Document ESXi Host(s) Info                      *"
    Write-Host " * |_ 3) Document NSX Enviornamnt Diagram via VISIO Tool *"
    Write-Host " * |_ 4) Import vRealie Log Insight Dashboard            *"
    Write-Host " *                                                       *"
    Write-Host " * Networking Documentation                              *"
    Write-Host " * |_ 5) Document Routing info                           *"
    Write-Host " * |_ 6) Document VxLAN info                             *"
    Write-Host " *                                                       *"
    Write-Host " * Security Documentation                                *"
    Write-Host " * |_ 7) Document NSX DFW info to Excel - DFW2Excel      *"
    Write-Host " * |_ 8) Document DFW-VAT                                *"
    Write-Host " *                                                       *"
    Write-Host " * 0) Exit Documentation Menu                            *"
    Write-Host " *********************************************************"
}

function printHealthCheckMenu{
    Write-Host "`n ********************************"
    Write-Host " **  e-Cube Health Check Menu  **"
    Write-Host " ********************************"
    Write-Host " *                              *"
    Write-Host " * 1) Check VDR Instance        *"
    Write-Host " * 2) Check VIB Version         *"
    Write-Host " *                              *"
    Write-Host " * 0) Exit Health Check Menu    *"
    Write-Host " ********************************"
}

#Install PowerNSX here
function installPowerNSX($sectionNumber){
    $userSelection = "Install PowerNSX"
    Write-Host "`n You have selected # '$sectionNumber'. Now executing '$userSelection'..."\
    $Branch="v2";$url="https://raw.githubusercontent.com/vmware/powernsx/$Branch/PowerNSXInstaller.ps1"; try { $wc = new-object Net.WebClient;$scr = try { $wc.DownloadString($url)} catch { if ( $_.exception.innerexception -match "(407)") { $wc.proxy.credentials = Get-Credential -Message "Proxy Authentication Required"; $wc.DownloadString($url) } else { throw $_ }}; $scr | iex } catch { throw $_ }
}

#Connect to NSX Manager and vCenter. Save the credentials.
function connectNSXManager($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now executing Connect with NSX Manager..."
    
    $vCenterHost = Read-Host -Prompt " Enter vCenter IP"
    $vCenterUser = Read-Host -Prompt " Enter vCenter User"
    $vCenterPass = Read-Host -Prompt " Enter vCenter Password"

    $nsxManagerHost = Read-Host -Prompt "`n Enter NSX Manager IP"
    $nsxManagerUser = Read-Host -Prompt " Enter NSX Manager User"
    $nsxManagerPass = Read-Host -Prompt " Enter NSX Manager Password"

    if ($nsxManagerHost -eq '' -or $nsxManagerUser -eq '' -or $nsxManagerPass -eq ''){
        " NSX Manager information not provided. Can't connect to NSX Manager or vCenter!"
    }
    elseif ($vCenterHost -eq '' -or $vCenterUser -eq '' -or $vCenterPass -eq ''){
        " vCenter information not provided. Can't connect to NSX Manager or vCenter!"
    }
    else{
        "Connecting with vCenter..."
        Connect-VIServer -Server $vCenterHost -User $vCenterUser -Password $vCenterPass
        "`nConnecting with NSX Manager..."
        Connect-NsxServer -Server $nsxManagerHost -User $nsxManagerUser -Password $nsxManagerPass
        "Connecting NSX Manager to vCenter..."
        Set-NsxManager -vCenterServer $vCenterHost -vCenterUserName $vCenterUser -vCenterPassword $vCenterPass
        "Done!"
    }
}

#---- Get Documentation Menu here ----#
function documentationkMenu($sectionNumber){    
    if ($sectionNumber -eq 3){printDocumentationMenu}
    Write-Host "`n>> Please select a Documentation Menu option: " -ForegroundColor DarkBlue -NoNewline 
    $documentationSectionNumber = Read-Host

    if ($documentationSectionNumber -eq 0 -or $documentationSectionNumber -eq "exit"){
        " Exit Documentation Menu`n"
        printMainMenu}
    elseif ($documentationSectionNumber -eq 1){
        $allNSXComponentData = getNSXComponents($documentationSectionNumber)
    }
    elseif ($documentationSectionNumber -eq 2){getHostInformation($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 3){runNSXVISIOTool($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 7){runDFW2Excel($documentationSectionNumber)}
    
    elseif ($documentationSectionNumber -eq "help"){documentationkMenu(3)}
    elseif ($documentationSectionNumber -eq ''){documentationkMenu(22)}
    else { Write-Host "`n You have made an invalid choice!"
    documentationkMenu(22)}
}

#---- Get Health Check Menu here ----#
function healthCheckMenu($sectionNumber){    
    if ($sectionNumber -eq 4){printHealthCheckMenu}
    Write-Host "`n>> Please select a Health Check Menu option: " -ForegroundColor DarkBlue -NoNewline
    $healthCheckSectionNumber = Read-Host

    if ($healthCheckSectionNumber -eq 0 -or $healthCheckSectionNumber -eq "exit"){
        " Exit NSX Health Check Menu`n"
        printMainMenu}
    elseif ($healthCheckSectionNumber -eq 1){getVDRInstance($healthCheckSectionNumber)}
    elseif ($healthCheckSectionNumber -eq 2){getVIBVersion($healthCheckSectionNumber)}

    elseif ($healthCheckSectionNumber -eq "help"){healthCheckMenu(4)}
    elseif ($healthCheckSectionNumber -eq ''){healthCheckMenu(22)}
    else { Write-Host "`n You have made an invalid choice!"
    healthCheckMenu(22)}
}

#Get NSX Component info here
function getNSXComponents($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now getting NSX Components info..."
    #### Call other functions to get NSX Components info here...
    #### Save NSX Components info on local variable here
    
    
    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel
    $listOfWorkBooks = "Summery", "Host1", "Host2"
    createNewExcel("NSXComponents", $listOfWorkBooks)

    # Loop
    documentationkMenu(22) #Keep in Documentation Menu
}

#Get Host info here
function getHostInformation($sectionNumber){
    $userSelection = "Get List of Hosts"
    Write-Host "`n You have selected # '$sectionNumber'. Now executing '$userSelection'..."
    $vmHosts = get-vmhost
    $vmHosts
    $exportHostList = Read-Host -Prompt "`n Export output in a .txt file? Please enter 'y' or 'n'"
    if ($exportHostList -eq 'y'){
        $vmHosts > ListOfAllHost.txt
        " Created a list of all VM(s) and exported in ListOfAllHost.txt"
    }
    documentationkMenu(22)
}

#Run DFW2Excel
function runDFW2Excel($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now documenting DFW to excel file..."
    invoke-expression -Command .\PowerNSX-Scripts\DFW2Excel.ps1
    documentationkMenu(22)
}

#Run visio
function runNSXVISIOTool($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now documenting NSX Network..."
    documentationkMenu(22)
}

#Run getVDRInstance
function getVDRInstance($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now geting VDR Instance..."
    healthCheckMenu(22)
}

#Run getVIBVersion
function getVIBVersion($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now geting VIB Version..."
    healthCheckMenu(22)
}


# ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- Excel Functions start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- #

#Create empty excel sheet here w/ correct name 
function createNewExcel($excelName, $listOfWorkBooks){
    $Excel = New-Object -Com Excel.Application
    $Excel.visible = $True
    $Excel.DisplayAlerts = $false
    $wb = $Excel.Workbooks.Add()

}

# Plot excel sheet here ..pass dynamic values like workbook number, 
function plotDynamicExcel($excelName, $excelWorkBookNumber, $plotDataDict){

#    foreach($appliedTo in $rule.appliedToList.appliedTo){
#                $sheet.Cells.Item($appRow,18) = $appliedTo.name
#                $appRow++
#            }

}


#Get VMs info here
#function thirdOptionSelected($sectionNumber){
#    $userSelection = "Get List of VMs"
#    Write-Host "`n You have selected # '$sectionNumber'. Now executing '$userSelection'..."
#    $listOfVMs = get-vm
#    $listOfVMs
#    $exportVMsList = Read-Host -Prompt "`n Export VMs list in a .txt file? Please enter 'y' or 'n'"
#    if ($exportVMsList -eq 'y'){
#        $listOfVMs > ListOfAllVMs.txt
#        " Created a list of all VM(s) and exported in ListOfAllVMs.txt"
#    }
#}

"`n"
" __/\\\\\\\\\\\\\\\______________________/\\\\\\\\\________________/\\\_______________________        "
"  _\/\\\///////////____________________/\\\////////________________\/\\\_______________________       "
"   _\/\\\_____________________________/\\\/_________________________\/\\\_______________________      "
"    _\/\\\\\\\\\\\______/\\\\\\\\\\\__/\\\______________/\\\____/\\\_\/\\\____________/\\\\\\\\\_     "
"     _\/\\\///////______\///////////__\/\\\_____________\/\\\___\/\\\_\/\\\\\\\\\____/\\\//    /__    "
"      _\/\\\___________________________\//\\\____________\/\\\___\/\\\_\/\\\////\\\__/\\\\\\\\\____   "
"       _\/\\\____________________________\///\\\__________\/\\\___\/\\\_\/\\\__\/\\\_\//\\/  //_____  "
"        _\/\\\\\\\\\\\\\\\__________________\////\\\\\\\\\_\//\\\\\\\\\__\/\\\\\\\\\___\//\\\\\\\\\__ "
"         _\///////////////______________________\/////////___\/////////___\/////////_____\/////////___`n`n"


" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
" ~~                  Welcome to E-Cube                    ~~" 
" ~~                A project by SA Team                   ~~" 
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
" ~ Note: Please run this script from PowerCLI.             ~" 
" ~       To get the list of available commands type 'help' ~" 
" ~       To exit type 'exit' or '0'.                       ~" 
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 
" What would you like to do today?" 
printMainMenu

while($true)
{
    Write-Host "`n>> Please select an e-cube option: " -ForegroundColor DarkMagenta -NoNewline
    $sectionNumber = Read-Host

    if ($sectionNumber -eq 0 -or $sectionNumber -eq "exit"){break}
    elseif ($sectionNumber -eq "help"){printMainMenu}

    elseif ($sectionNumber -eq 1){installPowerNSX($sectionNumber)}
    elseif ($sectionNumber -eq 2){connectNSXManager($sectionNumber)}
    elseif ($sectionNumber -eq 3){documentationkMenu($sectionNumber)}
    elseif ($sectionNumber -eq 4){healthCheckMenu($sectionNumber)}
    elseif ($sectionNumber -eq ''){}
    #elseif ($sectionNumber -eq 5){runNSXVisualTool($sectionNumber)}
    else { Write-Host "`n You have made an invalid choice!"}

}# Infinite while loop ends here
####start-sleep -s 1
