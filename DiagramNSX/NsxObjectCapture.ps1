<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#NSX Object Capture Script
#Nick Bradford
#nbradford@vmware.com
#Version 0.1

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

#Requires -Version 3.0
#Requires -Modules PowerNSX

#This script captures the necessary objects information from NSX and persists
#them to disk in order for topology reconstruction to be done by a sister script
#NSXDiagram.ps1.

param (

    [pscustomobject]$Connection=$DefaultNsxConnection,
    [string]$ExportFile
)

If ( (-not $Connection) -and ( -not $Connection.ViConnection.IsConnected ) ) {

    throw "No valid NSX Connection found.  Connect to NSX and vCenter using Connect-NsxServer first.  You can specify a non default PowerNSX Connection using the -connection parameter."

}

Set-StrictMode -Off

#########################
$TempDir = "$($env:Temp)\VMware\NSXObjectCapture"
if ( -not ( $exportFile )) { 
    $ExportPath = "$([system.Environment]::GetFolderPath('MyDocuments'))\VMware\NSXObjectCapture"
    $ExportFile = "$ExportPath\NSX-ObjectCapture-$($Connection.Server)-$(get-date -format "yyyy_MM_dd_HH_mm_ss").zip"
}
else { 
    $ExportPath = split-path -parent $ExportFile
}

$maxdepth = 5
$maxCaptures = 10

if ( -not ( test-path $TempDir )) {
    New-Item -Type Directory $TempDir | out-null
}
else {
    Get-ChildItem $TempDir | Remove-Item -force -recurse
}

if ( -not ( test-path $ExportPath )) {
    New-Item -Type Directory $ExportPath | out-null
}

$LsExportFile = "$TempDir\LsExport.xml"
$VdPgExportFile = "$TempDir\VdPgExport.xml"
$StdPgExportFile = "$TempDir\StdPgExport.xml"
$LrExportFile = "$TempDir\LrExport.xml"
$EdgeExportFile = "$TempDir\EdgeExport.xml"
$VmExportFile = "$TempDir\VmExport.xml"
$CtrlExportFile = "$TempDir\CtrlExport.xml"
$MacAddressExportFile = "$TempDir\MacExport.xml"


$LsHash = @{}
$VdPortGroupHash = @{}
$StdPgHash = @{}
$LrHash = @{}
$EdgeHash = @{}
$VmHash = @{}
$CtrlHash = @{}
$MacHash = @{}

write-progress -Activity "Generating NSX Capture Bundle"
write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting LogicalSwitches"
Get-NsxLogicalSwitch -connection $connection | % {
    $LsHash.Add($_.objectId, $_.outerXml)
}

write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting DV PortGroups"
Get-VDPortGroup -server $connection.ViConnection | % {

    if ( $_.VlanConfiguration ) {
        if (  $_.VlanConfiguration.VlanId ) {
            $VlanID = $_.VlanConfiguration.VlanId
        }
        else {
            $VlanId = "0"
        }
    }
    else {
        $VlanId = "0"
    }
    $VdPortGroupHash.Add( $_.ExtensionData.Moref.Value, [pscustomobject]@{ "MoRef" = $_.ExtensionData.Moref.Value; "Name" = $_.Name; "VlanId" = $VlanId } )

}

write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting VSS PortGroups"
Get-VirtualPortGroup -server $connection.ViConnection | ? { $_.key -match 'key-vim.host.PortGroup'} | Sort-Object -Unique | % {
    $StdPgHash.Add( $_.Name, [pscustomobject]@{ "Name" = $_.Name; "VlanId" = $VlanId } )

}

write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting Logical Routers"
$LogicalRouters = Get-NsxLogicalRouter -connection $connection
$LogicalRouters | % {
    $LrHash.Add($_.Id, $_.outerXml)
}
write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting Edges"
$edges = Get-NsxEdge -connection $connection
$edges | % {
    $EdgeHash.Add($_.id, $_.outerxml)
}

write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting NSX Controllers"
$Controllers = Get-NsxController -connection $connection
$Controllers | % {
    $CtrlHash.Add($_.id, $_.outerxml)
}


write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting VMs"
Get-Vm -server $connection.ViConnection| % {

    $IsManager = $false
    $IsEdge = $false
    $IsLogicalRouter = $false
    $IsController = $false
    $Nics = @()

    #Tag any edge, DLR or controller vms...
    $moref = $_.id.replace("VirtualMachine-","")
    if ( $Edges.appliances.appliance.vmid ) {
        if ( $Edges.appliances.appliance.vmid.Contains($moref) ) {
            $IsEdge = $true
        }
    }
    if ( $LogicalRouters.appliances.appliance.vmid ) {
        if ( $LogicalRouters.appliances.appliance.vmid.Contains($moref) ) {
            $IsLogicalRouter = $true
        }
    }
    if ( $Controllers.virtualMachineInfo.objectId ) {
        if ( $Controllers.virtualMachineInfo.objectId.Contains($moref) ) {
            $IsController = $true
        }
    }

    #NSX Keeps some metadata about Managers and Edges (not controllers) in the extraconfig data of the associated VMs.
    $configview = $_ | Get-View -Property Config
    $NSXAppliance = ($configview.Config.ExtraConfig | ? { $_.key -eq "vshield.vmtype" }).Value
    If ( $NSXAppliance -eq "Manager" )  {
        $IsManager = $true
    }

    $_ | Get-NetworkAdapter -server $connection.ViConnection | % {
        If ( $_.ExtensionData.Backing.Port.PortgroupKey ) {
            $PortGroup = $_.ExtensionData.Backing.Port.PortgroupKey;
        }
        elseif ( $_.NetworkName ) {
            $PortGroup = $_.NetworkName;
        }
        else {
            #No nic attachment
            Break
        }
        $Nics += [pscustomobject]@{
            "PortGroup" = $PortGroup
            "MacAddress" = $_.MacAddress
        }
    }

    $VmHash.Add($Moref, [pscustomobject]@{
        "MoRef" = $MoRef;
        "Name" = $_.name ;
        "Nics" = $Nics;
        "IsManager" = $IsManager;
        "IsEdge" = $IsEdge;
        "IsLogicalRouter" = $IsLogicalRouter;
        "IsController" = $IsController;
        "ToolsIp" = $_.Guest.Ipaddress })
}

write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Getting IP and MAC details from Spoofguard"
Get-NsxSpoofguardPolicy -connection $connection | Get-NsxSpoofguardNic -connection $connection | % {
    if ($MacHash.ContainsKey($_.detectedmacAddress)) {
        write-warning "Duplicate MAC ($($_.detectedMacAddress) - $($_.nicname)) found.  Skipping NIC!"
    }
    else {
        $MacHash.Add($_.detectedmacaddress, $_)
    }
}


write-progress -Activity "Generating NSX Capture Bundle" -CurrentOperation "Creating Object Export Bundle"

#Export files
$LsHash | export-clixml -depth $maxdepth $LsExportFile
$VdPortGroupHash | export-clixml -depth $maxdepth $VdPgExportFile
$StdPgHash | export-clixml -depth $maxdepth $StdPgExportFile
$LrHash | export-clixml -depth $maxdepth $LrExportFile
$EdgeHash | export-clixml -depth $maxdepth $EdgeExportFile
$VmHash | export-clixml -depth $maxdepth $VmExportFile
$CtrlHash | export-clixml -depth $maxdepth $CtrlExportFile
$MacHash | export-clixml -depth $maxdepth $MacAddressExportFile

Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::CreateFromDirectory($TempDir, $ExportFile)
$Captures = Get-ChildItem $ExportPath -filter 'NSX-ObjectCapture-*.zip'
while ( ( $Captures | measure ).count -ge $maxCaptures ) {

    write-warning "Maximum number of captures reached.  Removing oldest capture."
    $captures | sort-object -property LastWriteTime | select-object -first 1 | remove-item -confirm:$false
    $Captures = Get-ChildItem $ExportPath
}

write-progress -Activity "Generating NSX Capture Bundle" -Completed
return $ExportFile