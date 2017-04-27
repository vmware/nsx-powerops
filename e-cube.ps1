# *-------------------------------------------* #
# ********************************************* #
#      VMware NSX e-Cube by @thisispuneet       #
# This script automate NSX-v day 2 Operations   #
# and help build the env networking documents   #
# ********************************************* #
# *-------------------------------------------* #
#                Version: GA 1.0                #
# *-------------------------------------------* #

#Setting up max window size and max buffer size
invoke-expression -Command .\maxWindowSize.ps1

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

    $subTitleFontSize = 10
    $subTitleFontBold = $True
    $subTitleFontName = "Calibri (Body)"
    $subTitleInteriorColor = 42

    $valueFontName = "Calibri (Body)"
    $valueFontSize = 10

    $subSetInteriorColor = 22

    $global:myRow = 1
    $global:myColumn = 1

    $global:ConsoleWidth = (Get-host).ui.RawUI.windowsize.width
    $global:listOfNSXPrepHosts=@()

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
    elseif ($documentationSectionNumber -eq 6){runDFW2Excel($documentationSectionNumber)}
    elseif ($documentationSectionNumber -eq 7){runDFWVAT($documentationSectionNumber)}
    
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


#---- Get Health Check Menu here - currently not using this function ----#
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
    <# Example of the code to cherrypick dic elements to plot on documentation excel.
    $allNSXComponentExcelData = @{"NSX Controllers Info" = $nsxControllers, "objectTypeName", "revision", "clientHandle", "isUniversal", "universalRevision", "id", "ipAddress", "status", "upgradeStatus", "version", "upgradeAvailable", "virtualMachineInfo", "hostInfo", "resourcePoolInfo", "clusterInfo", "managedBy", "datastoreInfo", "controllerClusterStatus", "diskLatencyAlertDetected", "vmStatus"; 
    "NSX Manager Info" = $nsxManagerSummary, "ipv4Address", "dnsName", "hostName", "applianceName", "versionInfo", "uptime", "cpuInfoDto", "memInfoDto", "storageInfoDto", "currentSystemDate"; 
    "NSX Manager vCenter Configuration" = $nsxManagerVcenterConfig, "ipAddress", "userName", "certificateThumbprint", "assignRoleToUser", "vcInventoryLastUpdateTime", "Connected";
    "NSX Edge Info" = $nsxEdges, "id", "version", "status", "datacenterMoid", "datacenterName", "tenant", "name", "fqdn", "enableAesni", "enableFips", "vseLogLevel", "vnics", "appliances", "cliSettings", "features", "autoConfiguration", "type", "isUniversal", "hypervisorAssist", "queryDaemon", "edgeSummary";
    "NSX Logical Router Info" = $nsxLogicalRouters, "id", "version", "status", "datacenterMoid", "datacenterName", "tenant", "name", "fqdn", "enableAesni", "enableFips", "vseLogLevel", "appliances", "cliSettings", "features", "autoConfiguration", "type", "isUniversal", "mgmtInterface", "interfaces", "edgeAssistId", "lrouterUuid", "queryDaemon", "edgeSummary"}
    #>
    $allNSXComponentExcelDataMgr =@{"NSX Manager Info" = $nsxManagerSummary, "all"; "NSX Manager vCenter Configuration" = $nsxManagerVcenterConfig, "all"}
    
    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "NSX-Components-Excel"
    $nsxComponentExcelWorkBook = createNewExcel($excelName)
    
    ####plotDynamicExcel one workBook at a time
    $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName "NSX Manager" -listOfDataToPlot $allNSXComponentExcelDataMgr
    # Creating seperate worksheet for each controller, edge, and dlr 
    foreach ($eachNSXController in $nsxControllers){
        $nsxComponentExcelDataControllers =@{}
        $controllerID = $eachNSXController.id
        $tempControllerData = $eachNSXController, "all"
        $nsxComponentExcelDataControllers.Add($eachNSXController.id, $tempControllerData)
        if ($controllerID.length -gt 16){ $nsxComponentWorkSheetName = "NSX Controller-$($controllerID.substring(0,15))" }else{$nsxComponentWorkSheetName = "NSX Controller-$controllerID"}
        $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName $nsxComponentWorkSheetName -listOfDataToPlot $nsxComponentExcelDataControllers
    }
    foreach ($eachNSXEdge in $nsxEdges){
        $nsxComponentExcelDataEdge =@{}
        $edgeID = $eachNSXEdge.id
        $tempNSXEdgeData = $eachNSXEdge, "all"
        $nsxComponentExcelDataEdge.Add($eachNSXEdge.id, $tempNSXEdgeData)
        if ($edgeID.length -gt 22){ $nsxComponentWorkSheetName = "NSX Edge-$($edgeID.substring(0,21))" }else{$nsxComponentWorkSheetName = "NSX Edge-$edgeID"}
        $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName $nsxComponentWorkSheetName -listOfDataToPlot $nsxComponentExcelDataEdge
    }
    foreach ($eachNSXDLR in $nsxLogicalRouters){
        $nsxComponentExcelDataDLR =@{}
        $dlrID = $eachNSXDLR.id
        $tempNSXDLRData = $eachNSXDLR, "all"
        $nsxComponentExcelDataDLR.Add($eachNSXDLR.id, $tempNSXDLRData)
        if ($dlrID.length -gt 22){ $nsxComponentWorkSheetName = "NSX DLR-$($dlrID.substring(0,21))" }else{$nsxComponentWorkSheetName = "NSX DLR-$dlrID"}
        $plotNSXComponentExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxComponentExcelWorkBook -workSheetName $nsxComponentWorkSheetName -listOfDataToPlot $nsxComponentExcelDataDLR
    }
    
    #$nsxComponentExcelWorkBook.SaveAs()
    $global:newExcel.ActiveWorkbook.SaveAs()
    $global:newExcel.Workbooks.Close()
    $global:newExcel.Quit()
    Write-Host -ForegroundColor Green "`n Done Working on the Excel Sheet."
    #Loop back to document Menu
    documentationkMenu(22) #Keep in Documentation Menu
}

#Get Host info here
function getHostInformation($sectionNumber){
    $userSelection = "Get List of Hosts"
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now executing '$userSelection'..."
    #$vmHosts = get-vmhost
    getNSXPrepairedHosts
    $vmHosts = $global:listOfNSXPrepHosts
    Write-Host " Number of NSX Prepaired vmHosts are:" $vmHosts.length

    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "ESXi-Hosts-Excel"
    $nsxHosttExcelWorkBook = createNewExcel($excelName)
    foreach ($eachVMHost in $vmHosts){
        $esxcli = $eachVMHost | Get-EsxCli -v2
        $sshCommandOutputDataLogicalSwitch = @{}
        $sshCommandOutputDataVMKNIC = @{}
        $sshCommandOutputDataRouteTable = @{}
        $tempHostDataRouteTable=@()
        $sshCommandOutputLable = @()
        $allHostVIBList = @()
        $nsxVIBList = @()
        $listOfDLRCmd = @()
        $allHostNICList =@()
        $gotVXLAN = $false

        $myHostID = $eachVMHost.id
        $myHostName = $eachVMHost.Name
        $myParentClusterID = $eachVMHost.ParentId
        if ($myHostID -match "HostSystem-"){$myNewHostID = $myHostID -replace "HostSystem-", ""}else{$myNewHostID = $myHostID}

        <#
        # Run SSH Command to get Logical Switch Info from NSX Manager here...
        [string]$nsxMgrCommandLogicalSwitch = "show logical-switch host "+$myNewHostID+" verbose"
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommandLogicalSwitch -fileName "logical-switch-info.txt"
        $findElements= @("Control plane Out-Of-Sync", "MTU", "VXLAN vmknic")
        $sshCommandOutputDataLogicalSwitch = parseSSHOutput -fileToParse "logical-switch-info.txt" -findElements $findElements -direction "Row"
        #>
        get-cluster -Server $NSXConnection.ViConnection | %{ if ($_.id -eq $myParentClusterID){
            get-cluster $_ | Get-NsxClusterStatus | %{ if($_.featureId -eq "com.vmware.vshield.vsm.vxlan" -And $_.installed -eq "true"){
                    try{
						$vdsInfo = $esxcli.network.vswitch.dvs.vmware.vxlan.list.invoke()
						$myVDSName = $vdsInfo.VDSName
						$sshCommandOutputDataLogicalSwitch.Add("VXLAN Installed", "True")
						$sshCommandOutputDataLogicalSwitch.Add("VDSName", $myVDSName)
						$sshCommandOutputDataLogicalSwitch.Add("GatewayIP", $vdsInfo.GatewayIP)
						$sshCommandOutputDataLogicalSwitch.Add("MTU", $vdsInfo.MTU)

						$vmknicInfo = $esxcli.network.vswitch.dvs.vmware.vxlan.vmknic.list.invoke(@{"vdsname" = $myVDSName})
						$myVmknicName = $vmknicInfo.VmknicName
						$sshCommandOutputDataVMKNIC.Add("VmknicCount", $vdsInfo.VmknicCount)
						$sshCommandOutputDataVMKNIC.Add("VmknicName", $myVmknicName)
						$sshCommandOutputDataVMKNIC.Add("IP", $vmknicInfo.IP)
						$sshCommandOutputDataVMKNIC.Add("Netmask", $vmknicInfo.Netmask)

						$gotVXLAN = $true
					}catch{$ErrorMessage = $_.Exception.Message
						if ($ErrorMessage -eq "You cannot call a method on a null-valued expression."){
							Write-Host " Warning: No VxLAN data found on this Host $myHostName" -ForegroundColor Red
							$gotVXLAN = $false
						}else{Write-Host $ErrorMessage}
					}
            }}
        }}
        if($gotVXLAN -eq $false){
            $sshCommandOutputDataLogicalSwitch.Add("VXLAN Installed", "False")
            $sshCommandOutputDataVMKNIC.Add("VmknicCount", "0")}

        # Run SSH Command to get Route Table Info from NSX Manager here...
        $getDLRs = Get-NsxLogicalRouter
        $findLogicalSwitchElements= @("Destination")
        #$findLogicalSwitchElements= @("show")
        if($getDLRs.gettype().BaseType.Name -eq "Array"){
            $getDLRs | %{
                $nsxMgrCommandRouteTable = "show logical-router host "+$myNewHostID+" dlr "+$($_.id)+" route"
                invokeNSXCLICmd -commandToInvoke $nsxMgrCommandRouteTable -fileName $nsxMgrCommandRouteTable
                $parsedRouteTable = parseSSHOutput -fileToParse $nsxMgrCommandRouteTable -findElements $findLogicalSwitchElements -direction "Column"
                $sshCommandOutputDataRouteTable.Add($nsxMgrCommandRouteTable, $parsedRouteTable.$($parsedRouteTable.keys))
                $listOfDLRCmd += $nsxMgrCommandRouteTable
                }
            $tempHostDataRouteTable = $sshCommandOutputDataRouteTable, $listOfDLRCmd
        }else{
            $nsxMgrCommandRouteTable = "show logical-router host "+$myNewHostID+" dlr "+$getDLRs.id+" route"
            invokeNSXCLICmd -commandToInvoke $nsxMgrCommandRouteTable -fileName $nsxMgrCommandRouteTable
            $parsedRouteTable = (parseSSHOutput -fileToParse $nsxMgrCommandRouteTable -findElements $findLogicalSwitchElements -direction "Column")
            $sshCommandOutputDataRouteTable.Add($nsxMgrCommandRouteTable, $parsedRouteTable.$($parsedRouteTable.keys))
            $tempHostDataRouteTable = $sshCommandOutputDataRouteTable, $nsxMgrCommandRouteTable
        }
        # NSX Manager SSH Command Ends here.

        # Run ESXCLI Command to get VIB List Info from ESXi Host here...
        $allHostVIBList += $esxcli.software.vib.list.invoke() | Select-Object @{N="VMHostName"; E={$VMHostName}}, *
        #Filter out VIB with starting name 'esx-v'
        $allHostVIBList | %{if ($_.name.StartsWith("esx-v")){$nsxVIBList += $_}}
        # End ESXCLI Command here.

        $allHostNICList += $esxcli.network.nic.list.Invoke() | Select-Object @{N="VMHostName"; E={$VMHostName}}, *

        $allVmHostsExcelData=@{}
        $tempHostData=@()
        $tempHostDataMgrDetails=@()
        $tempHostDataVmkNicDetails=@()
        
        $tempHostDataNSXVIBList=@()
        $tempHostDataNSXNICList=@()
        #$allVmHostsExcelData = @{"ESXi Host" = $eachVMHost, "Name", "ConnectionState", "PowerState", "NumCpu", "CpuUsageMhz", "CpuTotalMhz", "MemoryUsageGB", "MemoryTotalGB", "Version"}
        $tempHostData = $eachVMHost, "all"
        if ($gotVXLAN -eq $true){
            $tempHostDataMgrDetails = $sshCommandOutputDataLogicalSwitch, "VXLAN Installed", "VDSName", "GatewayIP","MTU"
            $tempHostDataVmkNicDetails = $sshCommandOutputDataVMKNIC, "VmknicCount", "VmknicName", "IP", "Netmask"
        }else{
            $tempHostDataMgrDetails = $sshCommandOutputDataLogicalSwitch, "VXLAN Installed"
            $tempHostDataVmkNicDetails = $sshCommandOutputDataVMKNIC, "VmknicCount"}

        #$tempHostDataMgrDetails = $sshCommandOutputDataLogicalSwitch, "Control plane Out-Of-Sync", "MTU", "VXLAN vmknic"
        #$tempHostDataRouteTable = $sshCommandOutputDataRouteTable, "route-table-info.txt"
        ##$tempHostDataRouteTable = $sshCommandOutputDataRouteTable, "all"
        $tempHostDataNSXVIBList = $nsxVIBList, "AcceptanceLevel", "CreationDate", "InstallDate", "Name", "Version" 
        $tempHostDataNSXNICList = $allHostNICList, "all"

        $allVmHostsExcelData.Add("A) "+$myNewHostID, $tempHostData)
        $allVmHostsExcelData.Add("B) Route Table", $tempHostDataRouteTable)
        $allVmHostsExcelData.Add("C) Host VDSwitch Details", $tempHostDataMgrDetails)
        $allVmHostsExcelData.Add("D) Host VMKnic Details", $tempHostDataVmkNicDetails)
        $allVmHostsExcelData.Add("E) NSX VIB List", $tempHostDataNSXVIBList)
        $allVmHostsExcelData.Add("F) NSX VM NIC List", $tempHostDataNSXNICList)
        if ($myHostName.length -gt 31){ $hostWorkSheetName = $myHostName.substring(0,30) }else{$hostWorkSheetName = $myHostName}

        ####plotDynamicExcel one workBook at a time
        $plotHostInformationExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxHosttExcelWorkBook -workSheetName $hostWorkSheetName -listOfDataToPlot $allVmHostsExcelData
        ####writeToExcel -eachDataElementToPrint $sshCommandOutputDataLogicalSwitch -listOfAllAttributesToPrint $sshCommandOutputLable
    }
    #invokeNSXCLICmd(" show logical-switch host host-31 verbose ")
    #$nsxHosttExcelWorkBook.SaveAs()
    $global:newExcel.ActiveWorkbook.SaveAs()
    $global:newExcel.Workbooks.Close()
    $global:newExcel.Quit()
    Write-Host -ForegroundColor Green "`n Done Working on the Excel Sheet."
    documentationkMenu(22)
}

#Run visio tool
function runNSXVISIOTool($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now starting VISIO tool..."
    $capturePath = invoke-expression -Command .\DiagramNSX\NsxObjectCapture.ps1
    ##Write-Host "`n Capture Path is: $capturePath"
    #$pathVISIO = Read-Host -Prompt " Please provide the above .zip file path to generate the VISIO file"
    #$visioDiagramCommand = ".\DiagramNSX\NsxObjectDiagram.ps1 -CaptureBundle " + $pathVISIO
    $visioDiagramCommand = ".\DiagramNSX\NsxObjectDiagram.ps1 -CaptureBundle " + $capturePath
    ##Write-Host "DiagramCommand is: $visioDiagramCommand"
    invoke-expression -Command $visioDiagramCommand
    documentationkMenu(22)
}

#Download Log Insite's Dashboard
function importLogInSightDashBoard($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now starting VISIO tool..."
    Write-Host "`n Currently this feature is disabled."
    ##$lisVersion = Read-Host -Prompt " Please provide your Log Insite Version"
    ##Write-Host "`n Downloading custom Dashboard for your Log Insite version..."
}

#Get Routing info here
function getRoutingInformation($sectionNumber){
    $tempTXTFileNamesList = @()
    $userSelection = "Get Routing Information"
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now executing '$userSelection'..."
    
    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "NSX-Routing-Excel"
    $nsxRoutingExcelWorkBook = createNewExcel($excelName)

    # Getting Edge Routing Info here
    $numberOfEdges = Get-NsxEdge
    foreach ($eachEdge in $numberOfEdges){
        $allEdgeRoutingExcelData = @{}
        $edgeName = $eachEdge.Name
        $edgeID = $eachEdge.id
        $edgeRoutingInfo = Get-NsxEdge $edgeName | Get-NsxEdgeRouting        
        $tempEdgeRoutingValueArray = $edgeRoutingInfo, "all"
        $allEdgeRoutingExcelData.Add("A) "+$edgeName, $tempEdgeRoutingValueArray)

        #Run SSH Command to get IP Route Info
        [string]$ipRouteCommand = "show edge $edgeID ip route"
        $txtFileName = $ipRouteCommand
        #invokeNSXCLICmd -commandToInvoke $ipRouteCommand -fileName "ip-route-info.txt"
        invokeNSXCLICmd -commandToInvoke $ipRouteCommand -fileName $txtFileName
        #Parse SSH Output here
        $findIPRouteElements= @("Total number of routes")
        $sshCommandOutputIPRouteInfo = parseSSHOutput -fileToParse $txtFileName -findElements $findIPRouteElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalIPRouteInfo = $sshCommandOutputIPRouteInfo, $txtFileName
        $allEdgeRoutingExcelData.Add("B) Route IP Table", $finalIPRouteInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get Route Forwarding Info
        [string]$routeForwardingCommand = "show edge $edgeID ip forwarding"
        $txtFileName = $routeForwardingCommand
        invokeNSXCLICmd -commandToInvoke $routeForwardingCommand -fileName $txtFileName
        #Parse SSH Output here
        $findRouteFwdElements= @("haIndex")
        $sshCommandOutputRouteFwdInfo = parseSSHOutput -fileToParse $txtFileName -findElements $findRouteFwdElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteFwdInfo = $sshCommandOutputRouteFwdInfo, $txtFileName
        $allEdgeRoutingExcelData.Add("C) Route Forwarding Table", $finalRouteFwdInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get Route BGP Info
        [string]$routeBGPCommand = "show edge $edgeID ip bgp"
        $txtFileName = $routeBGPCommand
        invokeNSXCLICmd -commandToInvoke $routeBGPCommand -fileName $txtFileName
        #Parse SSH Output here
        $findRouteBGPElements= @("haIndex")
        $sshCommandOutputRouteBGPInfo = parseSSHOutput -fileToParse $txtFileName -findElements $findRouteBGPElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteBGPInfo = $sshCommandOutputRouteBGPInfo, $txtFileName
        $allEdgeRoutingExcelData.Add("D) Route BGP Table", $finalRouteBGPInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get Route BGP Neighbors Info
        [string]$routeBGPNeighborsCommand = "show edge $edgeID ip bgp neighbors"
        $txtFileName = $routeBGPNeighborsCommand
        invokeNSXCLICmd -commandToInvoke $routeBGPNeighborsCommand -fileName $txtFileName
        #Parse SSH Output here
        $findRouteBGPNeighborsElements= @("haIndex")
        $sshCommandOutputRouteBGPNeighborsInfo = parseSSHOutput -fileToParse $txtFileName -findElements $findRouteBGPNeighborsElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteBGPNeighborsInfo = $sshCommandOutputRouteBGPNeighborsInfo, $txtFileName
        $allEdgeRoutingExcelData.Add("E) BGP Neighbors", $finalRouteBGPNeighborsInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get Route OSPF Info
        [string]$routeOSPFCommand = "show edge $edgeID ip ospf"
        $txtFileName = $routeOSPFCommand
        invokeNSXCLICmd -commandToInvoke $routeOSPFCommand -fileName $txtFileName
        #Parse SSH Output here
        $findRouteOSPFElements= @("haIndex")
        $sshCommandOutputRouteOSPFInfo = parseSSHOutput -fileToParse $txtFileName -findElements $findRouteOSPFElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteOSPFInfo = $sshCommandOutputRouteOSPFInfo, $txtFileName
        $allEdgeRoutingExcelData.Add("F) Route OSPF Table", $finalRouteOSPFInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get Route OSPF Neighbors Info
        [string]$routeOSPFNeighborsCommand = "show edge $edgeID ip ospf neighbors"
        $txtFileName = $routeOSPFNeighborsCommand
        invokeNSXCLICmd -commandToInvoke $routeOSPFNeighborsCommand -fileName $txtFileName
        #Parse SSH Output here
        $findRouteOSPFNeighborsElements= @("haIndex")
        $sshCommandOutputRouteOSPFNeighborsInfo = parseSSHOutput -fileToParse $txtFileName -findElements $findRouteOSPFNeighborsElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteOSPFNeighborsInfo = $sshCommandOutputRouteOSPFNeighborsInfo, $txtFileName
        $allEdgeRoutingExcelData.Add("G) OSPF Neighbors", $finalRouteOSPFNeighborsInfo)
        $tempTXTFileNamesList += $txtFileName

        if ($edgeID.length -gt 13){ $nsxEdgeWorkSheetName = "NSX Edge Routing-$($edgeID.substring(0,13))" }else{$nsxEdgeWorkSheetName = "NSX Edge Routing-$edgeID"}
        $plotNSXRoutingExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxRoutingExcelWorkBook -workSheetName $nsxEdgeWorkSheetName -listOfDataToPlot $allEdgeRoutingExcelData
    }

    # Getting DLR routing Info here
    $numberOfDLRs = Get-NsxLogicalRouter
    foreach($eachDLR in $numberOfDLRs){
        $allDLRRoutingExcelData = @{}
        $dlrID = $eachDLR.id
        $dlrName = $eachDLR.Name
        $dlrRoutinginfo = Get-NsxLogicalRouter $dlrName | Get-NsxLogicalRouterRouting
        $tempDLRRoutingValueArray = $dlrRoutinginfo, "all"
        $allDLRRoutingExcelData.Add("A) "+$dlrName, $tempDLRRoutingValueArray)

        #get host id here
        $nsxLogicalRouter = Get-NsxLogicalRouter $dlrName
        $nsxLogicalRouterHostID = $nsxLogicalRouter.appliances.appliance.hostId
        if($nsxLogicalRouterHostID.gettype().BaseType.Name -eq "Array"){[String]$hostID = $nsxLogicalRouterHostID[0]
        }else{[String]$hostID = $nsxLogicalRouterHostID}

        #Run SSH Command to get Route Table
        #[string]$nsxMgrCommandRouteTable = "show logical-router host "+$hostID+" dlr "+$dlrID+" route"
        [string]$nsxMgrCommandRouteTable = "show edge $dlrID ip route"
        $txtFileName = $nsxMgrCommandRouteTable
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommandRouteTable -fileName $txtFileName
        #Parse SSH Output here
        $findLogicalSwitchElements= @("haIndex")
        $sshCommandOutputDataRouteTable = parseSSHOutput -fileToParse $txtFileName -findElements $findLogicalSwitchElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $tempDLRRoutingValueArray2 = $sshCommandOutputDataRouteTable, $txtFileName
        $allDLRRoutingExcelData.Add("B) Route IP Table", $tempDLRRoutingValueArray2)
        $tempTXTFileNamesList += $txtFileName
        
        #Run SSH Command to get Route Table
        [string]$nsxMgrCommandIPFwd = "show edge $dlrID ip forwarding"
        $txtFileName = $nsxMgrCommandIPFwd
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommandIPFwd -fileName $txtFileName
        #Parse SSH Output here
        $findIPFwdElements= @("haIndex")
        $sshCommandOutputDataIPFwd = parseSSHOutput -fileToParse $txtFileName -findElements $findIPFwdElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $tempIPFwdValueArray2 = $sshCommandOutputDataIPFwd, $txtFileName
        $allDLRRoutingExcelData.Add("C) Route Forwarding Table", $tempIPFwdValueArray2)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get BGP Table
        [string]$nsxMgrCommandBGPTable = "show edge $dlrID ip bgp"
        $txtFileName = $nsxMgrCommandBGPTable
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommandBGPTable -fileName $txtFileName
        #Parse SSH Output here
        $findtxtFileElements= @("haIndex")
        $sshCommandOutputDataBGPTable = parseSSHOutput -fileToParse $txtFileName -findElements $findtxtFileElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteBGPInfo = $sshCommandOutputDataBGPTable, $txtFileName
        $allDLRRoutingExcelData.Add("D) BGP Table", $finalRouteBGPInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get BGP Neighbors Table
        [string]$nsxMgrCommandBGPNeighborsTable = "show edge $dlrID ip bgp neighbors"
        $txtFileName = $nsxMgrCommandBGPNeighborsTable
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommandBGPNeighborsTable -fileName $txtFileName
        #Parse SSH Output here
        $findtxtFileElements= @("haIndex")
        $sshCommandOutputDataBGPNeighborsTable = parseSSHOutput -fileToParse $txtFileName -findElements $findtxtFileElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteBGPNeighborsInfo = $sshCommandOutputDataBGPNeighborsTable, $txtFileName
        $allDLRRoutingExcelData.Add("E) BGP Neighbors Info", $finalRouteBGPNeighborsInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get OSPF Table
        [string]$nsxMgrCommandOSPFTable = "show edge $dlrID ip ospf"
        $txtFileName = $nsxMgrCommandOSPFTable
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommandOSPFTable -fileName $txtFileName
        #Parse SSH Output here
        $findtxtFileElements= @("haIndex")
        $sshCommandOutputDataOSPFTable = parseSSHOutput -fileToParse $txtFileName -findElements $findtxtFileElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteOSPFInfo = $sshCommandOutputDataOSPFTable, $txtFileName
        $allDLRRoutingExcelData.Add("F) OSPF Table", $finalRouteOSPFInfo)
        $tempTXTFileNamesList += $txtFileName

        #Run SSH Command to get OSPF Neighbors Table
        [string]$nsxMgrCommandOSPFNeighborsTable = "show edge $dlrID ip ospf neighbors"
        $txtFileName = $nsxMgrCommandOSPFNeighborsTable
        invokeNSXCLICmd -commandToInvoke $nsxMgrCommandOSPFNeighborsTable -fileName $txtFileName
        #Parse SSH Output here
        $findtxtFileElements= @("haIndex")
        $sshCommandOutputDataOSPFNeighborsTable = parseSSHOutput -fileToParse $txtFileName -findElements $findtxtFileElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalRouteOSPFNeighborsInfo = $sshCommandOutputDataOSPFNeighborsTable, $txtFileName
        $allDLRRoutingExcelData.Add("G) OSPF Neighbors Info", $finalRouteOSPFNeighborsInfo)
        $tempTXTFileNamesList += $txtFileName

        #Make sure workbook name wont exceed 31 letters
        if ($dlrID.length -gt 14){ $nsxDLRWorkSheetName = "NSX DLR Routing-$($dlrID.substring(0,13))" }else{$nsxDLRWorkSheetName = "NSX DLR Routing-$dlrID"}
        #Plot the NSX Route final
        $plotNSXRoutingExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxRoutingExcelWorkBook -workSheetName $nsxDLRWorkSheetName -listOfDataToPlot $allDLRRoutingExcelData
    }
    #$nsxRoutingExcelWorkBook.SaveAs()
    $global:newExcel.ActiveWorkbook.SaveAs()
    $global:newExcel.Workbooks.Close()
    $global:newExcel.Quit()
    $tempTXTFileNamesList | %{ Remove-Item ./$_}
    Write-Host -ForegroundColor Green "`n Done Working on the Excel Sheet."
    documentationkMenu(22)
}

<#
#get VXLAN Info
function getVXLANInformation($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now documenting VXLAN Info to the excel file..."

    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $excelName = "NSX-VXLAN-Excel"
    $nsxVXLANExcelWorkBook = createNewExcel($excelName)
    $numberOfEdges = Get-NsxEdge
    $edgeInterfaceInfo = @()
    foreach ($eachEdge in $numberOfEdges){
        $allVXLANExcelData = @{}
        Get-NsxEdge $eachEdge.name | Get-NsxEdgeInterface | %{ if($_.isConnected -eq "TRUE"){$edgeInterfaceInfo += $_}}
        $tempEdgeInterfaceValueArray = $edgeInterfaceInfo, "all"
        $allVXLANExcelData.Add($eachEdge.name, $tempEdgeInterfaceValueArray)
        $plotNSXInterfaceExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxVXLANExcelWorkBook -workSheetName $eachEdge.name -listOfDataToPlot $allVXLANExcelData     
    }
    documentationkMenu(22)
}
#>

#Run DFW2Excel
function runDFW2Excel($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now documenting DFW to excel file..."
    invoke-expression -Command .\PowerNSX-DFW2Excel\DFW2Excel.ps1
    documentationkMenu(22)
}


#Run DFW-VAT
function runDFWVAT($sectionNumber){
    Write-Host -ForegroundColor Darkyellow "You have selected # '$sectionNumber'. Now Exicuting DFW VATool..."
    Write-Host "Need python2.7 to run DFW-VAT. Currently disabled."
    #invoke DFW_VAT subgit folder here...
    #invoke-expression -Command .\PowerNSX-Scripts\DFW2Excel.ps1
    documentationkMenu(22)
}


function getMemberWithProperty($tempListOfAllAttributesInFunc){
    #$listOfAllAttributesWithCorrectProperty = New-Object System.Collections.ArrayList
    $listOfAllAttributesWithCorrectProperty = @()
    foreach($eachAttribute in $tempListOfAllAttributesInFunc){
        if ($eachAttribute.MemberType -eq "Property" -or $eachAttribute.MemberType -eq "NoteProperty"){
            $listOfAllAttributesWithCorrectProperty += $eachAttribute.Name}
    }
    #write-Host "List of properties to print are: $listOfAllAttributesWithCorrectProperty"
    return ,$listOfAllAttributesWithCorrectProperty
}


function invokeNSXCLICmd($commandToInvoke, $fileName){
    Write-Host -ForeGroundColor Yellow "`n Note: CLI Command Invoked:" $commandToInvoke
    
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


function getNSXPrepairedHosts() {
    $allEnvClusters = get-cluster -Server $NSXConnection.ViConnection | %{
        $nsxCluster = $_
        get-cluster $_ | Get-NsxClusterStatus | %{
            if($_.featureId -eq "com.vmware.vshield.vsm.nwfabric.hostPrep" -And $_.installed -eq "true"){
                $global:listOfNSXPrepHosts += $nsxCluster | get-vmhost}}
    }
    $global:listOfNSXPrepHosts = $global:listOfNSXPrepHosts | Sort-Object -unique
}


function parseSSHOutput ($fileToParse, $findElements, $direction) {
    $sshCommandOutputParsedDic = @{}
    $findElements | %{
        $indx = ''
        $indx = Select-String $_ $fileToParse | ForEach-Object {$_.LineNumber}
        $totalLines = get-content $fileToParse | Measure-Object -Line
        if ($indx -ne '' -and $direction -eq "Row"){
            if($indx.gettype().BaseType.Name -eq "Array"){
                $tempelementResultArray = @()
                $indx | %{ [string]$eachElementResult = (Get-Content $fileToParse)[$_ -1]
                $tempelementResultArray += $eachElementResult}
            $sshCommandOutputParsedDic.Add($_, $tempelementResultArray)
            }else{
            [string]$eachElementResult = (Get-Content $fileToParse)[$indx -1]
            $sshCommandOutputParsedDic.Add($_, $eachElementResult)}
        }elseif($indx -ne '' -and $direction -eq "Column"){
            [string]$eachElementResult = ""
            $startLineNumberRT = $indx -1
            $endLineNumberRT = $totalLines.lines +1
            $startLineNumberRT..$endLineNumberRT | %{
                $eachElementResult = $eachElementResult + (Get-Content $fileToParse)[$_] + "`n"
            }
            $sshCommandOutputParsedDic.Add($fileToParse, $eachElementResult)
        }
    }
    return $sshCommandOutputParsedDic
}

function clx {
    [System.Console]::SetWindowPosition(0,[System.Console]::CursorTop)
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


# ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- Excel Functions start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- # 

#Create empty excel sheet here w/ correct name 
function createNewExcel($newExcelName){
    $startTime = Get-Date
    $newExcelNameWithDate = $newExcelName +"-"+ $startTime.ToString("yyyy-MM-dd-hh-mm") + ".xlsx"
    Write-Host -ForeGroundColor Green "`n Creating Excel File:" $newExcelNameWithDate
    
    #$xlFixedFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlWorkbookDefault
    $global:newExcel = New-Object -Com Excel.Application
    $global:newExcel.visible = $false
    $global:newExcel.DisplayAlerts = $false
    #$Excel.Name = "Test Excel Name"
    $wb = $global:newExcel.Workbooks.Add()
    #$sheet = $wb.ActiveSheet
    
    # Save the excel with provided Name
    #$newExcel.ActiveWorkbook.SaveAs($newExcelNameWithDate, $xlFixedFormat)
    $global:newExcel.ActiveWorkbook.SaveAs($newExcelNameWithDate)
    return $wb
} # End of function createNewExcel

# Plot excel sheet here one workBook at a time ..pass already created Excel, Worksheet Name, List of values need to be plotted.
# Call this function seperatelly for multiple Work Sheets.
function plotDynamicExcelWorkBook($myOpenExcelWBReturn, $workSheetName, $listOfDataToPlot){
    $listOfAllAttributes =@()
    Write-Host -ForeGroundColor Green "`n Creating WorkSheet: $workSheetName. This can take upto 10 mins..."
    $global:myRow =1
    $global:myColumn=1
    $sheet = $myOpenExcelWBReturn.WorkSheets.Add()
    $sheet.Name = $workSheetName
    $sheet.Cells.Item(1,1) = $workSheetName
    
    #Use this loop for nonsorted dic data: foreach($eachDataSetKey in $listOfDataToPlot.Keys){
    foreach($eachsortedDataSetKey in $listOfDataToPlot.GetEnumerator() | Sort Name){
        $eachDataSetKey = $eachsortedDataSetKey.name
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
            $listOfAllAttributes = @()
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
    ##Write-Host "eachDataElementToPrint type is:" $eachDataElementToPrint.gettype()
    ##Write-Host "list Of All Attributes are:" $listOfAllAttributesToPrint
    ##Write-Host "myRow again is:" $global:myRow
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
                    }else{
                        $sheet.Cells.Item($global:myRow,$global:myColumn) = $eachLabelToPrint
                        $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Size = $subTitleFontSize
                        $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Bold = $subTitleFontBold
                        $sheet.Cells.Item($global:myRow,$global:myColumn).Font.Name = $subTitleFontName
                        $sheet.Cells.Item($global:myRow,$global:myColumn).Interior.ColorIndex = $subTitleInteriorColor
                        
                        $sheet.Cells.Item($global:myRow,$global:myColumn+1) = $newElementOfArrayToPrint
                        $sheet.Cells.Item($global:myRow,$global:myColumn+1).Font.Size = $valueFontSize
                        $sheet.Cells.Item($global:myRow,$global:myColumn+1).Font.Name = $valueFontName
                        $sheet.Cells.Item($global:myRow,$global:myColumn+1).HorizontalAlignment = -4131
                        #Write-Host "    " $eachLabelToPrint "is:" $eachDataElementToPrint.$eachLabelToPrint
                        $global:myRow++
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
            #$sheet.Cells.Item($global:myRow,$global:myColumn).Font.Size = $subTitleFontSize
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
    Write-Host (" " * $ScreenSize) "**        PowerOps Main Menu         **"
    Write-Host (" " * $ScreenSize) "***************************************"
    Write-Host (" " * $ScreenSize) "*                                     *"
    Write-Host (" " * $ScreenSize) "* 1) Install PowerNSX                 *"
    Write-Host (" " * $ScreenSize) "* 2) Connect NSX Manager & vCenter    *"
    Write-Host (" " * $ScreenSize) "* 3) Show Documentation Menu          *"
    Write-Host (" " * $ScreenSize) "* 4) Show Health Check Menu           *"
#    Write-Host (" " * $ScreenSize) "* 5) Check NSX Upgrade Prerequisites  *"
    Write-Host (" " * $ScreenSize) "*                                     *"
    Write-Host (" " * $ScreenSize) "* 0) Exit PowerOps                    *"
    Write-Host (" " * $ScreenSize) "***************************************"
}


#Function to show Documentation Menu
function printDocumentationMenu{
    $ScreenSize = [math]::Round($ConsoleWidth-58)/2
    Write-Host "`n"
    Write-Host (" " * $ScreenSize) "****************************|*****************************"
    Write-Host (" " * $ScreenSize) "**             PowerOps Documentation Menu              **"
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
#    Write-Host (" " * $ScreenSize) "* |-> 6) Document VxLAN info                             *"
    Write-Host (" " * $ScreenSize) "*                                                        *"
    Write-Host (" " * $ScreenSize) "* Security Documentation                                 *"
    Write-Host (" " * $ScreenSize) "* |-> 6) Document NSX DFW info to Excel - DFW2Excel      *"
    Write-Host (" " * $ScreenSize) "* |-> 7) Document DFW-VAT                                *"
    Write-Host (" " * $ScreenSize) "*                                                        *"
    Write-Host (" " * $ScreenSize) "* 0) Exit Documentation Menu                             *"
    Write-Host (" " * $ScreenSize) "**********************************************************"
}


#Function to show Health Check Menu
function printHealthCheckMenu{
    $ScreenSize = [math]::Round($ConsoleWidth-41)/2
    Write-Host "`n"
    Write-Host (" " * $ScreenSize) "********************|********************"
    Write-Host (" " * $ScreenSize) "**      PowerOps Health Check Menu     **"
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
$ScreenSize = [math]::Round($ConsoleWidth-127)/2
Write-Host "`n"
Write-Host (" " * $ScreenSize) "  __/\\\\\\\\\\\_______________________________________________|__________________/\\\\\________________________________        " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "   _\/\\\///////\\\______________________________________________________________/\\\///\\\______________________________       " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "    _\/\\\_____\/\\\____________________________________________________________/\\\/__\///\\\____/\\\\\\\\\______________      " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "     _\/\\\\\\\\\\\/___/\\\\\_____/\\ __ /\\ _ /\\____/\\\\\\\\\__/\\/\\\\\\___/\\\______\//\\\__/\\\/___/\\\__/\\\\\\\\\\_     " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "      _\/\\\///////___/\\\///\\\__\/\\\  /\\\\ /\\\__/\\\///\\//__\/\\\////\\\_\/\\\_______\/\\\_\/\\\___\\\\__\/\\\/___//__    " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "       _\/\\\_________/\\\__\//\\\_\//\\ /\\\\ /\\\__/\\\\\\\\\____\/\\\  \///__\//\\\______/\\\__\/\\\//////___\/\\\\\\\\\\_   " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "        _\/\\\________\//\\\__/\\\___\//\\\\\/\\\\\__\//\\/////_____\/\\\_________\///\\\__/\\\____\/\\\_________\///___//\\\_  " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "         _\/\\\_________\///\\\\\/_____\//\\\\//\\\____\//\\\\\\\\\__\/\\\___________\///\\\\\/_____\/\\\__________/\\\\\\\\\\_ " -BackgroundColor Black -ForegroundColor Blue
Write-Host (" " * $ScreenSize) "          _\///____________\/////________\///__\///______\/////////___\///______________\/////_______\///__________\//////////__" -BackgroundColor Black -ForegroundColor Blue

$ScreenSize = [math]::Round($ConsoleWidth-59)/2
Write-Host "`n"
Write-Host (" " * $ScreenSize) "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host (" " * $ScreenSize) "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
Write-Host (" " * $ScreenSize) "~~                 Welcome to PowerOps                   ~~"
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
        remove-variable -scope global listOfNSXClusterName
        
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