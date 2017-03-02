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
import-module Posh-SSH
import-module Pester
##Import-Module PesterNew-SSHSession
#Import-Module pscx

########################################################
#    Formatting Options for Excel Spreadsheet
########################################################

    $titleFontSize = 13
    $titleFontBold = $True
    $titleFontColorIndex = 2
    $titleFontName = "Calibri (Body)"
    $titleInteriorColor = 10

    $subTitleFontSize = 10.5
    $subTitleFontBold = $True
    $subTitleFontName = "Calibri (Body)"
    $subTitleInteriorColor = 42

    $valueFontName = "Calibri (Body)"
    $valueFontSize = 10.5
    $valueMissingColorIndex =
    $valueMissingText = "<BLANK>"
    $valueMissingHighlight = 6
    $valueNotApplicable = "<NOT APPLICABLE>"
    $valueNotDefined = "<NOT DEFINED>"

    $subSetInteriorColor = 22

    $global:myRow = 1
    $global:myColumn = 1

    $global:ConsoleWidth = (Get-host).ui.RawUI.windowsize.width

#Install PowerNSX here
function installPowerNSX($sectionNumber){
    $userSelection = "Install PowerNSX"
    Write-Host -ForegroundColor DarkGreen "You have selected # '$sectionNumber'. Now executing '$userSelection'..."\
    $Branch="v2";$url="https://raw.githubusercontent.com/vmware/powernsx/$Branch/PowerNSXInstaller.ps1"; try { $wc = new-object Net.WebClient;$scr = try { $wc.DownloadString($url)} catch { if ( $_.exception.innerexception -match "(407)") { $wc.proxy.credentials = Get-Credential -Message "Proxy Authentication Required"; $wc.DownloadString($url) } else { throw $_ }}; $scr | iex } catch { throw $_ }
    printMainMenu
}

#Connect to NSX Manager and vCenter. Save the credentials.
function connectNSXManager($sectionNumber){
    Write-Host -ForegroundColor DarkGreen "You have selected # '$sectionNumber'. Now executing Connect with Hosts..."
    
    $global:vCenterHost = Read-Host -Prompt " Enter vCenter IP"
    $vCenterUser = Read-Host -Prompt " Enter vCenter User"
    $vCenterPass = Read-Host -Prompt " Enter vCenter Password" 

    $global:nsxManagerHost = Read-Host -Prompt "`n Enter NSX Manager IP"
    $nsxManagerUser = Read-Host -Prompt " Enter NSX Manager User"
    $nsxManagerPasswd = Read-Host -Prompt " Enter NSX Manager Password" 
    $global:nsxManagerAuthorization = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($nsxManagerUser + ":" + $nsxManagerPasswd))
    $nsxManagerSecurepasswd = ConvertTo-SecureString $nsxManagerPasswd -AsPlainText -Force
    $global:nsxManagerPSCredential = New-Object System.Management.Automation.PSCredential ($nsxManagerUser, $nsxManagerSecurepasswd)

    if ($global:nsxManagerHost -eq '' -or $nsxManagerUser -eq '' -or $nsxManagerPasswd -eq ''){
        " NSX Manager information not provided. Can't connect to NSX Manager or vCenter!"
    }
    elseif ($global:vCenterHost -eq '' -or $vCenterUser -eq '' -or $vCenterPass -eq ''){
        " vCenter information not provided. Can't connect to NSX Manager or vCenter!"
    }
    else{
        Write-Host -ForegroundColor Yellow "`n Connecting with vCenter..."
        Connect-VIServer -Server $global:vCenterHost -User $vCenterUser -Password $vCenterPass

        Write-Host -ForegroundColor Yellow "`n Connecting with NSX Manager..."
        $global:NsxConnection = Connect-NsxServer -Server $global:nsxManagerHost -User $nsxManagerUser -Password $nsxManagerPasswd -viusername $vCenterUser -vipassword $vCenterPass -ViWarningAction "Ignore"

        ##"`n Establishing SSH connection with NSX Manager..."
        #$nsxManagerSecurePass = $nsxManagerPass | ConvertTo-SecureString -AsPlainText -Force
        #$myNSXManagerSecureCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $nsxManagerUser, $nsxManagerSecurePass
        ##$global:NsxSSHConnection = startSSHSession -serverToConnectTo $nsxManagerHost -credentialsToUse $nsxManagerPSCredential
        ##$global:NsxSSHConnection

        Write-Host -ForegroundColor Yellow "`n Connecting NSX Manager to vCenter..."
        Set-NsxManager -vCenterServer $global:vCenterHost -vCenterUserName $vCenterUser -vCenterPassword $vCenterPass
        Write-Host -ForegroundColor Green "Done!"
    }
}

#---- Get Documentation Menu here ----#
function documentationkMenu($sectionNumber){    
    if ($sectionNumber -eq 3){clx | printDocumentationMenu}
    Write-Host "`n>> Please select a Documentation Menu option: " -ForegroundColor Darkyellow -NoNewline 
    $documentationSectionNumber = Read-Host

    if ($documentationSectionNumber -eq 0 -or $documentationSectionNumber -eq "exit"){
        Write-Host -ForeGroundColor Darkyellow "Exit Documentation Menu`n"
        clx | printMainMenu}
    elseif ($documentationSectionNumber -eq 1){$allNSXComponentData = getNSXComponents($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 2){getHostInformation($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 3){runNSXVISIOTool($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 4){importLogInSightDashBoard($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 5){getRoutingInformation($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 6){getVXLANInformation($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 7){runDFW2Excel($documentationSectionNumber)}
    
    elseif ($documentationSectionNumber -eq "help"){documentationkMenu(3)}
    elseif ($documentationSectionNumber -eq "clear"){documentationkMenu(3)}
    elseif ($documentationSectionNumber -eq ''){documentationkMenu(22)}
    else { Write-Host -ForegroundColor DarkRed "You have made an invalid choice!"
    documentationkMenu(22)}
}

#---- Get Health Check Menu here ----#
function healthCheckMenu($sectionNumber){    
    if ($sectionNumber -eq 4){clx | printHealthCheckMenu}
    Write-Host "`n>> Please select a Health Check Menu option: " -ForegroundColor Darkyellow -NoNewline
    $healthCheckSectionNumber = Read-Host

    if ($healthCheckSectionNumber -eq 0 -or $healthCheckSectionNumber -eq "exit"){
        Write-Host -ForeGroundColor Darkyellow "Exit Health Check Menu`n"
        clx | printMainMenu}
    elseif ($healthCheckSectionNumber -eq 1){runNSXTest -sectionNumber $healthCheckSectionNumber -testModule "testNSXConnections"}
    elseif ($healthCheckSectionNumber -eq 2){runNSXTest -sectionNumber $healthCheckSectionNumber -testModule "testNSXManager"}
    elseif ($healthCheckSectionNumber -eq 3){runNSXTest -sectionNumber $healthCheckSectionNumber -testModule "testNSXControllers"}
    elseif ($healthCheckSectionNumber -eq 4){runNSXTest -sectionNumber $healthCheckSectionNumber -testModule "testNSXLogicalSwitch"}
    elseif ($healthCheckSectionNumber -eq 5){runNSXTest -sectionNumber $healthCheckSectionNumber -testModule "testNSXDistributedFirewallHeap"}
    elseif ($healthCheckSectionNumber -eq 6){runNSXTest -sectionNumber $healthCheckSectionNumber -testModule "testNSXVDR"}
    elseif ($healthCheckSectionNumber -eq 7){runNSXTest -sectionNumber $healthCheckSectionNumber -testModule "testNSXVIBVersion"}

    elseif ($healthCheckSectionNumber -eq "help"){healthCheckMenu(4)}
    elseif ($healthCheckSectionNumber -eq "clear"){healthCheckMenu(4)}
    elseif ($healthCheckSectionNumber -eq ''){healthCheckMenu(22)}
    else { Write-Host -ForegroundColor DarkRed "You have made an invalid choice!"
    healthCheckMenu(22)}
}


#---- Get Health Check Menu here ----#
function nsxUpdateCheckReport($sectionNumber){
    Write-Host -ForegroundColor DarkGreen "You have selected # '$sectionNumber'. Now collecting NSX upgrade info..."
}


#Get NSX Component info here
function getNSXComponents($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now getting NSX Components info..."
    #### Call other functions to get NSX Components info here...

    #### Save NSX Components info on local variable here
    $nsxControllers = Get-nsxcontroller
    $allNSXComponentExcelDataControllers =@{}

    $nsxEdges = Get-NsxEdge
    $allNSXComponentExcelDataEdge =@{}

    $nsxLogicalRouters = Get-NsxLogicalRouter
    $allNSXComponentExcelDataDLR =@{}

    $nsxManagerSummary = Get-NsxManagerSystemSummary
    $nsxManagerVcenterConfig = Get-NsxManagerVcenterConfig
    #Write-Host "Controller ID is:"$nsxControllers[0].id
    <# 
    $allNSXComponentExcelData = @{"NSX Controllers Info" = $nsxControllers, "objectTypeName", "revision", "clientHandle", "isUniversal", "universalRevision", "id", "ipAddress", "status", "upgradeStatus", "version", "upgradeAvailable", "virtualMachineInfo", "hostInfo", "resourcePoolInfo", "clusterInfo", "managedBy", "datastoreInfo", "controllerClusterStatus", "diskLatencyAlertDetected", "vmStatus"; 
    "NSX Manager Info" = $nsxManagerSummary, "ipv4Address", "dnsName", "hostName", "applianceName", "versionInfo", "uptime", "cpuInfoDto", "memInfoDto", "storageInfoDto", "currentSystemDate"; 
    "NSX Manager vCenter Configuration" = $nsxManagerVcenterConfig, "ipAddress", "userName", "certificateThumbprint", "assignRoleToUser", "vcInventoryLastUpdateTime", "Connected";
    "NSX Edge Info" = $nsxEdges, "id", "version", "status", "datacenterMoid", "datacenterName", "tenant", "name", "fqdn", "enableAesni", "enableFips", "vseLogLevel", "vnics", "appliances", "cliSettings", "features", "autoConfiguration", "type", "isUniversal", "hypervisorAssist", "queryDaemon", "edgeSummary";
    "NSX Logical Router Info" = $nsxLogicalRouters, "id", "version", "status", "datacenterMoid", "datacenterName", "tenant", "name", "fqdn", "enableAesni", "enableFips", "vseLogLevel", "appliances", "cliSettings", "features", "autoConfiguration", "type", "isUniversal", "mgmtInterface", "interfaces", "edgeAssistId", "lrouterUuid", "queryDaemon", "edgeSummary"}
    #>
    $allNSXComponentExcelDataMgr =@{"NSX Manager Info" = $nsxManagerSummary, "all"; "NSX Manager vCenter Configuration" = $nsxManagerVcenterConfig, "all"}

    foreach ($eachNSXController in $nsxControllers){
        $tempControllerData = $eachNSXController, "all"
        $allNSXComponentExcelDataControllers.Add($eachNSXController.id, $tempControllerData)
    }
    foreach ($eachNSXEdge in $nsxEdges){
        $tempNSXEdgeData = $eachNSXEdge, "all"
        $allNSXComponentExcelDataEdge.Add($eachNSXEdge.id, $tempNSXEdgeData)
    }
    foreach ($eachNSXDLR in $nsxLogicalRouters){
        $tempNSXDLRData = $eachNSXDLR, "all"
        $allNSXComponentExcelDataDLR.Add($eachNSXDLR.id, $tempNSXDLRData)
    }
    #$allNSXComponentExcelDataDLR =@{"NSX Logical Router Info" = $nsxLogicalRouters, "all"}

    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "NSX-Components-Excel"
    $nsxComponentExcelWorkBook = createNewExcel($excelName)
    
    ####plotDynamicExcel one workBook at a time

    $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName "NSX Manager" -listOfDataToPlot $allNSXComponentExcelDataMgr
    $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName "NSX Controllers" -listOfDataToPlot $allNSXComponentExcelDataControllers
    $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName "NSX Edge Services Gateway" -listOfDataToPlot $allNSXComponentExcelDataEdge
    $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName "NSX Logical Router" -listOfDataToPlot $allNSXComponentExcelDataDLR

    Write-Host -ForegroundColor Green "`n Done Working on the Excel Sheet."
    #Loop back to document Menu
    documentationkMenu(22) #Keep in Documentation Menu
}

#Get Host info here
function getHostInformation($sectionNumber){
    $userSelection = "Get List of Hosts"
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now executing '$userSelection'..."
    $vmHosts = get-vmhost
    Write-Host " Number of vmHosts are:" $vmHosts.length

    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "ESXi-Hosts-Excel"
    $nsxComponentExcelWorkBook = createNewExcel($excelName)
    foreach ($eachVMHost in $vmHosts){
        $sshCommandOutputData = @{}
        $sshCommandOutputLable = @()
        # Run SSH Command on NSX Manager here...
        $myHost = $eachVMHost.id
        if ($myHost -match "HostSystem-"){$myNewHost = $myHost -replace "HostSystem-", ""}
        [string]$nsxMgrCommand = "show logical-switch host "+$myNewHost+" verbose"
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommand -fileName "temp-logical-switch-info.txt"
        #invokeNSXCLICmd -commandToInvoke "show cluster all" -fileName "temp-logical-switch-info.txt"
        $findElements= @("Control plane Out-Of-Sync", "MTU", "VXLAN vmknic")
        foreach ($eachElement in $findElements){
            $indx = ''
            $indx = Select-String $eachElement "temp-logical-switch-info.txt" | ForEach-Object {$_.LineNumber}
            if ($indx -ne '') {
                [string]$eachElementResult = (Get-Content "temp-logical-switch-info.txt")[$indx-1]
                $sshCommandOutputData.Add($eachElement, $eachElementResult)
                $sshCommandOutputLable += $eachElement
            }
        }
        # NSX Manager SSH Command Ends here.

        $allVmHostsExcelData=@{}
        $tempHostData=@()
        $tempHostData2=@()
        #$allVmHostsExcelData = @{"ESXi Host" = $eachVMHost, "Name", "ConnectionState", "PowerState", "NumCpu", "CpuUsageMhz", "CpuTotalMhz", "MemoryUsageGB", "MemoryTotalGB", "Version"}
        $tempHostData = $eachVMHost, "all"
        $tempHostData2 = $sshCommandOutputData, "Control plane Out-Of-Sync", "MTU", "VXLAN vmknic"
        $allVmHostsExcelData.Add($eachVMHost.name, $tempHostData)
        $allVmHostsExcelData.Add("NSX Manager Details", $tempHostData2)
        ####plotDynamicExcel one workBook at a time
        $plotHostInformationExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName $eachVMHost.name -listOfDataToPlot $allVmHostsExcelData
        ####writeToExcel -eachDataElementToPrint $sshCommandOutputData -listOfAllAttributesToPrint $sshCommandOutputLable
    }
    #invokeNSXCLICmd(" show logical-switch host host-31 verbose ")

    <#
    $exportHostList = Read-Host -Prompt "`n Export output in a .txt file? Please enter 'y' or 'n'"
    if ($exportHostList -eq 'y'){
        $vmHosts > ListOfAllHost.txt
        " Created a list of all VM(s) and exported in ListOfAllHost.txt"
    }
    #>
    Write-Host -ForegroundColor Green "`n Done Working on the Excel Sheet."
    documentationkMenu(22)
}

#Run visio tool
function runNSXVISIOTool($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now starting VISIO tool..."
    $capturePath = invoke-expression -Command .\DiagramNSX\NsxObjectCapture.ps1
    Write-Host "`n"
    #$pathVISIO = Read-Host -Prompt " Please provide the above .zip file path to generate the VISIO file"
    #$visioDiagramCommand = ".\DiagramNSX\NsxObjectDiagram.ps1 -CaptureBundle " + $pathVISIO
    $visioDiagramCommand = ".\DiagramNSX\NsxObjectDiagram.ps1 -CaptureBundle " + $capturePath
    invoke-expression -Command $visioDiagramCommand
    documentationkMenu(22)
}

#Download Log Insite's Dashboard
function importLogInSightDashBoard($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now starting VISIO tool..."
    $lisVersion = Read-Host -Prompt " Please provide your Log Insite Version"
    Write-Host "`n Downloading custom Dashboard for your Log Insite version..."
}

#Get Routing info here
function getRoutingInformation($sectionNumber){
    $userSelection = "Get Routing Information"
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now executing '$userSelection'..."
    
    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "NSX-Routing-Excel"
    $nsxComponentExcelWorkBook = createNewExcel($excelName)
    ##$numberOfEdges
    # Getting Edge Routing Info here
    $allEdgeRoutingExcelData = @{}
    $numberOfEdges = Get-NsxEdge
    foreach ($eachEdge in $numberOfEdges){
        $edgeRoutingInfo = Get-NsxEdge $eachEdge.name | Get-NsxEdgeRouting 
        ##$edgeRoutingInfo
        #$edgeRoutingInfo = @{$eachEdge.name = $tempEdgeRoutingInfo}
        $tempEdgeRoutingValueArray = $edgeRoutingInfo, "all"
        $allEdgeRoutingExcelData.Add($eachEdge.name, $tempEdgeRoutingValueArray)
    }
    #$allEdgeRoutingExcelData = @{"NSX Edge Routing" = $edgeRoutingInfo, "all"}
    $plotNSXRoutingExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName "NSX Edge Routing Config" -listOfDataToPlot $allEdgeRoutingExcelData 

    # Getting DLR routing Info here
    $allDLRRoutingExcelData = @{}
    $numberOfDLRs = Get-NsxLogicalRouter
    foreach($eachDLR in $numberOfDLRs){
        $dlrRoutinginfo = Get-NsxLogicalRouter $eachDLR.Name | Get-NsxLogicalRouterRouting
        $tempDLRRoutingValueArray = $dlrRoutinginfo, "all"
        $allDLRRoutingExcelData.Add($eachDLR.Name, $tempDLRRoutingValueArray)
    }
    
    ##$dlRoutingInfo =  Get-NsxLogicalRouterRouting
    
    ####plotDynamicExcel one workBook at a time
    $plotNSXRoutingExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName "NSX DLR Routing Config" -listOfDataToPlot $allDLRRoutingExcelData
    
    Write-Host -ForegroundColor Green "`n Done Working on the Excel Sheet."
    documentationkMenu(22)
}

#get VXLAN Info
function getVXLANInformation($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now documenting VXLAN Info to the excel file..."

    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "NSX-VXLAN-Excel"
    $nsxVXLANExcelWorkBook = createNewExcel($excelName)
    $numberOfEdges = Get-NsxEdge
    foreach ($eachEdge in $numberOfEdges){
        $allVXLANExcelData = @{}
        $edgeInterfaceInfo = Get-NsxEdge $eachEdge.name | Get-NsxEdgeInterface
        $tempEdgeInterfaceValueArray = $edgeInterfaceInfo, "all"
        $allVXLANExcelData.Add($eachEdge.name, $tempEdgeInterfaceValueArray)
        $plotNSXInterfaceExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxVXLANExcelWorkBook -workSheetName $eachEdge.name -listOfDataToPlot $allVXLANExcelData     
    }
    documentationkMenu(22)
}


#Run DFW2Excel
function runDFW2Excel($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now documenting DFW to excel file..."
    invoke-expression -Command .\PowerNSX-Scripts\DFW2Excel.ps1
    documentationkMenu(22)
}


function getMemberWithProperty($tempListOfAllAttributesInFunc){
    #$listOfAllAttributesWithCorrectProperty = New-Object System.Collections.ArrayList
    $listOfAllAttributesWithCorrectProperty = @()
    foreach($eachAttribute in $tempListOfAllAttributesInFunc){
        if ($eachAttribute.MemberType -eq "Property"){
            #$listOfAllAttributesWithCorrectProperty.Add($eachAttribute.Name)
            $listOfAllAttributesWithCorrectProperty += $eachAttribute.Name
        }
    }
    #return $listOfAllAttributesWithCorrectProperty
    return ,$listOfAllAttributesWithCorrectProperty
}


function invokeNSXCLICmd($commandToInvoke, $fileName){
    Write-Host -ForeGroundColor Yellow "`n Note: CLI Command Invoked" $commandToInvoke
    
    $nsxMgrCliApiURL = $global:nsxManagerHost+"/api/1.0/nsx/cli?action=execute"
    if ($nsxMgrCliApiURL.StartsWith("http://")){$nsxMgrCliApiURL -replace "http://", "https://"}
    elseif($nsxMgrCliApiURL.StartsWith("https://")){}
    else{$nsxMgrCliApiURL = "https://"+$nsxMgrCliApiURL}

    $xmlBody = "<nsxcli>
     <command> $commandToInvoke </command>
     </nsxcli>"
    $curlHead = @{"Accept"="text/plain"; "Content-type"="Application/xml"; "Authorization"="Basic $global:nsxManagerAuthorization"}

    $nsxCLIResponceweb = Invoke-WebRequest -uri $nsxMgrCliApiURL -Body $xmlBody -Headers $curlHead -Method Post
    $nsxCLIResponceweb.content > $fileName
}


function startSSHSession($serverToConnectTo, $credentialsToUse){
    #$myNSXManagerCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $mySecurePass
    $newSSHSession = New-Sshsession -computername $serverToConnectTo -Credential $credentialsToUse
    return $newSSHSession
}


# ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- HealthCheck Functions start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- # 


function runNSXTest ($sectionNumber, $testModule){
  Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Testing $testModule..."
  $startTime = Get-Date
  $outputFileName = $testModule +"-"+ $startTime.ToString("yyyy-MM-dd-hh-mm") + ".xml"
  $result = Invoke-Pester -Script @{ Path = './HealthCheck/'+$testModule+'.Tests.ps1'; Parameters = @{ testModule = $testModule} } -OutputFile ./HealthCheck/testResult-$outputFileName
  Write-Host "`nSave the result in an XML file? Y or N [default Y]: " -ForegroundColor Darkyellow -NoNewline
  $saveHCResult = Read-Host
  if ($saveHCResult -eq 'n'-or $saveHCResult -eq "N") {Remove-Item ./HealthCheck/testResult-$outputFileName}else{
      Write-Host "Saved XML file at:" ./HealthCheck/testResult-$outputFileName -ForegroundColor Green}
  healthCheckMenu(22)
}


function clx {
    [System.Console]::SetWindowPosition(0,[System.Console]::CursorTop)
}

# ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- Excel Functions start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- # 

#Create empty excel sheet here w/ correct name 
function createNewExcel($newExcelName){
    $startTime = Get-Date
    $newExcelNameWithDate = $newExcelName +"-"+ $startTime.ToString("yyyy-MM-dd-hh-mm") + ".xlsx"
    Write-Host -ForeGroundColor Green "`n Creating Excel File:" $newExcelNameWithDate
    
    #$xlFixedFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlWorkbookDefault
    $newExcel = New-Object -Com Excel.Application
    $newExcel.visible = $True
    $newExcel.DisplayAlerts = $false
    #$Excel.Name = "Test Excel Name"
    $wb = $newExcel.Workbooks.Add()
    #$sheet = $wb.ActiveSheet
    
    # Save the excel with provided Name
    #$newExcel.ActiveWorkbook.SaveAs($newExcelNameWithDate, $xlFixedFormat)
    $newExcel.ActiveWorkbook.SaveAs($newExcelNameWithDate)
    return $wb
} # End of function createNewExcel

# Plot excel sheet here one workBook at a time ..pass already created Excel, Worksheet Name, List of values need to be plotted.
# Call this function seperatelly for multiple Work Sheets.
function plotDynamicExcelWorkBook($myOpenExcelWBReturn, $workSheetName, $listOfDataToPlot){
    $listOfAllAttributes =@()
    Write-Host -ForeGroundColor Green "`n Creating WorkSheet: $workSheetName. This can take upto 30 mins..."
    $global:myRow =1
    $global:myColumn=1
    $sheet = $myOpenExcelWBReturn.WorkSheets.Add()
    $sheet.Name = $workSheetName
    $sheet.Cells.Item(1,1) = $workSheetName

    foreach($eachDataSetKey in $listOfDataToPlot.Keys){
        Write-Host " =>Plotting data for:" $eachDataSetKey
        $global:myRow++
        $global:myRow++
        $global:myColumn = 1
        $sheet.Cells.Item($global:myRow,$global:myColumn) = $eachDataSetKey
        $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Size = $titleFontSize
        $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Bold = $titleFontBold
        $sheet.Cells.Item($global:myRow,$global:myColumn).Font.ColorIndex = $titleFontColorIndex
        $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Name = $titleFontName
        $sheet.Cells.Item($global:myRow,$global:myColumn).Interior.ColorIndex = $titleInteriorColor
        $sheet.Cells.Item($global:myRow,$global:myColumn).HorizontalAlignment = -4108
        foreach ($eachDataElement in $listOfDataToPlot.Item($eachDataSetKey)[0]){
            #Write-Host "  listOfDataToPlot[0] eachDataElement is:" $eachDataElement.name
            $global:myRow++
            $global:myRow++
            if ($listOfDataToPlot.Item($eachDataSetKey)[1] -eq "all"){
                #Write-Host "Found All"
                #$listOfAllAttributes = $listOfDataToPlot.Item($eachDataSetKey)[0] | Format-List * -force
                $tempListOfAllAttributes = $listOfDataToPlot.Item($eachDataSetKey)[0] | Get-Member
                $listOfAllAttributes = getMemberWithProperty($tempListOfAllAttributes)
            }else{
                 #Write-Host "Found Specific Parameters to print"
                $tempLableNumber =0
                #Write-Host "Length of passed array is:" $listOfDataToPlot.Item($eachDataSetKey).count
                foreach ($eachCustomLabel in $listOfDataToPlot.Item($eachDataSetKey)){
                    #Write-Host "Each Element passed is:" $eachCustomLabel
                    if ($tempLableNumber -ne 0){$listOfAllAttributes+=$eachCustomLabel}
                    $tempLableNumber++
                }
            }
            $global:myColumn = 1
            writeToExcel $eachDataElement $listOfAllAttributes
        }
        #$sheet.Cells.Item($myRow,1) = $eachDataSetKey
        #$myRow++
    }
    
    $usedRange = $sheet.UsedRange
    $usedRange.EntireColumn.Autofit()

#    foreach($appliedTo in $rule.appliedToList.appliedTo){
#                $sheet.Cells.Item($appRow,18) = $appliedTo.name
#                $appRow++
#            }
} # End Function plotDynamicExcelWorkBook


function writeToExcel($eachDataElementToPrint, $listOfAllAttributesToPrint){
    $newListOfXMLToPrint =@()
    #Write-Host "eachDataElementToPrint again is:" $eachDataElementToPrint
    #Write-Host "list Of All Attributes again is:" $listOfAllAttributesToPrint
    #Write-Host "myRow again is:" $global:myRow
    foreach ($eachLabelToPrint in $listOfAllAttributesToPrint){        
        Try{
            $valueOfLableToPrint = $eachDataElementToPrint.$eachLabelToPrint
            #if ($valueOfLableToPrint.gettype().BaseType.Name -ne "XmlLinkedNode" -or $valueOfLableToPrint.gettype().BaseType.Name -ne "Array"){
            if ($valueOfLableToPrint.gettype().BaseType.Name -eq "XmlLinkedNode"){
                #Write-Host "`nFound a xml within list." $valueOfLableToPrint.Name
                $newListOfXMLToPrint += $valueOfLableToPrint
            }elseif($valueOfLableToPrint.gettype().BaseType.Name -eq "Array"){
                $lengthOfLoop = 1
                foreach($newElementOfArrayToPrint in $valueOfLableToPrint){
                    #Write-Host "newElementOfArrayToPrint type is:" $newElementOfArrayToPrint.gettype().BaseType.Name
                    if ($newElementOfArrayToPrint.gettype().BaseType.Name -eq "XmlLinkedNode"){
                        #Write-Host "Found an Array!" $newElementOfArrayToPrint.Name
                        $listOfAllArrayAttributes = $newElementOfArrayToPrint | Get-Member
                        $newListOfArrayAllAttributes = getMemberWithProperty($listOfAllArrayAttributes)
                        #Write-Host $newListOfArrayAllAttributes
                        writeToExcel $newElementOfArrayToPrint $newListOfArrayAllAttributes
                        if($valueOfLableToPrint.count -ne $lengthOfLoop){$global:myRow++}
                        $lengthOfLoop++
                    }
                }
            }else{
                $sheet.Cells.Item($global:myRow,$global:myColumn) = $eachLabelToPrint
                $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Size = $subTitleFontSize
                $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Bold = $subTitleFontBold
                $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Name = $subTitleFontName
                $sheet.Cells.Item($global:myRow,$global:myColumn).Interior.ColorIndex = $subTitleInteriorColor
                
                $sheet.Cells.Item($global:myRow,$global:myColumn+1) = $valueOfLableToPrint
                $sheet.Cells.Item($global:myRow,$global:myColumn+1).Font.Size = $valueFontSize
                $sheet.Cells.Item($global:myRow,$global:myColumn+1).Font.Name = $valueFontName
                $sheet.Cells.Item($global:myRow,$global:myColumn+1).HorizontalAlignment = -4131
                #Write-Host "    " $eachLabelToPrint "is:" $eachDataElementToPrint.$eachLabelToPrint
                $global:myRow++
            }
            ##$global:myRow++
            ##Write-Host "    " $eachLabelToPrint "is:" $valueOfLableToPrint
        }Catch{
            $ErrorMessage = $_.Exception.Message
            #pass
            ##Write-Host " Warning:" $ErrorMessage
            ##Write-Host "   Details: No value available for:" $eachLabelToPrint
        }
    }

    if ($newListOfXMLToPrint.count -gt 0){
        foreach ($newDataElementToPrint in $newListOfXMLToPrint){
            $sheet.Cells.Item($global:myRow,$global:myColumn) = $newDataElementToPrint.Name
            $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Size = $subTitleFontSize
            $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Bold = $subTitleFontBold
            $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Name = $subTitleFontName
            $sheet.Cells.Item($global:myRow,$global:myColumn).Interior.ColorIndex = $subSetInteriorColor
            $global:myRow++
            $global:myColumn++
            $newLevelListOfAllAttributes = $newDataElementToPrint | Get-Member
            $newListOfAllAttributes = getMemberWithProperty($newLevelListOfAllAttributes)
            writeToExcel $newDataElementToPrint $newListOfAllAttributes
            $global:myColumn--
            #$global:myRow++
        }
    }
} # End function writeToExcel


# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- Test Function for development use only ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- #

function testFunction(){
    runNSXTest -sectionNumber 22 -testModule "get-helloworld"
}
<#
function testFunction(){
    $vmHosts = get-vmhost
    Write-Host " Number of vmHosts are:" $vmHosts.length
    foreach ($eachHost in $vmHosts){Write-Host "Each Host is: "$eachHost.id}
    #
    #invokeNSXCLICmd -commandToInvoke "show logical-switch host host-31 verbose" -fileName "test.txt"
    ##invokeNSXCLICmd -commandToInvoke "show cluster all" -fileName "test.txt"
    #$findElements= @("Out-Of-Sync", "MTU", "VXLAN vmknic")
    #foreach ($eachElement in $findElements){
    #    $indx = ''
    #    $indx = Select-String $eachElement "test.txt" | ForEach-Object {$_.LineNumber}
    #    if ($indx -ne '') {Write-Host "Found Object" (Get-Content "test.txt")[$indx-1]}
    #}
    #
}
#>


# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- Welcome Logo & Menus start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- # 

#Function to show Main Menu
function printMainMenu{
    $ScreenSize = [math]::Round($ConsoleWidth-39)/2
    Write-Host "`n"
    Write-Host (" " * $ScreenSize) "*******************|*******************"
    Write-Host (" " * $ScreenSize) "**         E-Cube Main Menu          **"
    Write-Host (" " * $ScreenSize) "***************************************"
    Write-Host (" " * $ScreenSize) "*                                     *"
    Write-Host (" " * $ScreenSize) "* 1) Install PowerNSX                 *"
    Write-Host (" " * $ScreenSize) "* 2) Connect NSX Manager & vCenter    *"
    Write-Host (" " * $ScreenSize) "* 3) Show Documentation Menu          *"
    Write-Host (" " * $ScreenSize) "* 4) Show Health Check Menu           *"
#    Write-Host (" " * $ScreenSize) "* 5) Check NSX Upgrade Prerequisites  *"
    Write-Host (" " * $ScreenSize) "*                                     *"
    Write-Host (" " * $ScreenSize) "* 0) Exit E-Cube                      *"
    Write-Host (" " * $ScreenSize) "***************************************"
}


#Function to show Documentation Menu
function printDocumentationMenu{
    $ScreenSize = [math]::Round($ConsoleWidth-58)/2
    Write-Host "`n"
    Write-Host (" " * $ScreenSize) "****************************|*****************************"
    Write-Host (" " * $ScreenSize) "**              E-Cube Documentation Menu               **"
    Write-Host (" " * $ScreenSize) "**********************************************************"
    Write-Host (" " * $ScreenSize) "*                                                        *"
    Write-Host (" " * $ScreenSize) "* Environment Documentation                              *"
    Write-Host (" " * $ScreenSize) "* |-> 1) Document all NSX Components                     *"
    Write-Host (" " * $ScreenSize) "* |-> 2) Document ESXi Host(s) Info                      *"
    Write-Host (" " * $ScreenSize) "* |-> 3) Document NSX Environment Diagram via VISIO Tool *"
    Write-Host (" " * $ScreenSize) "* |-> 4) Import vRealize Log Insight Dashboard           *"
    Write-Host (" " * $ScreenSize) "*                                                        *"
    Write-Host (" " * $ScreenSize) "* Networking Documentation                               *"
    Write-Host (" " * $ScreenSize) "* |-> 5) Document Routing info                           *"
    Write-Host (" " * $ScreenSize) "* |-> 6) Document VxLAN info                             *"
    Write-Host (" " * $ScreenSize) "*                                                        *"
    Write-Host (" " * $ScreenSize) "* Security Documentation                                 *"
    Write-Host (" " * $ScreenSize) "* |-> 7) Document NSX DFW info to Excel - DFW2Excel      *"
    Write-Host (" " * $ScreenSize) "* |-> 8) Document DFW-VAT                                *"
    Write-Host (" " * $ScreenSize) "*                                                        *"
    Write-Host (" " * $ScreenSize) "* 0) Exit Documentation Menu                             *"
    Write-Host (" " * $ScreenSize) "**********************************************************"
}


#Function to show Health Check Menu
function printHealthCheckMenu{
    $ScreenSize = [math]::Round($ConsoleWidth-41)/2
    Write-Host "`n"
    Write-Host (" " * $ScreenSize) "********************|********************"
    Write-Host (" " * $ScreenSize) "**       E-Cube Health Check Menu      **"
    Write-Host (" " * $ScreenSize) "*****************************************"
    Write-Host (" " * $ScreenSize) "*                                       *"
    Write-Host (" " * $ScreenSize) "* 1) NSX Connectivity Test              *"
    Write-Host (" " * $ScreenSize) "* 2) NSX Manager Test                   *"
    Write-Host (" " * $ScreenSize) "* 3) NSX Controllers Appliance Test     *"
    Write-Host (" " * $ScreenSize) "* 4) NSX Logical Switch Test            *"
    Write-Host (" " * $ScreenSize) "* 5) NSX Distributed Firewall Heap Test *"
    Write-Host (" " * $ScreenSize) "*                                       *"
    Write-Host (" " * $ScreenSize) "* 6) Check VDR Instance                 *"
    Write-Host (" " * $ScreenSize) "* 7) Check VIB Version                  *"
    Write-Host (" " * $ScreenSize) "*                                       *"
    Write-Host (" " * $ScreenSize) "* 0) Exit Health Check Menu             *"
    Write-Host (" " * $ScreenSize) "*****************************************"
}

clx
$ScreenSize = [math]::Round($ConsoleWidth-99)/2
Write-Host "`n"
Write-Host (" " * $ScreenSize) "__/\\\\\\\\\\\\\\\______________________/\\\\\\\\\________________/\\\_______________________        " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "__\/\\\///////////____________________/\\\////////________________\/\\\_______________________       " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) " _\/\\\_____________________________/\\\/_________________________\/\\\________________________      " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "  _\/\\\\\\\\\\\______/\\\\\\\\\\\__/\\\______________/\\\____/\\\_\/\\\____________/\\\\\\\\\__     " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "   _\/\\\///////______\///////////__\/\\\_____________\/\\\___\/\\\_\/\\\\\\\\\____/\\\//    /___    " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "    _\/\\\___________________________\//\\\____________\/\\\___\/\\\_\/\\\////\\\__/\\\\\\\\\_____   " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "     _\/\\\____________________________\///\\\__________\/\\\___\/\\\_\/\\\__\/\\\_\//\\/  //______  " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "      _\/\\\\\\\\\\\\\\\__________________\////\\\\\\\\\_\//\\\\\\\\\__\/\\\\\\\\\___\//\\\\\\\\\___ " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "       _\///////////////______________________\//|//////___\/////////___\/////////_____\/////////____" -BackgroundColor Black -ForegroundColor Blue

$ScreenSize = [math]::Round($ConsoleWidth-59)/2
Write-Host "`n"
Write-Host (" " * $ScreenSize) "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host (" " * $ScreenSize) "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host (" " * $ScreenSize) "~~                  Welcome to E-Cube                    ~~"
Write-Host (" " * $ScreenSize) "~~                A project by SA Team                   ~~"
Write-Host (" " * $ScreenSize) "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host (" " * $ScreenSize) "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host (" " * $ScreenSize) "~ Note: Please run this script in VMware PowerCLI.        ~"
Write-Host (" " * $ScreenSize) "~       To get the list of available commands type 'help' ~"
Write-Host (" " * $ScreenSize) "~       To exit the program type 'exit' or '0'.           ~"
Write-Host (" " * $ScreenSize) "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" 

#"`n                    What would you like to do today?" 
printMainMenu

while($true)
{
    Write-Host "`n>> Please select an e-cube option: " -ForegroundColor DarkGreen -NoNewline
    $sectionNumber = Read-Host

    if ($sectionNumber -eq 0 -or $sectionNumber -eq "exit"){
        if ($global:nsxManagerHost){Write-Host -ForegroundColor Yellow "Disconnecting NSX Server..."
        Disconnect-NsxServer}
        if ($global:vCenterHost){Write-Host -ForegroundColor Yellow "Disconnecting VIServer..."
        Disconnect-VIServer -Server * -Force}
        remove-variable -scope global myRow
        remove-variable -scope global myColumn
        
        break}
    elseif ($sectionNumber -eq "help"){printMainMenu}
    #elseif ($sectionNumber -eq "clear"){clear-host | printMainMenu}
    elseif ($sectionNumber -eq "clear"){clx | printMainMenu}

    elseif ($sectionNumber -eq 1){installPowerNSX($sectionNumber)}
    elseif ($sectionNumber -eq 2){connectNSXManager($sectionNumber)}
    elseif ($sectionNumber -eq 3){documentationkMenu($sectionNumber)}
    elseif ($sectionNumber -eq 4){healthCheckMenu($sectionNumber)}
    elseif ($sectionNumber -eq 5){nsxUpdateCheckReport($sectionNumber)}
    #elseif ($sectionNumber -eq 'test'){testFunction}
    elseif ($sectionNumber -eq ''){}
    #elseif ($sectionNumber -eq 5){runNSXVisualTool($sectionNumber)}
    else { Write-Host -ForegroundColor DarkRed "You have made an invalid choice!"}

}# Infinite while loop ends here 
####start-sleep -s 1