# *-------------------------------------------* #
# ********************************************* #
#      VMware NSX e-Cube by @thisispuneet       #
# This script automate NSX-v Operationalization #
# and help build the env networking documents   #
# ********************************************* #
# *-------------------------------------------* #
#               Version: 1.0.3                  #
# *-------------------------------------------* #

function printMainMenu{
    "`n 1) Install PowerNSX"
    " 2) Connect NSX Manager and vCenter"
    " 3) Documentation Menu"
    " 4) Health Check Menu"
    " 0) Exit E-Cube"
}

function printDocumentationMenu{
    "`n ***************************************"
    " ** Welcome to NSX Documentation Menu **"
    " ***************************************"
    "`n Enviornment Documentation"
    "  |_ 1) Document all NSX Components"
    "  |_ 2) Document ESXi Host(s) Info"
    "  |_ 3) Document NSX Enviornamnt Diagram via VISIO Tool"
    "  |_ 4) Import vRealie Log Insight Dashboard"

    "`n Networking Documentation"
    "  |_ 5) Document Routing info"
    "  |_ 6) Document VxLAN info"

    "`n Security Documentation"
    "  |_ 7) Document NSX DFW info to Excel - DFW2Excel"
    "  |_ 8) Document DFW-VAT"
    " 0) Exit Documentation Menu"
}

function printHealthCheckMenu{
    "`n **************************************"
    " ** Welcome to NSX Health Check Menu **"
    " **************************************"
    "`n 1) VDR Instance Check"
    " 2) VIB Version Check"
    " 0) Exit Health Check Menu"
}

#Install PowerNSX here
function installPowerNSX($sectionNumber){
    $userSelection = "Install PowerNSX"
    Write-Host "`n You have selected # '$sectionNumber'. Now executing '$userSelection'..."\
    $Branch="v2";$url="https://raw.githubusercontent.com/vmware/powernsx/$Branch/PowerNSXInstaller.ps1"; try { $wc = new-object Net.WebClient;$scr = try { $wc.DownloadString($url)} catch { if ( $_.exception.innerexception -match "(407)") { $wc.proxy.credentials = Get-Credential -Message "Proxy Authentication Required"; $wc.DownloadString($url) } else { throw $_ }}; $scr | iex } catch { throw $_ }
}

#Get Health Check Menu here
function healthCheckMenu($sectionNumber){    
    if ($sectionNumber -eq 4){printHealthCheckMenu}
    $healthCheckSectionNumber = Read-Host -Prompt "`n >> Please select a Health Check option"

    if ($healthCheckSectionNumber -eq 0 -or $healthCheckSectionNumber -eq "exit"){
        "Exit NSX Health Check Menu"
        printMainMenu}
    elseif ($healthCheckSectionNumber -eq 1){getVDRInstance($healthCheckSectionNumber)}
    elseif ($healthCheckSectionNumber -eq 2){getVIBVersion($healthCheckSectionNumber)}
    elseif ($healthCheckSectionNumber -eq "help"){
        printHealthCheckMenu 
        healthCheckMenu(22)
    }
    else { Write-Host "`n You have made an invalid choice! Exiting Health Check Menu."}
}

#Get Health Check Menu here
function documentationkMenu($sectionNumber){    
    if ($sectionNumber -eq 3){printDocumentationMenu}
    $documentationSectionNumber = Read-Host -Prompt "`n >> Please select a Documentation option"

    if ($documentationSectionNumber -eq 0 -or $healthCheckSectionNumber -eq "exit"){
        "Exit Documentation Menu"
        printMainMenu}
    #elseif ($documentationSectionNumber -eq 1){getVDRInstance($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 2){getHostInformation($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 3){runNSXVISIOTool($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 7){runDFW2Excel($documentationSectionNumber)}
    
    elseif ($documentationSectionNumber -eq "help"){
        printDocumentationMenu
        documentationkMenu(22)
    }
    else { Write-Host "`n You have made an invalid choice! Exiting Documentation Menu."}
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
}

#Run DFW2Excel
function runDFW2Excel($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now documenting DFW to excel file..."
    invoke-expression -Command ..\PowerNSX-Scripts\DFW2Excel.ps1
}

#Run visio
function runNSXVISIOTool($sectionNumber){
    Write-Host "`n You have selected # '$sectionNumber'. Now documenting NSX Network..."
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


" **************************"
" **************************"
" **  Welcome to E-Cube   **"
" ** A project by SA Team **"
" **************************"
" **************************`n"
" Note: Please run this script from PowerCLI."
"       To get the list of available commands type 'help'."
"       To exit type 'exit' or '0'."

" What would you like to do today?"
printMainMenu

while($true)
{

    $sectionNumber = Read-Host -Prompt "`n >> Please select an e-cube option"

    if ($sectionNumber -eq 0 -or $sectionNumber -eq "exit"){break}
    if ($sectionNumber -eq "help"){printMainMenu}

    if ($sectionNumber -eq 1){installPowerNSX($sectionNumber)}
    #elseif ($sectionNumber -eq 2){healthCheckMenu($sectionNumber)}
    elseif ($sectionNumber -eq 3){documentationkMenu($sectionNumber)}
    elseif ($sectionNumber -eq 4){healthCheckMenu($sectionNumber)}
    #elseif ($sectionNumber -eq 5){runNSXVisualTool($sectionNumber)}
    else { Write-Host "`n You have made an invalid choice!"}

}# Infinite while loop ends here
####start-sleep -s 1
