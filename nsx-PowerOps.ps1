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
$version = "2.0"
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

$fontColorGood = 4
$fontColorBad = 3
$fontColorUnknownState = 46

$horizontalAlignmentCenter = -4108

$verticalAlignmentTop = -4160

$borderLineStyle = 1
$borderWeight = 2

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
                write-progress -Activity "Checking dependancies" -Status $module -Completed        
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
    
    $currentdocumentpath = "$documentlocation\NSX-Components-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xlsx" -f (get-date)
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
    $currentdocumentpath = "$documentlocation\ESXi-Hosts-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xlsx" -f (get-date)
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
    $capturePath = "$documentlocation\NSX-CaptureBundle-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.zip" -f (get-date)
    $ObjectDiagram = "$MyDirectory\DiagramNSX\NsxObjectDiagram.ps1"
    $ObjectCapture = "$MyDirectory\DiagramNSX\NsxObjectCapture.ps1"
    $null = &$ObjectCapture -ExportFile $capturePath
    if ( [type]::GetTypeFromProgID("Visio.Application") ) { 
        &$ObjectDiagram -NoVms -CaptureBundle $capturePath -outputDir $DocumentLocation
    }
    else {
        out-event -entrytype warning "Visio not installed.  Visio diagram generation is disabled (capture bundle is still created in report directory)"
    }
}

#Get Routing info here
function getRoutingInformation {
    $tempTXTFileNamesList = @()
    $userSelection = "Get Routing Information"
    #### Call Build Excel function here ..pass local variable of NSX Components to plot the info on excel 
    
    $currentdocumentpath = "$documentlocation\NSX-Routing-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xlsx" -f (get-date)
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
    $DocumentPath = "$documentlocation\DfwToExcel-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xlsx" -f (get-date)
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
    $newSSHSession = New-Sshsession -computername $serverToConnectTo -Credential $credentialsToUse -AcceptKey
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

function runLB2Excel($sectionNumber){

    $DocumentPath = "$documentlocation\LBToExcel-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xlsx" -f (get-date)

    $nsxEdges = Get-NsxEdge | ? {$_.features.loadBalancer.enabled -eq "true"}
    $allNSXComponentExcelDataEdge =@{}

    #Some variables we will use to populate the summary page
    $counterVIPs = 0
    $counterVIPsOpen = 0
    $counterVIPsClosed = 0
    $counterPools = 0
    $counterPoolsUp = 0
    $counterPoolsDown = 0
    $counterMembers = 0
    $counterMembersUp = 0
    $counterMembersDown = 0
    $counterMembersUnknown = 0

    $summaryEdgeStats = [ordered]@{}

    # Create the new excel workbook that we will be working on
    $nsxLBExcelWorkBook = createNewExcel

    # Creating seperate worksheet for each edge lb
    foreach ($edge in $nsxEdges) {

        Write-Progress -Activity "Procesing $($edge.name)"

        $lbconf = $edge | Get-NsxLoadBalancer
        $lbStats = $lbconf | Get-NsxLoadBalancerStats

        # Create a hash table to store summary information about this edge
        $summary = @{}
        $summary.Add("id", $edge.id)

        # Store the VIP counters
        $edgeVips = ($lbconf.virtualserver | measure).count
        $edgeVIPsOpen = ($lbstats.virtualserver | ? {$_.status -eq "OPEN"} | measure).count
        $edgeVIPsClosed = ($lbstats.virtualserver | ? {$_.status -ne "OPEN"} | measure).count

        $counterVIPs += $edgeVips
        $counterVIPsOpen += $edgeVIPsOpen
        $counterVIPsClosed += $edgeVIPsClosed

        $summary.Add("vips", $edgeVips)
        $summary.Add("vipsOpen", $edgeVIPsOpen)
        $summary.Add("vipsClosed", $edgeVIPsClosed)

        # Store the Pool counters
        $edgePools = ($lbconf.pool | measure).count
        $edgePoolsUp = ($lbstats.pool | ? {$_.status -eq "UP"} | measure).count
        $edgePoolsDown = ($lbstats.pool | ? {$_.status -ne "Up"} | measure).count

        $counterPools += $edgePools
        $counterPoolsUp += $edgePoolsUp
        $counterPoolsDown += $edgePoolsDown

        $summary.Add("pools", $edgePools)
        $summary.Add("poolsUp", $edgePoolsUp)
        $summary.Add("poolsDown", $edgePoolsDown)
        $summary.Add("poolMembers", $edgePoolMembers)

        # Store the member details
        $edgePoolMembers = ($lbstats.pool.member | measure).count
        $edgePoolMembersUp = ($lbstats.pool.member | ? { $_.status -eq "UP"} | measure).count
        $edgePoolMembersDown = ($lbstats.pool.member | ? { $_.status -eq "DOWN"} | measure).count
        $edgePoolMembersUnknown = ($lbstats.pool.member | ? { ($_.status -ne "DOWN") -and ($_.status -ne "UP")} | measure).count

        $counterMembers += $edgePoolMembers
        $counterMembersUp += $edgePoolMembersUp
        $counterMembersDown += $edgePoolMembersDown
        $counterMembersUnknown += $edgePoolMembersUnknown

        $summary.Add("members", $edgePoolMembers)
        $summary.Add("membersUp", $edgePoolMembersUp)
        $summary.Add("membersDown", $edgePoolMembersDown)
        $summary.Add("membersUnknown", $edgePoolMembersUnknown)

        # Add the summary information for this edge to the main hash table
        $summaryEdgeStats.Add($edge.name,$summary)

        # Add a new worksheet (after the last worksheet) for the Edge with load
        # balancer enabled.
        $wsStats = $nsxLBExcelWorkBook.WorkSheets.Add([System.Reflection.Missing]::Value,$nsxLBExcelWorkBook.Worksheets.Item($nsxLBExcelWorkBook.Worksheets.count))
        $wsStats.Name = $edge.name

        if (($edgePoolsDown -ge 1) -or ($edgePoolMembersDown -ge 1)) {
            $wsStats.tab.ColorIndex = $fontColorBad
        } else {
            $wsStats.tab.ColorIndex = $fontColorGood
        }

        $summaryRowTitle = 2
        $summaryRowHeader = $summaryRowTitle + 1
        $summaryRowDetail = $summaryRowHeader + 1
        $summaryColTitleVips = 2
        $summaryColTitlePools = $summaryColTitleVips + 4
        $summaryColTitleMembers = $summaryColTitlePools + 4

        $wsStats.Cells.Item($summaryRowTitle,$summaryColTitleVips)  = "VIPs"
        $wsStats.Cells.Item($summaryRowTitle,$summaryColTitlePools)  = "Pools"
        $wsStats.Cells.Item($summaryRowTitle,$summaryColTitleMembers)  = "Members"

        $wsStats.Cells.Item($summaryRowHeader,$summaryColTitleVips)  = "Total"
        $wsStats.Cells.Item($summaryRowHeader,($summaryColTitleVips + 1))  = "OPEN"
        $wsStats.Cells.Item($summaryRowHeader,($summaryColTitleVips + 2))  = "CLOSED"

        $wsStats.Cells.Item($summaryRowDetail,$summaryColTitleVips)  = $edgeVips
        $wsStats.Cells.Item($summaryRowDetail,($summaryColTitleVips + 1))  = $edgeVIPsOpen
        $wsStats.Cells.Item($summaryRowDetail,($summaryColTitleVips + 2))  = $edgeVIPsClosed

        $wsStats.Cells.Item($summaryRowHeader,$summaryColTitlePools)  = "Total"
        $wsStats.Cells.Item($summaryRowHeader,($summaryColTitlePools + 1))  = "UP"
        $wsStats.Cells.Item($summaryRowHeader,($summaryColTitlePools + 2))  = "DOWN"

        $wsStats.Cells.Item($summaryRowDetail,$summaryColTitlePools)  = $edgePools
        $wsStats.Cells.Item($summaryRowDetail,($summaryColTitlePools + 1))  = $edgePoolsUp
        $wsStats.Cells.Item($summaryRowDetail,($summaryColTitlePools + 2))  = $edgePoolsDown

        $wsStats.Cells.Item($summaryRowHeader,$summaryColTitleMembers)  = "Total"
        $wsStats.Cells.Item($summaryRowHeader,($summaryColTitleMembers + 1))  = "UP"
        $wsStats.Cells.Item($summaryRowHeader,($summaryColTitleMembers + 2))  = "DOWN"
        $wsStats.Cells.Item($summaryRowHeader,($summaryColTitleMembers + 3))  = "UNKNOWN"

        $wsStats.Cells.Item($summaryRowDetail,$summaryColTitleMembers)  = $edgePoolMembers
        $wsStats.Cells.Item($summaryRowDetail,($summaryColTitleMembers + 1))  = $edgePoolMembersUp
        $wsStats.Cells.Item($summaryRowDetail,($summaryColTitleMembers + 2))  = $edgePoolMembersDown
        $wsStats.Cells.Item($summaryRowDetail,($summaryColTitleMembers + 3))  = $edgePoolMembersUnknown

        # Format VIP Summary table
        $vipSummaryHeaderRange = $wsStats.range($wsStats.cells.item($summaryRowTitle,$summaryColTitleVips),$wsStats.cells.item($summaryRowTitle,($summaryColTitleVips +2)))
        $vipSummaryHeaderRange.Font.Size = $titleFontSize
        $vipSummaryHeaderRange.Font.Bold = $titleFontBold
        $vipSummaryHeaderRange.Font.ColorIndex = $titleFontColorIndex
        $vipSummaryHeaderRange.Font.Name = $titleFontName
        $vipSummaryHeaderRange.Interior.ColorIndex = $subSetInteriorColor
        $vipSummaryHeaderRange.merge() | Out-Null
        $vipSummaryHeaderRange.HorizontalAlignment = $horizontalAlignmentCenter

        $vipSummaryRange = $wsStats.range($wsStats.cells.item($summaryRowHeader,$summaryColTitleVips),$wsStats.cells.item($summaryRowDetail,($summaryColTitleVips +2)))
        $vipSummaryRange.Borders.linestyle = $borderLineStyle
        $vipSummaryRange.Borders.Weight = $borderWeight
        $vipSummaryRange.HorizontalAlignment = $horizontalAlignmentCenter

        # Format Pool Summary table
        $poolSummaryHeaderRange = $wsStats.range($wsStats.cells.item($summaryRowTitle,$summaryColTitlePools),$wsStats.cells.item($summaryRowTitle,($summaryColTitlePools +2)))
        $poolSummaryHeaderRange.Font.Size = $titleFontSize
        $poolSummaryHeaderRange.Font.Bold = $titleFontBold
        $poolSummaryHeaderRange.Font.ColorIndex = $titleFontColorIndex
        $poolSummaryHeaderRange.Font.Name = $titleFontName
        $poolSummaryHeaderRange.Interior.ColorIndex = $subSetInteriorColor
        $poolSummaryHeaderRange.merge() | Out-Null
        $poolSummaryHeaderRange.HorizontalAlignment = $horizontalAlignmentCenter

        $poolSummaryRange = $wsStats.range($wsStats.cells.item($summaryRowHeader,$summaryColTitlePools),$wsStats.cells.item($summaryRowDetail,($summaryColTitlePools +2)))
        $poolSummaryRange.Borders.linestyle = $borderLineStyle
        $poolSummaryRange.Borders.Weight = $borderWeight
        $poolSummaryRange.HorizontalAlignment = $horizontalAlignmentCenter

        # Format Member Summary table
        $memberSummaryHeaderRange = $wsStats.range($wsStats.cells.item($summaryRowTitle,$summaryColTitleMembers),$wsStats.cells.item($summaryRowTitle,($summaryColTitleMembers +3)))
        $memberSummaryHeaderRange.Font.Size = $titleFontSize
        $memberSummaryHeaderRange.Font.Bold = $titleFontBold
        $memberSummaryHeaderRange.Font.ColorIndex = $titleFontColorIndex
        $memberSummaryHeaderRange.Font.Name = $titleFontName
        $memberSummaryHeaderRange.Interior.ColorIndex = $subSetInteriorColor
        $memberSummaryHeaderRange.merge() | Out-Null
        $memberSummaryHeaderRange.HorizontalAlignment = $horizontalAlignmentCenter

        $poolSummaryRange = $wsStats.range($wsStats.cells.item($summaryRowHeader,$summaryColTitleMembers),$wsStats.cells.item($summaryRowDetail,($summaryColTitleMembers +3)))
        $poolSummaryRange.Borders.linestyle = $borderLineStyle
        $poolSummaryRange.Borders.Weight = $borderWeight
        $poolSummaryRange.HorizontalAlignment = $horizontalAlignmentCenter

        # Setup lb details row assignments
        $lbDetailsRowTitle = 6
        $lbDetailsRowHeader = 7

        # Setup lb details column assignments
        $lbdetailsColEdgeId = 1
        $lbdetailsColEdgeName = 2
        $lbdetailsColVIPName = 3
        $lbdetailsColVIPAddress = 4
        $lbdetailsColVIPStatus = 5
        $lbdetailsColSI = 6
        $lbdetailsColEngine = 7
        $lbdetailsColAppRule = 8
        $lbdetailsColProtocol = 9
        $lbdetailsColPort = 10
        $lbdetailsColAppProfile = 11
        $lbdetailsColPoolName = 12
        $lbdetailsColPoolStatus = 13
        $lbdetailsColPoolMember = 14

        # Format lb details title
        $wsStats.Cells.Item($lbDetailsRowTitle,$lbdetailsColEdgeId) = "Edge: $($edge.name) - LB VIP Information"
        $wsStats.Cells.Item($lbDetailsRowTitle,$lbdetailsColEdgeId).Font.Size = $titleFontSize
        $wsStats.Cells.Item($lbDetailsRowTitle,$lbdetailsColEdgeId).Font.Bold = $titleFontBold
        $wsStats.Cells.Item($lbDetailsRowTitle,$lbdetailsColEdgeId).Font.ColorIndex = $titleFontColorIndex
        $wsStats.Cells.Item($lbDetailsRowTitle,$lbdetailsColEdgeId).Font.Name = $titleFontName
        $wsStats.Cells.Item($lbDetailsRowTitle,$lbdetailsColEdgeId).Interior.ColorIndex = $titleInteriorColor 
        $range1 = $wsStats.Range($wsStats.cells.item($lbDetailsRowTitle,$lbdetailsColEdgeId),$wsStats.cells.item($lbDetailsRowTitle,$lbdetailsColPoolMember) )
        $range1.merge() | Out-Null

        # Setup lb details header columns
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColEdgeId) = "Edge ID"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColEdgeName) = "Edge Name"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColVIPName) = "VIP Name"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColVIPAddress) = "VIP Address"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColVIPStatus) = "VIP Status"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColSI) = "Service Insertion"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColEngine) = "L4 Engine"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColAppRule) = "Application Rule"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColProtocol) = "Protocol"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColPort) = "Port"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColAppProfile) = "Application Profile"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColPoolName)  = "Pool Name"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColPoolStatus)  = "Pool Status"
        $wsStats.Cells.Item($lbDetailsRowHeader,$lbdetailsColPoolMember) = "Pool Member"

        # Format lb details headers
        $columnHeaderRange = $wsStats.Range($wsStats.cells.item($lbDetailsRowHeader,$lbdetailsColEdgeId), $wsStats.cells.item($lbDetailsRowHeader,$lbdetailsColPoolMember))
        $columnHeaderRange.Interior.ColorIndex = $subTitleInteriorColor
        $columnHeaderRange.font.bold = $subTitleFontBold
        $columnHeaderRange.AutoFilter() | Out-Null

        # # Need to keep a count of the row, and this is the one we start on.
        $row = $lbDetailsRowHeader + 1

        # # Loop through all the VIP config on the edge
        foreach ($lbconfvip in ($lbconf.virtualserver)) {

            Write-Progress -Activity "Procesing $($edge.name)" -Status "Documenting VIP - $($lbconfvip.name)"

            # save the pool and vip stats into their own variables
            $vipstats = $lbStats.virtualserver | ? {$_.virtualServerId -eq $lbconfvip.virtualServerId}
            $poolstats = $lbStats.pool | ? {$_.poolId -eq $lbconfvip.defaultPoolId}

            # start filling in the basic information
            $wsStats.Cells.Item($row,$lbdetailsColEdgeId) = $edge.id
            $wsStats.Cells.Item($row,$lbdetailsColEdgeName) = $edge.name
            $wsStats.Cells.Item($row,$lbdetailsColVIPName) = $lbconfvip.name
            $wsStats.Cells.Item($row,$lbdetailsColVIPAddress) = $lbconfvip.ipAddress
            # VIP Status is fairly easy, except we apply a bit of color
            $wsStats.Cells.Item($row,$lbdetailsColVIPStatus) = $vipstats.status
            if ($vipstats.status -eq "OPEN") {
                $wsStats.Cells.Item($row,$lbdetailsColVIPStatus).Font.ColorIndex = $fontColorGood
            } else {
                $wsStats.Cells.Item($row,$lbdetailsColVIPStatus).Font.ColorIndex = $fontColorBad
            }
            $wsStats.Cells.Item($row,$lbdetailsColSI) = $lbconfvip.enableServiceInsertion
            $wsStats.Cells.Item($row,$lbdetailsColEngine) = $lbconfvip.accelerationEnabled

            # There can be multiple application rules applied to a VIP, so we
            # loop through them all, and replace the object-id with the friendly
            # name.
            $appRuleArray = @()
            foreach ($rule in $lbconfvip.applicationRuleId) {
                $appRuleArray += ($lbconf.applicationrule | ? {$_.applicationRuleId -eq $rule} ).name
            }
            $wsStats.Cells.Item($row,$lbdetailsColAppRule) = $appRuleArray -join "`r`n"

            $wsStats.Cells.Item($row,$lbdetailsColProtocol) = $lbconfvip.protocol
            $wsStats.Cells.Item($row,$lbdetailsColPort) = $lbconfvip.port

            # We do the same replacement of objectid to friendly names for the
            # application profile and pools
            $wsStats.Cells.Item($row,$lbdetailsColAppProfile) = ($lbconf.applicationProfile | ? {$_.applicationProfileId -eq $lbconfvip.applicationProfileId}).name
            $wsStats.Cells.Item($row,$lbdetailsColPoolName) = ($lbconf.pool | ? {$_.poolId -eq $lbconfvip.defaultPoolId}).name
            # Apply some color to the pool status
            $wsStats.Cells.Item($row,$lbdetailsColPoolStatus) = $poolstats.status
            if ($poolstats.status -eq "UP") {
                $wsStats.Cells.Item($row,$lbdetailsColPoolStatus).Font.ColorIndex = $fontColorGood
            } else {
                $wsStats.Cells.Item($row,$lbdetailsColPoolStatus).Font.ColorIndex = $fontColorBad
            }

            # Now we do some trickery. We place each pool member on a different
            # row, and then depending on the member status, we color the text.
            $rowMember = $row
            foreach ($member in $poolstats.member) {
                $wsStats.Cells.Item($rowMember,$lbdetailsColPoolMember) = $member.name
                if ($member | Get-Member -MemberType Property -Name Status) {
                    if ($member.status -eq "UP") {
                        $wsStats.Cells.Item($rowMember,$lbdetailsColPoolMember).Font.ColorIndex = $fontColorGood
                    } else {
                        $wsStats.Cells.Item($rowMember,$lbdetailsColPoolMember).Font.ColorIndex = $fontColorBad
                    }
                } else {
                    # If the member doesn't have a status, like when a "cluster"
                    # object is defined in the pool, but there are no VMs in the
                    # cluster turned on, then we format the cell differently
                    $wsStats.Cells.Item($rowMember,$lbdetailsColPoolMember).Font.Italic = $True
                    $wsStats.Cells.Item($rowMember,$lbdetailsColPoolMember).AddComment() | out-null
                    $wsStats.Cells.Item($rowMember,$lbdetailsColPoolMember).comment.Visible = $False
                    $wsStats.Cells.Item($rowMember,$lbdetailsColPoolMember).Comment.text("NSX-PowerOps:`r`nThere doesn't appear to be any underlying members") | out-null
                }

                # Now we see if the row number we have incremented due to
                # multiple members has increased from the original row we start
                # on, and if so, we go back and merge the previous columns to
                # make it look all nice and spiffy.
                if ($row -ne $rowMember) {
                    $lbdetailsColEdgeId..$lbdetailsColPoolStatus | % {
                        $mergeCells = $wsStats.Range($wsStats.Cells.Item($row,$_),$wsStats.Cells.Item($rowMember,$_))
                        $MergeCells.Select() | out-null
                        $MergeCells.MergeCells = $true
                        $MergeCells.VerticalAlignment = $verticalAlignmentTop
                    }
                }
                $rowMember ++
            }
            $row = $rowMember
        }
        # Format the lb details table with borders
        $lbDetailsRange = $wsStats.Range($wsStats.cells.item($lbDetailsRowTitle,$lbdetailsColEdgeId), $wsStats.cells.item(($row - 1),$lbdetailsColPoolMember))
        $lbDetailsRange.Borders.linestyle = $borderLineStyle
        $lbDetailsRange.Borders.Weight = $borderWeight

        # Apply autofit to the whole sheet
        $entireRange = $wsStats.UsedRange
        $entireRange.EntireColumn.Autofit() | out-null

    }

    # Add a new worksheet for the overall summary pages as the first worksheet.
    $wsSummary = $nsxLBExcelWorkBook.WorkSheets.Add($nsxLBExcelWorkBook.Worksheets.Item(1))
    $wsSummary.Name = "Summary"

    $summaryRowTitle = 1
    $summaryRowHeader = $summaryRowTitle + 1
    $summaryRowDetail = $summaryRowHeader + 1
    $summaryColHeaderEdgeName = 1
    $summaryColHeaderEdgeId = 2
    $summaryColHeaderVipTotal = 3
    $summaryColHeaderVipOpen = 4
    $summaryColHeaderVipClosed = 5
    $summaryColHeaderPoolTotal = 6
    $summaryColHeaderPoolUp = 7
    $summaryColHeaderPoolDown = 8
    $summaryColHeaderMemberTotal = 9
    $summaryColHeaderMemberUp = 10
    $summaryColHeaderMemberDown = 11
    $summaryColHeaderMemberUnknown = 12

    $wsSummary.Cells.Item($summaryRowTitle,$summaryColHeaderEdgeName) = "NSX Edge Load Balancer - Summary"

    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderEdgeName) = "Edge Name"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderEdgeId) = "Edge ID"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderVipTotal) = "VIPs"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderVipOpen) = "VIPs Up"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderVipClosed) = "VIPs Closed"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderPoolTotal) = "Pools"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderPoolUp) = "Pools Up"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderPoolDown) = "Pools Down"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderMemberTotal) = "Members"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderMemberUp) = "Members Up"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderMemberDown) = "Members Down"
    $wsSummary.Cells.Item($summaryRowHeader,$summaryColHeaderMemberUnknown) = "Members Unknown"


    $wsSummary.Cells.Item($summaryRowTitle,$summaryColHeaderEdgeName).Font.Size = $titleFontSize
    $wsSummary.Cells.Item($summaryRowTitle,$summaryColHeaderEdgeName).Font.Bold = $titleFontBold
    $wsSummary.Cells.Item($summaryRowTitle,$summaryColHeaderEdgeName).Font.ColorIndex = $titleFontColorIndex
    $wsSummary.Cells.Item($summaryRowTitle,$summaryColHeaderEdgeName).Font.Name = $titleFontName
    $wsSummary.Cells.Item($summaryRowTitle,$summaryColHeaderEdgeName).Interior.ColorIndex = $titleInteriorColor
    $summaryTitleRange = $wsSummary.Range($wsSummary.cells.item($summaryRowTitle,$summaryColHeaderEdgeName),$wsSummary.cells.item($summaryRowTitle,$wsSummary.usedRange.columns.count))
    $summaryTitleRange.merge() | Out-Null

    $summaryHeaderRange = $wsSummary.Range($wsSummary.cells.item($summaryRowHeader,$summaryColHeaderEdgeName), $wsSummary.cells.item($summaryRowHeader,$wsSummary.usedRange.columns.count))
    $summaryHeaderRange.Interior.ColorIndex = $subTitleInteriorColor
    $summaryHeaderRange.font.bold = $True

    $row = $summaryRowDetail
    foreach ($item in $summaryEdgeStats.keys) {
        $wsSummary.Cells.Item($row,$summaryColHeaderEdgeName) = $item
        $wsSummary.HyperLinks.Add($wsSummary.cells.item($row,$summaryColHeaderEdgeName),"","'$($item)'!A1") | out-null
        $wsSummary.Cells.Item($row,$summaryColHeaderEdgeId) = $summaryEdgeStats.item($item).id
        $wsSummary.Cells.Item($row,$summaryColHeaderVipTotal) = $summaryEdgeStats.item($item).vips
        $wsSummary.Cells.Item($row,$summaryColHeaderVipOpen) = $summaryEdgeStats.item($item).vipsopen
        $wsSummary.Cells.Item($row,$summaryColHeaderVipClosed) = $summaryEdgeStats.item($item).vipsclosed
        if ($summaryEdgeStats.item($item).vipsclosed -ge 1) {
            $wsSummary.Cells.Item($row,$summaryColHeaderVipClosed).Interior.ColorIndex = $fontColorBad
        }
        $wsSummary.Cells.Item($row,$summaryColHeaderPoolTotal) = $summaryEdgeStats.item($item).pools
        $wsSummary.Cells.Item($row,$summaryColHeaderPoolUp) = $summaryEdgeStats.item($item).poolsup
        $wsSummary.Cells.Item($row,$summaryColHeaderPoolDown) = $summaryEdgeStats.item($item).poolsdown
        if ($summaryEdgeStats.item($item).poolsdown -ge 1) {
            $wsSummary.Cells.Item($row,$summaryColHeaderPoolDown).Interior.ColorIndex = $fontColorBad
        }
        $wsSummary.Cells.Item($row,$summaryColHeaderMemberTotal) = $summaryEdgeStats.item($item).members
        $wsSummary.Cells.Item($row,$summaryColHeaderMemberUp) = $summaryEdgeStats.item($item).membersUp
        $wsSummary.Cells.Item($row,$summaryColHeaderMemberDown) = $summaryEdgeStats.item($item).membersDown
        if ($summaryEdgeStats.item($item).membersDown -ge 1) {
            $wsSummary.Cells.Item($row,$summaryColHeaderMemberDown).Interior.ColorIndex = $fontColorBad
        }
        $wsSummary.Cells.Item($row,$summaryColHeaderMemberUnknown) = $summaryEdgeStats.item($item).membersUnknown
        if ($summaryEdgeStats.item($item).membersUnknown -ge 1) {
            $wsSummary.Cells.Item($row,$summaryColHeaderMemberUnknown).Interior.ColorIndex = $fontColorUnknownState
        }
        $row ++
    }

    $wsSummaryRange = $wsSummary.usedRange
    $wsSummaryRange.EntireColumn.Autofit() | out-null
    $wsSummaryRange.Borders.linestyle = $borderLineStyle
    $wsSummaryRange.Borders.Weight = $borderWeight
    $wsSummaryRange.HorizontalAlignment = $horizontalAlignmentCenter

    $global:newExcel.worksheets.item("Sheet1").Delete()
    $global:newExcel.ActiveWorkbook.SaveAs($DocumentPath)
    $global:newExcel.Workbooks.Close()
    $global:newExcel.Quit()

    Write-Progress -Activity "Procesing $($edge.name)" -Completed
    releaseObject -obj $nsxLBExcelWorkBook
    releaseObject -obj $newExcel
}

# ---- ---- ---- ---- ---- ---- ---- ---- ---- #
#---- ---- HealthCheck Functions start here ---- ----#
# ---- ---- ---- ---- ---- ---- ---- ---- ---- # 


function runNSXTest ($testModule){
    $startTime = Get-Date
    $outputFileName = "$testModule-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xml" -f (get-date)
    
    #Todo: Change connection handling to suit connection profiles.
    $global:NsxConnection = $DefaultNSXConnection
    $global:EsxiHostCredential = Get-ProfileEsxiCreds -ProfileName $config.defaultprofile
    $global:ControllerCredential = Get-ProfileControllerCreds -ProfileName $config.defaultprofile
    $result = Invoke-Pester -Script @{ 
        Path = "$mydirectory/HealthCheck/$testModule.Tests.ps1"
        Parameters = @{ 
            testModule = $testModule
        }
    } `
    -OutputFile $documentlocation/$outputFileName -OutputFormat NUnitXML 

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
        Out-Event -entrytype information "Executing Load Balancer documentation task"
        runLB2Excel
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
            "Status" = { if ((checkDependancies -ListAvailable $true) ) { "MenuEnabled" } else { "Disabled" } }
            "Footer" = $footer
            "MainHeader" = $MainHeader
            "Subheader" = $Subheader
            "Items" = @(
                @{
                    "SectionHeader" = "Environment Documentation"
                    "Name" = "Document All NSX Components"
                    "Status" = { if ($DefaultNSXConnection -and [type]::GetTypeFromProgID("Excel.Application") ) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = { getNSXComponents }
                },
                @{
                    "SectionHeader" = "Environment Documentation"
                    "Name" = "Document ESXi Host(s) Info"
                    "Status" = { if ($DefaultNSXConnection  -and [type]::GetTypeFromProgID("Excel.Application") ) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  getHostInformation }
                },
                @{
                    "SectionHeader" = "Networking Documentation"
                    "Name" = "Document NSX Environment via Visio Diagramming Tool"
                    "Status" = { if ($DefaultNSXConnection) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runNSXVISIOTool }
                },
                @{
                    "SectionHeader" = "Networking Documentation"
                    "Name" = "Document Routing information"
                    "Status" = { if ($DefaultNSXConnection -and [type]::GetTypeFromProgID("Excel.Application") ) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  getRoutingInformation }
                },
                @{
                    "SectionHeader" = "Networking Documentation"
                    "Name" = "Document Load Balancing Information"
                    "Status" = { if ($DefaultNSXConnection -and [type]::GetTypeFromProgID("Excel.Application") ) { "MenuEnabled" } else { "Disabled" } }
                    "Interactive" = $true
                    "Script" = {  runLB2Excel }
                },
                @{
                    "SectionHeader" = "Security Documentation"
                    "Name" = "Document NSX DFW info to Excel via DFW2Excel"
                    "Status" = { if ($DefaultNSXConnection -and [type]::GetTypeFromProgID("Excel.Application") ) { "MenuEnabled" } else { "Disabled" } }
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
            "Status" = { if ((checkDependancies -ListAvailable $true)) { "MenuEnabled" } else { "Disabled" } }
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
                    "Interactive" = $true
                    "Script" = { 
                        try { 
                            New-ConnectionProfile
                            if ( $Config.DefaultProfile -and (-not ($DefaultNSXConnection))) { connectProfile -ProfileName $Config.DefaultProfile } 
                        }
                        catch { 
                            # Make error here non terminating...
                            write-warning "Profile creation failed.  Please try again : $_"
                        }
                    }
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
                if ((checkDependancies -ListAvailable $true) -and ( $Config.Profiles.count -gt 0 )) { 
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
