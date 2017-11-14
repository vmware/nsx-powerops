<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

NSX Power Operations

Copyright 2017 VMware, Inc.  All rights reserved				

The MIT license (the ìLicenseî) set forth below applies to all parts of the NSX Power Operations project.  You may not use this file except in compliance with the License.†

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>

# *-------------------------------------------* #
# ********************************************* #
#      VMware NSX PowerOps by @thisispuneet     #
# This script automate NSX-v day 2 Operations   #
# and help build the env networking documents   #
# ********************************************* #
# *-------------------------------------------* #

[CmdletBinding(DefaultParameterSetName = "Default")]
param (
    # Flag that we are running without UI, menu system and prompts are disabled. 
    [Parameter(Mandatory = $true, ParameterSetName = "NonInteractive")]
        [switch]$NonInteractive,
    # When running non-interactive, the connection profile to use.
    [Parameter(Mandatory = $true, ParameterSetName = "NonInteractive")]
        [string]$ConnectionProfile,
    # When running non-interactive, what task to execute.
    [Parameter(ParameterSetName = "NonInteractive")]
        [ValidateSet("All")]
        [string]$Task = "All",
    [Parameter(ParameterSetName = "NonInteractive")]
        [ValidateNotNullOrEmpty()]
        [string]$DocumentLocation = ("{0}\Report\{1:yyyy}-{1:MM}-{1:dd}_{1:HH}-{1:mm}" -f (split-path -parent $MyInvocation.MyCommand.Path), (get-date)),
    [Parameter()]    
        [switch]$ConnectDefaultProfile
)

$global:PowerOps = $MyInvocation.MyCommand.Path
$global:MyDirectory = split-path -parent $MyInvocation.MyCommand.Path
$version = "0.1"
$requiredModules = @("PowerNSX", "Pester", "Posh-SSH")

#Setup default menu colours.
$global:PSDefaultParameterValues["Show-MenuV2:HeaderColor"] = "DarkGreen"
$global:PSDefaultParameterValues["Show-MenuV2:SubheaderColor"] = "DarkGreen"
$global:PSDefaultParameterValues["Show-MenuV2:FooterColor"] = "DarkGreen"
$global:PSDefaultParameterValues["Show-MenuV2:FooterTextColor"] = "White"
$global:PSDefaultParameterValues["Disabled"] = $false

#Default usernames for vc/nsx
$default_viusername = "administrator@vsphere.local"
$default_nsxusername = "admin"

#ScheduledTask details.
$TaskTimeOfDay = "6am"
$TaskDayOfWeek = "Sunday"
$EventLogSource = "PowerOps"
$MaxReports = 20

#dot source our utils script.
. $myDirectory\util.ps1

#Setting up max window size and max buffer size
# NB 11/17 - Commented out - this is a seriously annoying 'feature'.  Why are
# we not allowing the user to choose their window size?
# invoke-expression -Command $mydirectory\maxWindowSize.ps1


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
$global:nsxManagerAuthorization = ''

function init {
    #Need to read in saved config prior to defining menus.
    Read-Config 
    loadDependancies

    #Create document location
    if (-not ( test-path $DocumentLocation )) { 
        $null = new-item -ItemType Directory -Path $DocumentLocation
    }

    $ExistingReports = Get-ChildItem (split-path -parent $DocumentLocation) -Directory
    while ( ( $ExistingReports | measure ).count -gt $maxReports ) {
        $oldest = $ExistingReports | sort-object -property LastWriteTime | select-object -first 1
        $oldest | remove-item -confirm:$false -Recurse -Force
        out-event -entrytype warning "Maximum number of reports reached.  Removed $oldest."
        $ExistingReports = Get-ChildItem (split-path -parent $DocumentLocation) -Directory
    }
}
function loadDependancies {
    if ( checkDependancies -ListAvailable $true ) {
        write-progress -Activity "Loading dependancies"        
        foreach ( $module in $requiredModules ) {
            write-progress -Activity "Loading dependancies" -Status $module            
            import-module $module -Global
        }
        write-progress -Activity "Loading dependancies" -Completed
    }
}   

function checkDependancies {
    param(
        [bool]$ListAvailable = $false
    )
    # returns bool based on required dependancies for script being installed.
    write-progress -Activity "Checking dependancies"
    if ( -not $script:DependanciesSatisfied) { 
        foreach ( $module in $requiredModules ) { 
            write-progress -Activity "Checking dependancies" -Status $module
            if ( -not ( Get-Module -ListAvailable:$ListAvailable -name $module )) { 
                return $false
            }
        }
        $script:DependanciesSatisfied = $true
    }
    write-progress -Activity "Checking dependancies" -Completed    
    return $true
}

function installDependencies {

    if ( -not (get-module -listavailable PowerShellGet )) { 
        write-error "Unable to perform dependancy installation, PowerShellGet is not installed.  Install from https://www.powershellgallery.com/packages/PowerShellGet/ and try again."
    }
    else { 
        Write-Progress -Activity "Installing module dependancies."
        
        foreach ( $module in $requiredModules )  {
            if ( -not (Get-Module -ListAvailable $Module )) { 
                Install-Module -Name $Module -Scope CurrentUser
                Write-Progress -Activity "Installing module dependancies." -CurrentOperation "Install module $module."
            }
        }
        Write-Progress -Activity "Installing module dependancies." -Completed        
    }

    #Force Load the deps now
    loadDependancies
}

#Connect to NSX Manager and vCenter. Save the credentials.
function connectProfile {

    param ( 
        $ProfileName
    )

    out-event "Connecting to NSX manager $($Config.Profiles["$ProfileName"].NSXServer) defined in connection profile $ProfileName"
    if ( -not ( $Config.Profiles["$ProfileName"] )) { 
        throw "Profile $Profile not defined."
    }
    if ( 
        $global:DefaultNsxConnection.Server -eq $Config.Profiles["$ProfileName"].NSXServer -and
        $global:DefaultNsxConnection.Credential.Username -eq $Config.Profiles["$ProfileName"].nsxusername -and
        $global:DefaultNsxConnection.ViConnection.IsConnected
    ) { 
        return "Using existing connection to $($global:DefaultNsxConnection.Server)"
    }
    
    try { 
        $vCenterCredentials = New-Object System.Management.Automation.PSCredential (
            $Config.Profiles["$ProfileName"].viusername, 
            ($Config.Profiles["$ProfileName"].vipassword | ConvertTo-SecureString)
        )
        
        $NSXManagerCredentials =  New-Object System.Management.Automation.PSCredential (
            $Config.Profiles["$ProfileName"].nsxusername, 
            ($Config.Profiles["$ProfileName"].nsxpassword | ConvertTo-SecureString)
        )

        Connect-NsxServer -NSXServer $Config.Profiles["$ProfileName"].NSXServer -Credential $NSXManagerCredentials -VICred $vCenterCredentials -ViWarningAction "Ignore" | out-null
    }
    catch {
        out-event -entrytype error "Error connecting to NSX using connection profile $ProfileName.  $_.  Please try again."
    }
}

function disconnectDefaultNsxConnection {

    if ( $DefaultNsxConnection ) { 
        if ( $DefaultNsxConnection.ViConnection.isConnected ) { 
            Disconnect-VIServer $DefaultNsxConnection.ViConnection -Confirm:$false
        }
        Remove-Variable -Scope Global -name DefaultNsxConnection
    }
}

#Get NSX Component info here
function getNSXComponents {

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
	$nsxManagerRole = Get-NsxManagerRole
	$nsxManagerBackup = Get-NsxManagerBackup
	$nsxManagerNetwork = Get-NsxManagerNetwork
	$nsxManagerSsoConfig = Get-NsxManagerSsoConfig
	$nsxManagerSyslogServer = Get-NsxManagerSyslogServer
	$nsxManagerTimeSettings = Get-NsxManagerTimeSettings
	$vCenterVersionInfo = $global:DefaultVIServer.ExtensionData.Content.About
	
    #Write-Host "Controller ID is:"$nsxControllers[0].id
    <# Example of the code to cherrypick dic elements to plot on documentation excel.
    $allNSXComponentExcelData = @{"NSX Controllers Info" = $nsxControllers, "objectTypeName", "revision", "clientHandle", "isUniversal", "universalRevision", "id", "ipAddress", "status", "upgradeStatus", "version", "upgradeAvailable", "virtualMachineInfo", "hostInfo", "resourcePoolInfo", "clusterInfo", "managedBy", "datastoreInfo", "controllerClusterStatus", "diskLatencyAlertDetected", "vmStatus"; 
    "NSX Manager Info" = $nsxManagerSummary, "ipv4Address", "dnsName", "hostName", "applianceName", "versionInfo", "uptime", "cpuInfoDto", "memInfoDto", "storageInfoDto", "currentSystemDate"; 
    "NSX Manager vCenter Configuration" = $nsxManagerVcenterConfig, "ipAddress", "userName", "certificateThumbprint", "assignRoleToUser", "vcInventoryLastUpdateTime", "Connected";
    "NSX Edge Info" = $nsxEdges, "id", "version", "status", "datacenterMoid", "datacenterName", "tenant", "name", "fqdn", "enableAesni", "enableFips", "vseLogLevel", "vnics", "appliances", "cliSettings", "features", "autoConfiguration", "type", "isUniversal", "hypervisorAssist", "queryDaemon", "edgeSummary";
    "NSX Logical Router Info" = $nsxLogicalRouters, "id", "version", "status", "datacenterMoid", "datacenterName", "tenant", "name", "fqdn", "enableAesni", "enableFips", "vseLogLevel", "appliances", "cliSettings", "features", "autoConfiguration", "type", "isUniversal", "mgmtInterface", "interfaces", "edgeAssistId", "lrouterUuid", "queryDaemon", "edgeSummary"}
    #>
    $allNSXComponentExcelDataMgr =@{"NSX Manager Info" = $nsxManagerSummary, "all"; "NSX Manager vCenter Configuration" = $nsxManagerVcenterConfig, "all"; "NSX Manager Role" = $nsxManagerRole, "all"; "NSX Manager Backup" = $nsxManagerBackup, "all"; "NSX Manager Network" = $nsxManagerNetwork, "all"; "NSX Manager SSO Config" = $nsxManagerSsoConfig, "all"; "NSX Manager Syslog Server" = $nsxManagerSyslogServer, "all"; "NSX Manager Time Settings" =  $nsxManagerTimeSettings, "all"; "vCenter Version" = $vCenterVersionInfo, "all"}
	
    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel
    $currentdocumentpath = "$documentlocation\NSX-Components.xlsx" 
    $nsxComponentExcelWorkBook = createNewExcel
    
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
    $nsxComponentExcelWorkBook.SaveAs($currentdocumentpath)
    $nsxComponentExcelWorkBook.Close()
    $global:newExcel.Quit()
    releaseObject -obj $nsxComponentExcelWorkBook
    releaseObject -obj $newExcel
}

#Get Host info here
function getHostInformation {
    #$vmHosts = get-vmhost
    getNSXPreparedHosts
    $vmHosts = $global:listOfNSXPrepHosts
    # out-event "Number of NSX Prepared vmHosts are: $($vmHosts.length)"

    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    $currentdocumentpath = "$documentlocation\ESXi-Hosts.xlsx" 
    $nsxHostExcelWorkBook = createNewExcel
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
        $tempvmknicLableList = @()
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
        get-cluster -Server $DefaultNSXConnection.ViConnection | % {
            if ($_.id -eq $myParentClusterID){
                get-cluster $_ | Get-NsxClusterStatus | % {
                    if($_.featureId -eq "com.vmware.vshield.vsm.vxlan" -And $_.installed -eq "true"){
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
                            $tempCountVMKnic = 0
                            if ($vdsInfo.VmknicCount -gt 1){
                                $myVmknicName | %{
                                    $sshCommandOutputDataVMKNIC.Add("VmknicName$tempCountVMKnic", $myVmknicName[$tempCountVMKnic])
                                    $sshCommandOutputDataVMKNIC.Add("IP$tempCountVMKnic", $vmknicInfo.IP[$tempCountVMKnic])
                                    $sshCommandOutputDataVMKNIC.Add("Netmask$tempCountVMKnic", $vmknicInfo.Netmask[$tempCountVMKnic])
                                    $tempvmknicLableList = $tempvmknicLableList + ("VmknicName$tempCountVMKnic", "IP$tempCountVMKnic", "Netmask$tempCountVMKnic")
                                    $tempCountVMKnic ++
                                }
                            }else{
                                $sshCommandOutputDataVMKNIC.Add("VmknicName", $myVmknicName)
                                $sshCommandOutputDataVMKNIC.Add("IP", $vmknicInfo.IP)
                                $sshCommandOutputDataVMKNIC.Add("Netmask", $vmknicInfo.Netmask)
                            }
                            $gotVXLAN = $true
                        }
                        catch{
                            $ErrorMessage = $_.Exception.Message
                            if ($ErrorMessage -eq "You cannot call a method on a null-valued expression."){
                                out-event -entrytype warning "No VxLAN data found on this Host $myHostName"
                                $gotVXLAN = $false
                            }
                            else{
                                out-event -entrytype error $ErrorMessage
                            }
                        }
                    }
                }
            }
        }
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
        $plotHostInformationExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxHostExcelWorkBook -workSheetName $hostWorkSheetName -listOfDataToPlot $allVmHostsExcelData
        ####writeToExcel -eachDataElementToPrint $sshCommandOutputDataLogicalSwitch -listOfAllAttributesToPrint $sshCommandOutputLable
        Remove-Item ./$nsxMgrCommandRouteTable
    }
    #invokeNSXCLICmd(" show logical-switch host host-31 verbose ")
    #$nsxHostExcelWorkBook.SaveAs()
    $nsxHostExcelWorkBook.SaveAs($currentdocumentpath)
    $nsxHostExcelWorkBook.Close()
    $global:newExcel.Quit()
    releaseObject -obj $nsxHostExcelWorkBook
    releaseObject -obj $newExcel
    
}

#Run visio tool
function runNSXVISIOTool {
    
    $capturePath = "$DocumentLocation\NSX-CaptureBundle.zip"
    $ObjectDiagram = "$MyDirectory\DiagramNSX\NsxObjectDiagram.ps1"
    $ObjectCapture = "$MyDirectory\DiagramNSX\NsxObjectCapture.ps1"
    $null = &$ObjectCapture -ExportFile $capturePath
    &$ObjectDiagram -NoVms -CaptureBundle $capturePath -outputDir $DocumentLocation   
}

#Get Routing info here
function getRoutingInformation {
    $tempTXTFileNamesList = @()
    $userSelection = "Get Routing Information"
    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    
    $currentdocumentpath = "$documentlocation\NSX-Routing.xlsx"
    $nsxRoutingExcelWorkBook = createNewExcel

    Write-Progress -Activity "Documenting Routing Information"
    
    # Getting Edge Routing Info here
    $numberOfEdges = Get-NsxEdge
    foreach ($eachEdge in $numberOfEdges){
        Write-Progress -Activity "Documenting Routing Information" -CurrentOperation "Processing Edge $($eachedge.name)"
    
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
        Write-Progress -Activity "Documenting Routing Information" -CurrentOperation "Processing Edge $($eachedge.name)" -Completed
    }

    # Getting DLR routing Info here
    $numberOfDLRs = Get-NsxLogicalRouter
    foreach($eachDLR in $numberOfDLRs){

        Write-Progress -Activity "Documenting Routing Information" -CurrentOperation "Processing DLR $($eachdlr.name)"

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

        #Run SSH Command to get Route Info from Master Controller
        [string]$routeTableFromControllerCommand = "show logical-router controller master dlr $dlrID route"
        $txtFileName = $routeTableFromControllerCommand
        invokeNSXCLICmd -commandToInvoke $routeTableFromControllerCommand -fileName $txtFileName
        #Parse SSH Output here
        $findControllerRouteTableElements= @("Destination")
        $sshCommandOutputControllerRouteTable = parseSSHOutput -fileToParse $txtFileName -findElements $findControllerRouteTableElements -direction "Column"
        #Add parsed output to the allDLRRoutingExcelData dictionary
        $finalControllerRouteTable = $sshCommandOutputControllerRouteTable, $txtFileName
        $allDLRRoutingExcelData.Add("H) NSX Controller Route Table", $finalControllerRouteTable)
        $tempTXTFileNamesList += $txtFileName

        #Make sure workbook name wont exceed 31 letters
        if ($dlrID.length -gt 14){ $nsxDLRWorkSheetName = "NSX DLR Routing-$($dlrID.substring(0,13))" }else{$nsxDLRWorkSheetName = "NSX DLR Routing-$dlrID"}
        #Plot the NSX Route final
        $plotNSXRoutingExcelWB = plotDynamicExcelWorkBook -myOpenExcelWBReturn $nsxRoutingExcelWorkBook -workSheetName $nsxDLRWorkSheetName -listOfDataToPlot $allDLRRoutingExcelData
        Write-Progress -Activity "Documenting Routing Information" -CurrentOperation "Processing DLR $($eachdlr.name)" -Completed
    }
    #$nsxRoutingExcelWorkBook.SaveAs()
    $nsxRoutingExcelWorkBook.SaveAs($currentdocumentpath)
    $nsxRoutingExcelWorkBook.Close()
    $global:newExcel.Quit()
    releaseObject -obj $nsxRoutingExcelWorkBook
    releaseObject -obj $newExcel

    $tempTXTFileNamesList | %{ Remove-Item ./$_}

    Write-Progress -Activity "Documenting Routing Information" -Completed
    
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
function runDFW2Excel {
    
    $Dfw2Excel = "$myDirectory\PowerNSX-DFW2Excel\DFW2Excel.ps1"
    $DocumentPath = "$DocumentLocation\DfwToExcel.xlsx"    
    &$Dfw2Excel -EnableIpDetection -StartMinimised -DocumentPath $DocumentPath
    
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
    write-progress -activity "Executing NSX CLI Command: $commandToInvoke"
    <#
    if ($nsxManagerAuthorization -eq ''){
            $nsxManagerUser = Read-Host -Prompt " Enter NSX Manager $nsxManagerHost User"
            $nsxManagerPasswd = Read-Host -Prompt " Enter NSX Manager Password"
            $nsxManagerAuthorization = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($nsxManagerUser + ":" + $nsxManagerPasswd))
    }
    
    $nsxMgrCliApiURL = $global:nsxManagerHost+"/api/1.0/nsx/cli?action=execute"
    if ($nsxMgrCliApiURL.StartsWith("http://")){$nsxMgrCliApiURL -replace "http://", "https://"}
    elseif($nsxMgrCliApiURL.StartsWith("https://")){}
    else{$nsxMgrCliApiURL = "https://"+$nsxMgrCliApiURL}

    $curlHead = @{"Accept"="text/plain"; "Content-type"="Application/xml"; "Authorization"="Basic $global:nsxManagerAuthorization"}
    #>
    $xmlBody = "<nsxcli>
     <command> $commandToInvoke </command>
     </nsxcli>"

    ####$nsxCLIResponceweb = Invoke-WebRequest -UseBasicParsing -uri $nsxMgrCliApiURL -Body $xmlBody -Headers $curlHead -Method Post
    $AdditionalHeaders = @{"Accept"="text/plain"; "Content-type"="Application/xml"}
    $nsxCLIResponceweb = Invoke-NsxWebRequest -URI "/api/1.0/nsx/cli?action=execute" -method post -extraheader $AdditionalHeaders -body $xmlBody
    $nsxCLIResponceweb.content > $fileName
    write-progress -activity "Executing NSX CLI Command: $commandToInvoke" -Completed
    
}

function startSSHSession($serverToConnectTo, $credentialsToUse){
    #$myNSXManagerCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $mySecurePass
    $newSSHSession = New-Sshsession -computername $serverToConnectTo -Credential $credentialsToUse
    return $newSSHSession
}

function getNSXPreparedHosts() {
    $allEnvClusters = get-cluster -Server $DefaultNSXConnection.ViConnection | %{
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

# NB 11/17 - As per above - why are we not letting the user choose the size of
# their windows!!!

# function clx {
#     [System.Console]::SetWindowPosition(0,[System.Console]::CursorTop)
# }


# ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- HealthCheck Functions start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- # 


function runNSXTest ($testModule){
    $startTime = Get-Date
    $outputFileName = $testModule +"-"+ $startTime.ToString("yyyy-MM-dd-hh-mm") + ".xml"
    
    #Todo: Change connection handling to suit connection profiles.
    $global:NsxConnection = $DefaultNSXConnection

    $result = Invoke-Pester -Script @{ Path = './HealthCheck/'+$testModule+'.Tests.ps1'; Parameters = @{ testModule = $testModule} } -OutputFile ./HealthCheck/testResult-$outputFileName -OutputFormat NUnitXML 

    # NB 11/17 Removing redundant prompt (we will manage old files separately, so write out by default.)
    # Write-Host "`nSave the result in an XML file? Y or N [default Y]: " -ForegroundColor Darkyellow -NoNewline
    # $saveHCResult = Read-Host
    # if ($saveHCResult -eq 'n'-or $saveHCResult -eq "N") {Remove-Item ./HealthCheck/testResult-$outputFileName}else{
    #     Write-Host "Saved XML file at:" ./HealthCheck/testResult-$outputFileName -ForegroundColor Green
    # }
}


# ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- Excel Functions start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- # 

#Create empty excel sheet here 

function createNewExcel{ 
    # param (
    #     $Path
    # )
    Write-Progress -Activity "Creating Excel Document" -Status "Create new Excel document"    
    #$xlFixedFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlWorkbookDefault
    $global:newExcel = New-Object -Com Excel.Application
    $global:newExcel.visible = $false
    $global:newExcel.DisplayAlerts = $false
    #$Excel.Name = "Test Excel Name"
    $wb = $global:newExcel.Workbooks.Add()
    #$sheet = $wb.ActiveSheet
    
    # Save the excel with provided Name
    #$newExcel.ActiveWorkbook.SaveAs($newExcelNameWithDate, $xlFixedFormat)
    # $global:newExcel.ActiveWorkbook.SaveAs($Path)
    Write-Progress -Activity "Creating Excel Document" -Status "Create new Excel document" -Completed    
    return $wb
} # End of function createNewExcel

# Plot excel sheet here one workBook at a time ..pass already created Excel, Worksheet Name, List of values need to be plotted.
# Call this function seperatelly for multiple Work Sheets.
function plotDynamicExcelWorkBook($myOpenExcelWBReturn, $workSheetName, $listOfDataToPlot){
    $listOfAllAttributes =@()
    Write-Progress -Activity "Populate Excel Document" -Status "Populating worksheet $workSheetName" -CurrentOperation "Creating worksheet in document"
    
    $global:myRow =1
    $global:myColumn=1
    $sheet = $myOpenExcelWBReturn.WorkSheets.Add()
    $sheet.Name = $workSheetName
    $sheet.Cells.Item(1,1) = $workSheetName
    
    #Use this loop for nonsorted dic data: foreach($eachDataSetKey in $listOfDataToPlot.Keys){
    foreach($eachsortedDataSetKey in $listOfDataToPlot.GetEnumerator() | Sort Name){
        $eachDataSetKey = $eachsortedDataSetKey.name
        Write-Progress -Activity "Populate Excel Document" -Status "Populating worksheet $workSheetName" -CurrentOperation "Writing data for $eachdatasetKey"
    
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
            Write-Progress -Activity "Populate Excel Document" -Status "Populating worksheet $workSheetName" -CurrentOperation "Processing element $($eachdataElement.name)"
        
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

    Write-Progress -Activity "Populating Excel Document" -Completed

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




Switch ( $PSCmdlet.ParameterSetName )  {

    "NonInteractive" {
        # Running non-interactively.
        $global:PSDefaultParameterValues["Write-EventLog:LogName"] = "Application"
        $global:PSDefaultParameterValues["Write-EventLog:Source"] = $EventLogSource
        $global:PSDefaultParameterValues["Write-EventLog:EntryType"] = "Information"
        $global:PSDefaultParameterValues["Write-EventLog:Category"] = 0
        $global:PSDefaultParameterValues["Write-EventLog:EventId"] = 1000
        $global:PSDefaultParameterValues["Out-Event:WriteToEventLog"] = $true
        
        init

        trap { 
            #Default error handler that dumps an error event log and bails.
            $LogMessage = "An unhandled exception occured in PowerOps.  $_`n"
            $LogMessage += "ScriptStackTrace: $($_.scriptstacktrace)"
            Write-EventLog -EntryType Error -EventId 1001 -Message $LogMessage
            break
        }
        Out-Event -entrytype information "Invoked with profile $ConnectionProfile and document location $documentlocation"
        
        if ( ($Config.Profiles[$ConnectionProfile]) -and (checkDependancies) ) { 
            connectProfile -ProfileName $ConnectionProfile
        }
        Out-Event -entrytype information "Executing NSX component documentation task"
        getNSXComponents
        Out-Event -entrytype information "Executing host information documentation task"
        getHostInformation
        Out-Event -entrytype information "Executing Visio diagramming task"
        runNSXVISIOTool
        Out-Event -entrytype information "Executing routing information task"
        getRoutingInformation
        Out-Event -entrytype information "Executing DFW2Excel documentation task"
        runDFW2Excel
        Out-Event -entrytype information "Invocation complete."
    }
    
    "Default" {
        
        init

        # Running interactively - Setup the menu system.
        # Header/Footer.
        $MainHeader = @"

__/\\\\\\\\\\\__________________________________________________________________/\\\\\________________________________        
 _\/\\\///////\\\______________________________________________________________/\\\///\\\______________________________
  _\/\\\_____\/\\\____________________________________________________________/\\\/__\///\\\____/\\\\\\\\\______________
   _\/\\\\\\\\\\\/___/\\\\\_____/\\ __ /\\ _ /\\____/\\\\\\\\\__/\\/\\\\\\___/\\\______\//\\\__/\\\/___/\\\__/\\\\\\\\\\_
    _\/\\\///////___/\\\///\\\__\/\\\  /\\\\ /\\\__/\\\///\\//__\/\\\////\\\_\/\\\_______\/\\\_\/\\\___\\\\__\/\\\/___//__
     _\/\\\_________/\\\__\//\\\_\//\\ /\\\\ /\\\__/\\\\\\\\\____\/\\\  \///__\//\\\______/\\\__\/\\\//////___\/\\\\\\\\\\_
      _\/\\\________\//\\\__/\\\___\//\\\\\/\\\\\__\//\\/////_____\/\\\_________\///\\\__/\\\____\/\\\_________\///___//\\\_
       _\/\\\_________\///\\\\\/_____\//\\\\//\\\____\//\\\\\\\\\__\/\\\___________\///\\\\\/_____\/\\\__________/\\\\\\\\\\_
        _\///____________\/////________\///__\///______\/////////___\///______________\/////_______\///__________\//////////__

"@

        $Subheader = "NSX PowerOps v$version.`nA project by the NSBU SA team.`n"

        # Footer is a script block that is executed each time the menu is rendered.  We can use it to display status.
        $Footer = { 
@"
Default Connection Profile: $($Config.DefaultProfile)
Connected : $($DefaultNsxConnection -and $DefaultNsxConnection.ViConnection.IsConnected)
Output Directory: $DocumentLocation
"@
        }

        # Dependancies menu definition.
        $DependanciesMenu = @{ 
            "Script" = { installDependencies }
            "Interactive" = "True"
            "HelpText" = "Installs the required dependancies for PowerOps.  The following modules will be installed: $($requiredmodules -join ', ')"
            "Name" = "Install NSX PowerOps Dependancies"
            "Status" = { if ( checkDependancies -ListAvailable $true) { "Disabled" } else { "MenuEnabled" } }
            "StatusText" = { if ( checkDependancies -ListAvailable $true) { "Installed" } else { "Not Installed" } }
            "Footer" = $footer
            "MainHeader" = $MainHeader
            "Subheader" = $Subheader
        }

        # Doc menu definition.
        $DocumentationMenu = @{    
            "Script" = { Show-MenuV2 -menu $DocumentationMenu }
            "HelpText" = "Displays a menu of PowerOps documentation tools."
            "Name" = "PowerOps Documentation Tools"
            "Status" = { if ((checkDependancies -ListAvailable $true) -and ($DefaultNSXConnection)) { "MenuEnabled" } else { "Disabled" } }
            "Footer" = $footer
            "MainHeader" = $MainHeader
            "Subheader" = $Subheader
            "Items" = @( 
                @{ 
                    "Name" = "Document All NSX Components"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = { getNSXComponents }
                },
                @{ 
                    "Name" = "Document ESXi Host(s) Info"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  getHostInformation }
                },
                @{ 
                    "Name" = "Document NSX Environment via Visio Diagramming Tool"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXVISIOTool }
                },
                @{ 
                    "Name" = "Document Routing information"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  getRoutingInformation }
                },
                @{ 
                    "Name" = "Document NSX DFW info to Excel via DFW2Excel"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runDFW2Excel }
                }
            )
        }

        # Healthcheck menu definition.
        $HealthCheckMenu = @{    
            "Script" = { Show-MenuV2 -menu $HealthCheckMenu }
            "HelpText" = "Displays a menu of PowerOps Healthchecks."
            "Name" = "PowerOps HealthChecks"
            "Status" = { if ((checkDependancies -ListAvailable $true) -and ($DefaultNSXConnection)) { "MenuEnabled" } else { "Disabled" } }
            "Footer" = $footer
            "MainHeader" = $MainHeader
            "Subheader" = $Subheader
            "Items" = @( 
                @{ 
                    "Name" = "NSX Connectivity Test"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXTest -testModule "testNSXConnections" }
                },
                @{ 
                    "Name" = "NSX Manager Test"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXTest -testModule "testNSXManager" }
                },
                @{ 
                    "Name" = "NSX Controllers Appliance Test"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {   runNSXTest -testModule "testNSXControllers" }
                },
                @{ 
                    "Name" = "NSX Logical Switch Test"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXTest -testModule "testNSXLogicalSwitch" }
                },
                @{ 
                    "Name" = "NSX Distributed Firewall Heap Test"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXTest -testModule "testNSXDistributedFirewallHeap" }
                },
                @{ 
                    "Name" = "Check DLR Instance"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXTest -testModule "testNSXVDR" }
                },
                @{ 
                    "Name" = "Check VIB Version"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXTest -testModule "testNSXVIBVersion" }
                },
                @{ 
                    "Name" = "Check vTEP to vTEP connectivity"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXTest -testModule "testNSXMTUUnderlay" }
                }
            )
        }

        # Authentication profile menu definition.
        $AuthConfigMenu = @{
            
            "Name" = "Configure Connection Profiles"
            "Status" = { 
                if ( -not (checkDependancies -ListAvailable $true) ) {
                    "Disabled"
                } 
                elseif ( -not ($Config.DefaultProfile )) { 
                    "MenuEnabled"
                }
                else {
                    "SelectedValid"
                }
            }
            "StatusText" = { 
                if ( -not (checkDependancies -ListAvailable $true) ) {
                    "DISABLED"
                } 
                elseif ( -not ($Config.DefaultProfile )) { 
                    "SELECT"
                }
                else {
                    "Default: $($Config.DefaultProfile)"
                }
            }
            "HelpText" = "Configures connection profiles for NSX and vCenter."
            "Script" = { Show-Menuv2 -menu $AuthConfigMenu }
            "MainHeader" = $MainHeader
            "Subheader" = $Subheader
            "Footer" = $footer
            "Items" = @(
                @{
                    "Name" = "Create Connection Profile"
                    "Status" = { "MenuEnabled" }
                    "HelpText" = "Creates a new connection profile that is saved to disk and can be used for operations that require access to NSX/VC."
                    "Script" = { New-ConnectionProfile; if ( $Config.DefaultProfile -and (-not ($DefaultNSXConnection))) { connectProfile -ProfileName $Config.DefaultProfile } }
                },
                @{
                    "Name" = "Delete Connection Profile"
                    "Status" = { If ( $Config.Profiles -and ($Config.Profiles.Count -gt 0) ) { "MenuEnabled" } else { "Disabled" } }
                    "StatusText" = { If ( $Config.Profiles -and ($Config.Profiles.Count -gt 0)) { "ENABLED" } else { "No Connection Profiles Defined" } }
                    "HelpText" = "Deletes an existing connection profile."
                    "Script" = { Remove-ConnectionProfile; if ((-not ($Config.DefaultProfile)) -and ($DefaultNSXConnection)) { disconnectDefaultNsxConnection } }
                },
                @{
                    "Name" = "Select Default Connection Profile"
                    "Status" = { 
                        If ( $Config.DefaultProfile ) {
                            "SelectedValid" 
                        } 
                        elseif ( $Config.Profiles -and ($Config.Profiles.Count -gt 0) ) {
                            "MenuValid"
                        }
                        else {
                            "Disabled" 
                        }
                    }
                    "StatusText" = {
                        If ( $Config.DefaultProfile ) {
                            $Config.DefaultProfile 
                        } 
                        elseif ( $Config.Profiles -and ($Config.Profiles.Count -gt 0) ) {
                            "SELECT"
                        }
                        else {
                            "No Connection Profiles Defined" 
                        }
                    }
                    "HelpText" = "Selects the connection profile used for interactive operations that require access to NSX/VC."
                    "Script" = { Set-DefaultConnectionProfile }
                }       
            )
        }

        # ScheduledTask menu definition.
        $ScheduledTasksMenu = @{ 
            "Script" = { Show-MenuV2 -menu $ScheduledTasksMenu }
            "Name" = "Configure Scheduled Tasks"
            "HelpText" = "Contains configuration to automate periodic Configuration Capture."
            "Status" = { 
                if ((checkDependancies -ListAvailable $true) -and ( @($Config.Profiles).count -gt 0 )) { 
                    "MenuEnabled" 
                } 
                else { 
                    "Disabled"
                }
            }
            "Footer" = $footer
            "MainHeader" = $MainHeader
            "Subheader" = $Subheader
            "Items" = @( 
                @{
                    "Name" = "Enable/Disable PowerOps Scheduled Documentation Task"
                    "HelpText" = "Enables a scheduled task for periodic documentation capture for any configured connection profile."
                    "Status" = { "MenuEnabled" }
                    "Script" = { Get-EnableScheduledTaskMenu }
                }
            )
        }

        # Root menu definition.
        $rootmenu = @{ 
            "Name" = "NSX PowerOps Main Menu"
            "Status" = { "MenuValid" }
            "Footer" = $footer
            "MainHeader" = $MainHeader
            "Subheader" = $Subheader
            "Items" = @( 
                $DependanciesMenu,
                $AuthConfigMenu,
                $ScheduledTasksMenu,
                $DocumentationMenu,
                $HealthcheckMenu
            )
        }

        # Display the root menu.  Menu system blocks until exited.
        
        if ( $Config.DefaultProfile -and (checkDependancies) ) { 
            if ( -not $PSBoundParameters.ContainsKey("ConnectDefaultProfile")) { 
                do {

                    # User did not specify switch explicitly - prompt them
                    $ans = read-host "Connect to NSX/VC defined in default profile $($Config.DefaultProfile)? (Y/N)"
                    if ($ans -match "^[yY]$")  {
                        $ConnectDefaultProfile = $true
                    }
                } while ( $ans -notmatch "^[yYnN]$")
            }
            
            if ( $ConnectDefaultProfile ) {
                connectProfile -ProfileName $Config.DefaultProfile
            }
        }
        show-menuv2 -menu $rootmenu 
    }
}

# User has exited gracefully, disconnect from NSX/VC
disconnectDefaultNsxConnection