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

# Author:   Tony Sangha
# Blog:    tonysangha.com
# Version:  1.0.1
# PowerCLI v6.0
# PowerNSX v3.0
# Purpose: Document NSX for vSphere Distributed Firewall

param (
    [switch]$EnableIpDetection,
    [switch]$GetSecTagMembers,
    [switch]$GetSecGrpMembers,
    [switch]$StartMinimised,
    [string]$DocumentPath
)
# Empty Hash-tables for use with Hyperlinks
$services_ht = @{}
$vmaddressing_ht = @{}
$ipsets_ht = @{}
$secgrp_ht = @{}
########################################################
# Cleanup Excel application object
# We Need to call this for EVERY VARIABLE that references
# an excel object.  __EVERY VARIABLE__
########################################################
function ReleaseObject {
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

########################################################
# Cleanup Excel application object
# We Need to call this for EVERY VARIABLE that references
# an excel object.  __EVERY VARIABLE__
########################################################
function ReleaseObject {
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

########################################################
#  Formatting/Functions Options for Excel Spreadsheet
########################################################

    $titleFontSize = 18
    $titleFontBold = $True
    $titleFontColorIndex = 2
    $titleFontName = "Calibri (Body)"
    $titleInteriorColor = 10

    $subTitleFontSize = 10.5
    $subTitleFontBold = $True
    $subTitleFontName = "Calibri (Body)"
    $subTitleInteriorColor = 43

    $valueFontName = "Calibri (Body)"
    $valueFontSize = 10.5
    $valueMissingColorIndex =
    $valueMissingText = "<BLANK>"
    $valueMissingHighlight = 6
    $valueNotApplicable = "<NOT APPLICABLE>"
    $valueNotDefined = "<NOT DEFINED>"

########################################################
#    Global Parameters
########################################################

$null = New-VIProperty -Name VMIPAddress -ObjectType VirtualMachine `
    -ValueFromExtensionProperty 'Summary.Guest.IPAddress' `
    -Force

########################################################
#    Define Excel Workbook and calls to different WS
########################################################
function startExcel(){

    $Excel = New-Object -Com Excel.Application
    if ( -not $StartMinimised ) { 
        $Excel.visible = $True
    }
    $Excel.DisplayAlerts = $false
    $wb = $Excel.Workbooks.Add()

    if ($args[0] -eq "y"){

        Write-Host "`nRetrieving IP Addresses for ALL Virtual Machines in vCenter environment." -foregroundcolor "magenta"
        Write-Host "*** This may take a while ***." -foregroundcolor "Yellow"
        $ws0 = $wb.WorkSheets.Add()
        $ws0.Name = "VM_Info"
        vm_ip_addresses_ws($ws0)
        $usedRange = $ws0.UsedRange
        $null = $usedRange.EntireColumn.Autofit()
        ReleaseObject -Obj $ws0
    }

    Write-Host "`nRetrieving Services configured in NSX-v." -foregroundcolor "magenta"
    $ws1 = $wb.WorkSheets.Add()
    $ws1.Name = "Services"
    services_ws($ws1)
    $usedRange = $ws1.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Service Groups configured in NSX-v." -foregroundcolor "magenta"
    $ws2 = $wb.WorkSheets.Add()
    $ws2.Name = "Service_Groups"
    service_groups_ws($ws2)
    $usedRange = $ws2.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving MACSETS configured in NSX-v." -foregroundcolor "magenta"
    $ws3 = $wb.WorkSheets.Add()
    $ws3.Name = "MACSETS"
    macset_ws($ws3)
    $usedRange = $ws3.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving IPSETS configured in NSX-v." -foregroundcolor "magenta"
    $ws4 = $wb.WorkSheets.Add()
    $ws4.Name = "IPSETS"
    ipset_ws($ws4)
    $usedRange = $ws4.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Security Groups configured in NSX-v." -foregroundcolor "magenta"
    $ws5 = $wb.WorkSheets.Add()
    $ws5.Name = "Security_Groups"
    sg_ws($ws5)
    $usedRange = $ws5.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Security Tags configured in NSX-v." -foregroundcolor "magenta"
    $ws6 = $wb.Worksheets.Add()
    $ws6.Name = "Security_Tags"
    sec_tags_ws($ws6)
    $usedRange = $ws6.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving VMs in DFW Exclusion List" -foregroundcolor "magenta"
    $ws7 = $wb.Worksheets.Add()
    $ws7.Name = "DFW Exclusion list"
    ex_list_ws($ws7)
    $usedRange = $ws7.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving Environment Summary" -foregroundcolor "magenta"
    $ws8 = $wb.Worksheets.Add()
    $ws8.Name = "Environment Summary"
    env_ws($ws8)
    $usedRange = $ws8.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    Write-Host "`nRetrieving DFW Layer 3 FW Rules" -foregroundcolor "magenta"
    $ws9 = $wb.Worksheets.Add()
    $ws9.Name = "Layer 3 Firewall"
    dfw_ws($ws9)
    $usedRange = $ws9.UsedRange
    $null = $usedRange.EntireColumn.Autofit()

    # Must cleanup manually or excel process wont quit.
    ReleaseObject -Obj $ws1    
    ReleaseObject -Obj $ws2
    ReleaseObject -Obj $ws3    
    ReleaseObject -Obj $ws4    
    ReleaseObject -Obj $ws5    
    ReleaseObject -Obj $ws6    
    ReleaseObject -Obj $ws7
    ReleaseObject -Obj $ws8    
    ReleaseObject -Obj $ws9    
    ReleaseObject -Obj $usedRange
    
    if ( $DocumentPath -and (test-path (split-path -parent $DocumentPath))) { 
        $wb.SaveAs($DocumentPath)
        $wb.close(0)
        $Excel.Quit()
        ReleaseObject -Obj $Excel
        ReleaseObject -Obj $wb
        
    }

}

########################################################
#    Firewall Worksheet (Only Layer 3)
########################################################

function dfw_ws($sheet){

    $sheet.Cells.Item(1,1) = "Firewall Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "s1")
    $range1.merge() | Out-Null

    l3_rules($sheet)
}

function l3_rules($sheet){

    $sheet.Cells.Item(2,1) = "Layer 3 Rules"
    $sheet.Cells.Item(2,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(2,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(2,1).Font.Name = $titleFontName
    $sheet.Cells.Item(2,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a2", "s2")

    $sheet.Cells.Item(3,1) = "Section Name"
    $sheet.Cells.Item(3,2) = "Section ID"

    $sheet.Cells.Item(3,3) = "Rule Status"
    $sheet.Cells.Item(3,4) = "Rule Name"
    $sheet.Cells.Item(3,5) = "Rule ID"

    $sheet.Cells.Item(3,6) = "Source Excluded (Negated)"
    $sheet.Cells.Item(3,7) = "Source Type"
    $sheet.Cells.Item(3,8) = "Source Name"
    $sheet.Cells.Item(3,9) = "Source Object ID"

    $sheet.Cells.Item(3,10) = "Destination Excluded (Negated)"
    $sheet.Cells.Item(3,11) = "Destination Type"
    $sheet.Cells.Item(3,12) = "Destination Name"
    $sheet.Cells.Item(3,13) = "Destination Object ID"

    $sheet.Cells.Item(3,14) = "Service Name"
    $sheet.Cells.Item(3,15) = "Action"
    $sheet.Cells.Item(3,16) = "Direction"
    $sheet.Cells.Item(3,17) = "Packet Type"
    $sheet.Cells.Item(3,18) = "Applied To"
    $sheet.Cells.Item(3,19) = "Log"

    $range2 = $sheet.Range("a3", "s3")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    $fw_sections = Get-NSXFirewallSection

    $row = 4

    foreach($section in $fw_sections){
        $sheet.Cells.Item($row,1) = $section.name
        $sheet.Cells.Item($row,1).Font.Bold = $true
        $sheet.Cells.Item($row,2) = $section.id
        $sheet.Cells.Item($row,2).Font.Bold = $true

        foreach($rule in $section.rule){

            if($rule.disabled -eq "false"){
                $sheet.Cells.Item($row,3) = "Enabled"
            } else {
                $sheet.Cells.Item($row,3) = "Disabled"
            }
            if ($rule.name -eq "rule"){
                $sheet.Cells.Item($row,4) = $valueNotDefined
                } else {
                    $sheet.Cells.Item($row,4) = $rule.name
                    $sheet.Cells.Item($row,4).Font.Bold = $true
                }
            $sheet.Cells.Item($row,5) = $rule.id
            $sheet.Cells.Item($row,5).Font.Bold = $true

            # Highlight Allow/Deny statements
            if($rule.action -eq "deny"){
                $sheet.Cells.Item($row,15) = $rule.action
                $sheet.Cells.Item($row,15).Font.ColorIndex = 3
            } elseif($rule.action -eq "allow"){
                $sheet.Cells.Item($row,15) = $rule.action
                $sheet.Cells.Item($row,15).Font.ColorIndex = 4
            }

            $sheet.Cells.Item($row,16) = $rule.direction
            $sheet.Cells.Item($row,17) = $rule.packetType
            $sheet.Cells.Item($row,19) = $rule.logged

            ###### Sources Section ######
            $srcRow = $row

            # If Source does not exist, it must be set to ANY
            if (!$rule.sources){
                $sheet.Cells.Item($srcRow,8) = "ANY"
                $sheet.Cells.Item($srcRow,8).Font.ColorIndex = 45
            } else {
                #If Negated field exists, document
                if ($rule.sources.excluded -eq "True" ){
                    $sheet.Cells.Item($srcRow,6) = "NEGATE"
                    $sheet.Cells.Item($row,6).Font.ColorIndex = 3
                }

                foreach($source in $rule.sources.source){
                    $sheet.Cells.Item($srcRow,7) = $source.type

                    if($source.type -eq "Ipv4Address"){
                        $sheet.Cells.Item($srcRow,8) = $source.value
                    } 
                    elseif($source.type -eq "Ipv6Address") {
                        $sheet.Cells.Item($srcRow,8) = $source.value
                    } 
                    elseif ($source.type -eq "IPSet") {
                        $result = $ipsets_ht[$source.value]        
                        if([string]::IsNullOrWhiteSpace($result))
                        {
                            $sheet.Cells.Item($srcRow,8) = $source.name
                            $sheet.Cells.Item($srcRow,9) = $source.value
                        }
                        else 
                        {
                            $link = $sheet.Hyperlinks.Add(
                            $sheet.Cells.Item($srcRow,8),
                            "",
                            $result,
                            $source.value,
                            $source.name)  
                           $sheet.Cells.Item($srcRow,9) = $source.value
                        }
                     }
                    elseif ($source.type -eq "SecurityGroup") {
                        $result = $secgrp_ht[$source.value]        
                        if([string]::IsNullOrWhiteSpace($result))
                        {
                            $sheet.Cells.Item($srcRow,8) = $source.name
                            $sheet.Cells.Item($srcRow,9) = $source.value
                        }
                        else 
                        {
                            $link = $sheet.Hyperlinks.Add(
                            $sheet.Cells.Item($srcRow,8),
                            "",
                            $result,
                            $source.value,
                            $source.name)  
                           $sheet.Cells.Item($srcRow,9) = $source.value
                        }
                     }
                    elseif ($source.type -eq "VirtualMachine") {
                        $result = $vmaddressing_ht[$source.value]        
                        if([string]::IsNullOrWhiteSpace($result))
                        {
                            $sheet.Cells.Item($srcRow,8) = $source.name
                            $sheet.Cells.Item($srcRow,9) = $source.value
                        }
                        else 
                        {
                            $link = $sheet.Hyperlinks.Add(
                            $sheet.Cells.Item($srcRow,8),
                            "",
                            $result,
                            $source.value,
                            $source.name)  
                           $sheet.Cells.Item($srcRow,9) = $source.value
                        }
                     }
                     else {
                        $sheet.Cells.Item($srcRow,8) = $source.name
                        $sheet.Cells.Item($srcRow,9) = $source.value
                    }
                $srcRow++
                }
            }

            ###### Destination Section ######
            $dstRow = $row

            # If Destination does not exist, it must be set to ANY
            if (!$rule.destinations){
                $sheet.Cells.Item($dstRow,13) = "ANY"
                $sheet.Cells.Item($dstRow,13).Font.ColorIndex = 45
            } else {

                #If Negated field exists, document
                if ($rule.destinations.excluded -eq "True" ){
                    $sheet.Cells.Item($srcRow,10) = "NEGATE"
                    $sheet.Cells.Item($row,10).Font.ColorIndex = 3
                }

                foreach($destination in $rule.destinations.destination){
                    $sheet.Cells.Item($dstRow,11) = $destination.type
                    if($destination.type -eq "Ipv4Address"){
                        $sheet.Cells.Item($dstRow,12) = $destination.value
                        } 
                    elseif($destination.type -eq "Ipv6Address") {
                            $sheet.Cells.Item($dstRow,12) = $destination.value
                        } 
                    elseif ($destination.type -eq "IPSet") {
                        $result = $ipsets_ht[$destination.value]        
                        if([string]::IsNullOrWhiteSpace($result))
                        {
                            $sheet.Cells.Item($dstRow,12) = $destination.name
                            $sheet.Cells.Item($dstRow,13) = $destination.value
                        }
                        else 
                        {
                            $link = $sheet.Hyperlinks.Add(
                            $sheet.Cells.Item($dstRow,12),
                            "",
                            $result,
                            $destination.value,
                            $destination.name)  
                           $sheet.Cells.Item($dstRow,13) = $destination.value
                        }
                     }
                    elseif ($destination.type -eq "VirtualMachine") {
                        $result = $vmaddressing_ht[$destination.value]        
                        if([string]::IsNullOrWhiteSpace($result))
                        {
                            $sheet.Cells.Item($dstRow,12) = $destination.name
                            $sheet.Cells.Item($dstRow,13) = $destination.value
                        }
                        else 
                        {
                            $link = $sheet.Hyperlinks.Add(
                            $sheet.Cells.Item($dstRow,12),
                            "",
                            $result,
                            $destination.value,
                            $destination.name)  
                           $sheet.Cells.Item($dstRow,13) = $destination.value
                        }
                     }
                    elseif ($destination.type -eq "SecurityGroup") {
                        $result = $secgrp_ht[$destination.value]        
                        if([string]::IsNullOrWhiteSpace($result))
                        {
                            $sheet.Cells.Item($dstRow,12) = $destination.name
                            $sheet.Cells.Item($dstRow,13) = $destination.value
                        }
                        else 
                        {
                            $link = $sheet.Hyperlinks.Add(
                            $sheet.Cells.Item($dstRow,12),
                            "",
                            $result,
                            $destination.value,
                            $destination.name)  
                           $sheet.Cells.Item($dstRow,13) = $destination.value
                        }
                     }                     
                     else {
                            $sheet.Cells.Item($dstRow,12) = $destination.name
                            $sheet.Cells.Item($dstRow,13) = $destination.value
                        }
                    $dstRow++
                }
            }

            ###### Services Section ######
            $svcRow = $row

            # If Service does not exist, it must be set to ANY
            if(!$rule.services){
                $sheet.Cells.Item($svcRow,14) = "ANY"
                $sheet.Cells.Item($svcRow,14).Font.ColorIndex = 45
            } else {
                foreach($service in $rule.services.service){
                    if($service.protocolName)
                    {
                        $sheet.Cells.Item($svcRow,14) = $service.protocolName + "/" + $service.destinationPort
                    }
                    else {
                        # $sheet.Cells.Item($svcRow,14) = $service.name
                        $result = $services_ht[$service.value]        
                        if([string]::IsNullOrWhiteSpace($result))
                        {
                             $sheet.Cells.Item($svcRow,14) = $service.name
                             # $svcRow++ # Increment Rows
                        }
                        else 
                        {
                            $link = $sheet.Hyperlinks.Add(
                            $sheet.Cells.Item($svcRow,14),
                            "",
                            $result,
                            $service.value,
                            $service.name)  
                            # $svcRow++ # Increment Rows
                        }
                    }
                    $svcRow++
                }
            }

            ###### AppliedTo ######
            $appRow = $row

            foreach($appliedTo in $rule.appliedToList.appliedTo){
                $sheet.Cells.Item($appRow,18) = $appliedTo.name
                $appRow++
            }
            $row = ($srcRow,$dstRow,$svcRow,$appRow | Measure-Object -Maximum).Maximum
        }
        $row++
        $sheet.Cells.Item($row,1).Interior.ColorIndex = $titleInteriorColor
        $range1 = $sheet.Range("a"+$row, "s"+$row)
        $range1.merge() | Out-Null
        $row++

    }
}

########################################################
#    Security Groups
########################################################

function sg_ws($sheet){

    $sheet.Cells.Item(1,1) = "Security Group Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "j1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Scope"
    $sheet.Cells.Item(2,3) = "Universal"
    $sheet.Cells.Item(2,4) = "Inheritance Allowed"
    $sheet.Cells.Item(2,5) = "Group Type (Dynamic/Static)"
    $sheet.Cells.Item(2,6) = "Dynamic Query Key Value"
    $sheet.Cells.Item(2,7) = "Dynamic Query Operator"
    $sheet.Cells.Item(2,8) = "Dynamic Query Criteria"
    $sheet.Cells.Item(2,9) = "Dynamic Query Value"
    $sheet.Cells.Item(2,10) = "Object-ID"
    $range2 = $sheet.Range("a2", "j2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_sg_ws($sheet)
}

function pop_sg_ws($sheet){

    $row = 3
    $sg = Get-NSXSecurityGroup -scopeID 'globalroot-0'
    foreach ($member in $sg){
        try 
        {
            $link_ref = "Security_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($secgrp_ht.ContainsKey($member.objectID) -eq $false)
            {
                $secgrp_ht.Add($member.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $member.objectID + "already exists, manually create hyperlink reference"
        }

        if($member.dynamicMemberDefinition){

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"

            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                $sheet.Cells.Item($row,6) = $entity.key
                $sheet.Cells.Item($row,7) = $entity.operator
                $sheet.Cells.Item($row,8) = $entity.criteria
                $sheet.Cells.Item($row,9) = $entity.value
                $row++
            }
        }
        else{
            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Static"
            $row++
        }
    }
    $sgu = Get-NSXSecurityGroup -scopeID 'universalroot-0'
    foreach ($member in $sgu){
        try 
        {
            $link_ref = "Security_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($secgrp_ht.ContainsKey($member.objectID) -eq $false)
            {
                $secgrp_ht.Add($member.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $member.objectID + "already exists, manually create hyperlink reference"
        }
        if($member.dynamicMemberDefinition){

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"

            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                $sheet.Cells.Item($row,6) = $entity.key
                $sheet.Cells.Item($row,7) = $entity.operator
                $sheet.Cells.Item($row,8) = $entity.criteria
                $sheet.Cells.Item($row,9) = $entity.value
                $row++
            }
        }
        else{
            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Static"
            $row++
        }
    }

    $sheet.Cells.Item($row,1) = "Security Group Membership"
    $sheet.Cells.Item($row,1).Font.Size = $titleFontSize
    $sheet.Cells.Item($row,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item($row,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item($row,1).Font.Name = $titleFontName
    $sheet.Cells.Item($row,1).Interior.ColorIndex = $titleInteriorColor
    $range2 = $sheet.Range("a"+$row, "j"+$row)
    $range2.merge() | Out-Null

    $row++

    $sheet.Cells.Item($row,1) = "SG Name"
    $sheet.Cells.Item($row,2) = "VM ID"
    $sheet.Cells.Item($row,3) = "VM Name"
    $range3 = $sheet.Range("a"+$row, "c"+$row)
    $range3.Font.Bold = $subTitleFontBold
    $range3.Interior.ColorIndex = $subTitleInteriorColor
    $range3.Font.Name = $subTitleFontName

    $row++


    if ($collect_vm_members -eq "y") {
        Write-Host "Collection of VM Sec Membership Enabled"
        
        foreach ($member in $sg){

            $members = $member | Get-NSXSecurityGroupEffectiveMember

            $sheet.Cells.Item($row,1) = $member.name

            foreach ($vm in $members.virtualmachine.vmnode)
            {
                $sheet.Cells.Item($row,2) = $vm.vmID
                $sheet.Cells.Item($row,3) = $vm.vmName

                $result = $vmaddressing_ht[$vm.vmID]        
                if([string]::IsNullOrWhiteSpace($result))
                {
                     $sheet.Cells.Item($row,3) = $vm.vmName
                }
                else 
                {
                    $link = $sheet.Hyperlinks.Add(
                    $sheet.Cells.Item($row,3),
                    "",
                    $result,
                    "Virtual Machine Information",
                    $vm.vmName)          
                }
                $row++
            }
        }
    }
    else {
        Write-Host "Collection of VM Sec Membership Disabled"
        $sheet.Cells.Item($row,2) = "<Collection Disabled>"
        $sheet.Cells.Item($row,2).Font.ColorIndex = 3
        $sheet.Cells.Item($row,3) = "<Collection Disabled>"
        $sheet.Cells.Item($row,3).Font.ColorIndex = 3
    }
} 

########################################################
#    Environment Summary
########################################################

function env_ws($sheet){

    $sheet.Cells.Item(1,1) = "NSX Environment Summary"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "j1")
    $range1.merge() | Out-Null

    $sys_sum = Get-NsxManagerSystemSummary
    $ssoconfig = Get-NsxManagerSsoConfig
    $vcconfig = Get-NsxManagerVcenterConfig
    $ver = Get-PowerNSXVersion

    $sheet.Cells.Item(2,1) = "PowerNSX version"
    $sheet.Cells.Item(2,2) = $ver.version.toString()

    $sheet.Cells.Item(3,1) = "NSX Manager Name"
    $sheet.Cells.Item(3,2) = $sys_sum.hostName
    
    $sheet.Cells.Item(4,1) = "IPv4 Address"
    $sheet.Cells.Item(4,2) = $sys_sum.Ipv4Address

    $sheet.Cells.Item(5,1) = "SSO Lookup URL"
    $sheet.Cells.Item(5,2) = $ssoconfig.ssoLookupServiceUrl    

    $sheet.Cells.Item(6,1) = "SSO User Account"
    $sheet.Cells.Item(6,2) = $ssoconfig.ssoAdminUsername
    
    $sheet.Cells.Item(7,1) = "vCenter Mapping"
    $sheet.Cells.Item(7,2) = $vcconfig.ipAddress

    $sheet.Cells.Item(8,1) = "NSX Manager Version"
    $sheet.Cells.Item(8,2) = ($sys_sum.versionInfo.majorVersion + "." `
                             + $sys_sum.versionInfo.minorVersion + "." `
                             + $sys_sum.versionInfo.patchVersion + "." `
                             + $sys_sum.versionInfo.buildNumber)
    
    $sheet.Cells.Item(9,1) = "Security Group Membership Statistics"
    $sheet.Cells.Item(9,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(9,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(9,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(9,1).Font.Name = $titleFontName
    $sheet.Cells.Item(9,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a9", "j9")
    $range1.merge() | Out-Null
    
    $sheet.Cells.Item(10,1) = "Security Group Name"
    $sheet.Cells.Item(10,2) = "Translated VMs"
    $sheet.Cells.Item(10,3) = "Translated IPs"
    $range2 = $sheet.Range("a10", "c10")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_env_ws($sheet)
}

function pop_env_ws($sheet){

    $row = 11

    ### Security Group Membership statistics

    $sg = Get-NSXSecurityGroup

    foreach($item in $sg){

        $sheet.Cells.Item($row,1) = $item.name

        $url_vms = "/api/2.0/services/securitygroup/" + $item.objectid + `
                   "/translation/virtualmachines"
        $url_ips = "/api/2.0/services/securitygroup/" + $item.objectid + `
                   "/translation/ipaddresses"
        
        $sec_vm_stats = Invoke-NsxRestMethod -method get -uri $url_vms
        $sheet.Cells.Item($row,2) = $sec_vm_stats.vmnodes.vmnode.Length 

        $sec_ip_stats = Invoke-NsxRestMethod -method get -uri $url_ips
        $sheet.Cells.Item($row,3) = $sec_ip_stats.ipNodes.ipNode.ipAddresses.Length

        $row ++
    }
}

########################################################
#    IPSETS Worksheet
########################################################

function ipset_ws($sheet){

    $sheet.Cells.Item(1,1) = "IPSET Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "d1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Value"
    $sheet.Cells.Item(2,3) = "Universal"
    $sheet.Cells.Item(2,4) = "Object-ID"
    $sheet.Cells.Item(2,5) = "Description"
    $range2 = $sheet.Range("a2", "e2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_ipset_ws($sheet)
}

function pop_ipset_ws($sheet){

    $row=3
    $ipset = get-nsxipset -scopeID 'globalroot-0'

    foreach ($ip in $ipset) {

        $sheet.Cells.Item($row,1) = $ip.name
        $sheet.Cells.Item($row,2) = $ip.value
        $sheet.Cells.Item($row,3) = $ip.isUniversal
        $sheet.Cells.Item($row,4) = $ip.objectId
        try 
        {
            $link_ref = "IPSETS!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($ipsets_ht.ContainsKey($ip.objectID) -eq $false)
            {
                $ipsets_ht.Add($ip.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $ip.objectID + "already exists, manually create hyperlink reference"
        }
        if(!$ip.description){
            $sheet.Cells.Item($row,5) = $valueNotDefined
        }
        else {$sheet.Cells.Item($row,5) = $ip.description}

        $row++ # Increment Rows
    }

    $ipset_unv = get-nsxipset -scopeID 'universalroot-0'

    foreach ($ip in $ipset_unv) {

        $sheet.Cells.Item($row,1) = $ip.name
        $sheet.Cells.Item($row,2) = $ip.value
        $sheet.Cells.Item($row,3) = $ip.isUniversal
        $sheet.Cells.Item($row,4) = $ip.objectId
        try 
        {
            $link_ref = "IPSETS!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($ipsets_ht.ContainsKey($ip.objectID) -eq $false)
            {
                $ipsets_ht.Add($ip.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $ip.objectID + "already exists, manually create hyperlink reference"
        }

        if(!$ip.description){
            $sheet.Cells.Item($row,5) = $valueNotDefined
        }
        else {$sheet.Cells.Item($row,5) = $ip.description}
        $row++ # Increment Rows
    }
}

########################################################
#    MACSETS Worksheet
########################################################

function macset_ws($sheet){

    $sheet.Cells.Item(1,1) = "MACSET Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "e1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Value"
    $sheet.Cells.Item(2,3) = "Description"
    $range2 = $sheet.Range("a2", "c2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_macset_ws($sheet)
}

function pop_macset_ws($sheet){

    # Grab MACSets and populate
    $row=3
    $macset = get-nsxmacset
    foreach ($mac in $macset) {

        $sheet.Cells.Item($row,1) = $mac.name
        $sheet.Cells.Item($row,2) = $mac.value
        if(!$mac.description){
            $sheet.Cells.Item($row,3) = $valueNotDefined
        }
        else {$sheet.Cells.Item($row,3) = $mac.description}

        $row++ # Increment Rows
    }
}

########################################################
#    Services Worksheet
########################################################

function services_ws($sheet){

    $sheet.Cells.Item(1,1) = "DFW Services Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Type"
    $sheet.Cells.Item(2,3) = "Application Protocol"
    $sheet.Cells.Item(2,4) = "Value"
    $sheet.Cells.Item(2,5) = "Universal"
    $sheet.Cells.Item(2,6) = "Object-ID"
    $range2 = $sheet.Range("a2", "f2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_services_ws($sheet)
}

function pop_services_ws($sheet){

    # Grab Services and populate
    $row=3
    $services = get-nsxservice -scopeID 'globalroot-0'
    foreach ($svc in $services) {

        $sheet.Cells.Item($row,1) = $svc.name
        $sheet.Cells.Item($row,2) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        $sheet.Cells.Item($row,5) = $svc.isUniversal
        $sheet.Cells.Item($row,6) = $svc.objectID
        try 
        {
            $link_ref = "Services!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc.objectID) -eq $false)
            {
                $services_ht.Add($svc.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc.objectID + "already exists, manually create hyperlink reference"
        }
      
        $row++ # Increment Rows
    }

    $services_unv = get-nsxservice -scopeID 'universalroot-0'
    foreach ($svc in $services_unv) {

        $sheet.Cells.Item($row,1) = $svc.name
        $sheet.Cells.Item($row,2) = $svc.type.typeName
        $sheet.Cells.Item($row,3) = $svc.element.applicationProtocol
        $sheet.Cells.Item($row,4).NumberFormat = "@"
        $sheet.Cells.Item($row,4) = $svc.element.value
        $sheet.Cells.Item($row,5) = $svc.isUniversal
        $sheet.Cells.Item($row,6) = $svc.objectID
        try 
        {
            $link_ref = "Services!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc.objectID) -eq $false)
            {
                $services_ht.Add($svc.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc.objectID + "already exists, manually create hyperlink reference"
        }
      
        $row++ # Increment Rows
    }
}

########################################################
#    Service Groups Worksheet
########################################################

function service_groups_ws($sheet){

    $sheet.Cells.Item(1,1) = "Service Group Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Service Group Name"
    $sheet.Cells.Item(2,2) = "Universal"
    $sheet.Cells.Item(2,3) = "Scope"
    $sheet.Cells.Item(2,4) = "Service Members"
    $sheet.Cells.Item(2,5) = "Object-ID"
    $range2 = $sheet.Range("a2", "e2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_service_groups_ws($sheet)
}

function pop_service_groups_ws($sheet){

    $row=3
    $SG = Get-NSXServiceGroup -scopeID 'globalroot-0'

    foreach ($svc_mem in $SG) 
    {
        $sheet.Cells.Item($row,1) = $svc_mem.name
        $sheet.Cells.Item($row,1).Font.Bold = $true
        $sheet.Cells.Item($row,2) = $svc_mem.isUniversal
        $sheet.Cells.Item($row,3) = $svc_mem.scope.name
        $sheet.Cells.Item($row,5) = $svc_mem.objectId
       
        try 
        {
            $link_ref = "Service_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc_mem.objectID) -eq $false)
            {
                $services_ht.Add($svc_mem.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc_mem.objectID + "already exists, manually create hyperlink reference"
        }

        if (!$svc_mem.member)
        {
            $row++ # Increment Rows
        }
        else
        {
            foreach ($member in $svc_mem.member)
            {
                $result = $services_ht[$member.objectid]        
                if([string]::IsNullOrWhiteSpace($result))
                {
                     $sheet.Cells.Item($row,4) = $member.name
                     $row++ # Increment Rows
                }
                else 
                {
                    $link = $sheet.Hyperlinks.Add(
                    $sheet.Cells.Item($row,4),
                    "",
                    $result,
                    $member.objectid,
                    $member.name)  
                    $row++ # Increment Rows
                }
            }
        }
    }

    $SGU = Get-NSXServiceGroup -scopeID 'universalroot-0'

    foreach ($svc_mem in $SGU) 
    {
        $sheet.Cells.Item($row,1) = $svc_mem.name
        $sheet.Cells.Item($row,1).Font.Bold = $true
        $sheet.Cells.Item($row,2) = $svc_mem.isUniversal
        $sheet.Cells.Item($row,3) = $svc_mem.scope.name
        $sheet.Cells.Item($row,5) = $svc_mem.objectId
        
        try 
        {
            $link_ref = "Service_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($services_ht.ContainsKey($svc_mem.objectID) -eq $false)
            {
                $services_ht.Add($svc_mem.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $svc_mem.objectID + "already exists, manually create hyperlink reference"
        }

        if (!$svc_mem.member) 
        {
                $row++ # Increment Rows
        }
        else 
        {
            foreach ($member in $svc_mem.member)
            {
                $result = $services_ht[$member.objectid]        
                if([string]::IsNullOrWhiteSpace($result))
                {
                     $sheet.Cells.Item($row,4) = $member.name
                     $row++ # Increment Rows
                }
                else 
                {
                    $link = $sheet.Hyperlinks.Add(
                    $sheet.Cells.Item($row,4),
                    "",
                    $result,
                    $member.objectid,
                    $member.name)  
                    $row++ # Increment Rows
                }
            }
        }
    }
}

########################################################
#    Security Tag Worksheet
########################################################

function sec_tags_ws($sheet){

    $sheet.Cells.Item(1,1) = "Security Tag Configuration"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "Security Tag Name"
    $sheet.Cells.Item(2,2) = "Built-In"
    $sheet.Cells.Item(2,3) = "VM Members"
    $sheet.Cells.Item(2,4) = "Is Universal"
    $range2 = $sheet.Range("a2", "d2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_sec_tags_ws($sheet)
}

function pop_sec_tags_ws($sheet){
    
    $row=3
    $ST = get-nsxsecuritytag -includesystem

    foreach ($tag in $ST) {
        $sheet.Cells.Item($row,1) = $tag.name
        $sheet.Cells.Item($row,2) = $tag.systemResource
        $sheet.Cells.Item($row,3) = $tag.vmCount
        $sheet.Cells.Item($row,4) = $tag.isUniversal
        $row++ # Increment Rows
    }

    $sheet.Cells.Item($row,1) = "Security Tag Name"
    $sheet.Cells.Item($row,2) = "VM Name"
    $range3 = $sheet.Range("a"+$row, "b"+$row)
    $range3.Font.Bold = $subTitleFontBold
    $range3.Interior.ColorIndex = $subTitleInteriorColor
    $range3.Font.Name = $subTitleFontName

    $row ++

    # Traverse VM membership and populate spreadsheet
    if ($collect_vm_stag_members -eq "y") {
        
        # Retrieve a list of all Tag Assignments
        $tag_assign = $ST | Get-NsxSecurityTagAssignment        
        
        foreach ($mem in $tag_assign){

            $sheet.Cells.Item($row,1) = $mem.SecurityTag.name
            $sheet.Cells.Item($row,2) = $mem.VirtualMachine.name
            $row++
        }
    }
    else {
        $sheet.Cells.Item($row,1) = "<Collection Disabled>"
        $sheet.Cells.Item($row,1).Font.ColorIndex = 3
        $sheet.Cells.Item($row,2) = "<Collection Disabled>"
        $sheet.Cells.Item($row,2).Font.ColorIndex = 3
    }
}

########################################################
#    Exclusion list Worksheet
########################################################

function ex_list_ws($sheet){

    $sheet.Cells.Item(1,1) = "Exclusion List"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "VM Name"
    $sheet.Cells.Item(2,2) = "VM ID"
    $range2 = $sheet.Range("a2", "b2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_ex_list_ws($sheet)
}

function pop_ex_list_ws($sheet){

    $row=3
    $guests = Get-NsxFirewallExclusionListMember

    foreach ($vm in $guests) {
        # $sheet.Cells.Item($row,1) = $vm.name
        $result = $vmaddressing_ht[$vm.id.TrimStart("VirtualMachine-")]        
        if([string]::IsNullOrWhiteSpace($result))
        {
             $sheet.Cells.Item($row,1) = $vm.name
             $sheet.Cells.Item($row,2) = $vm.id.TrimStart("VirtualMachine-")
        }
        else 
        {
            $link = $sheet.Hyperlinks.Add(
            $sheet.Cells.Item($row,1),
            "",
            $result,
            "Virtual Machine Information",
            $vm.name)
            $sheet.Cells.Item($row,2) = $vm.id.TrimStart("VirtualMachine-")
        }
        $row++ # Increment Rows
    }
}

########################################################
#    VM Addressing - First NIC IP Address
########################################################

function vm_ip_addresses_ws($sheet){

    $sheet.Cells.Item(1,1) = "Virtual Machine Addressing"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "f1")
    $range1.merge() | Out-Null

    $sheet.Cells.Item(2,1) = "VM Name"
    $sheet.Cells.Item(2,2) = "Guest IP Address"
    $sheet.Cells.Item(2,3) = "VM ID"
    $range2 = $sheet.Range("a2", "c2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName
    pop_ip_address_ws($sheet)
}

function pop_ip_address_ws($sheet){

    $row=3
    $guests = Get-VM | Select Name, VMIPAddress, id

    foreach ($vm in $guests) {
        $sheet.Cells.Item($row,1) = $vm.name
        $sheet.Cells.Item($row,2) = $vm.VMIPAddress
        $vm_id = $vm.id.TrimStart("VirtualMachine-")
        $sheet.Cells.Item($row,3) = $vm_id
        try 
        {
            $link_ref = "VM_Info!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($vmaddressing_ht.ContainsKey($vm_id) -eq $false)
            {
                $vmaddressing_ht.Add($vm_id, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning "already exists, manually create hyperlink reference"
        }

        $row++ # Increment Rows
    }
}

########################################################
#    Global Functions
########################################################

If (-not $DefaultNSXConnection) 
{
    Write-Warning "`nConnect to NSX Manager established"
    $nsx_mgr = Read-Host "`nIP or FQDN of NSX Manager? "
    Connect-NSXServer -NSXServer $nsx_mgr
}

$version = Get-NsxManagerSystemSummary
$major_version = $version.versionInfo.majorVersion

# Only tested to run on NSX 6.2.x & 6.3.x installations

if($major_version -eq 6){

    if ( $EnableIpDetection ) {
        $collect_vm_ips = "y"
        Write-Host "Collection of IP Addresses Enabled"
    } 
    elseif (-not $PSBoundParameters.ContainsKey("EnableIpDetection")) { 
        $collect_vm_ips = "n"
        Write-Warning "Collection of IP Addresses Disabled"
    }

    if ( $GetSecTagMembers ) {
        $collect_vm_stag_members= "y"
        Write-Host "Collection of Security Tag VM Membership Enabled"
    } 
    elseif (-not $PSBoundParameters.ContainsKey("GetSecTagMembers")) { 
        $collect_vm_stag_members = "n"
        Write-Warning "Collection of Security Tag VM Membership Disabled"
    }

    if ( $GetSecGrpMembers ) {
        $collect_vm_members = "y"
        Write-Host "Collection of Security Group VM Membership Enabled"
    } 
    elseif (-not $PSBoundParameters.ContainsKey("GetSecGrpMembers")) { 
        $collect_vm_members = "n"
        Write-Warning "Collection of Security Group VM Membership Disabled"
    }

    if ($collect_vm_ips -eq "y") {
        # Write-Host "Collection of IP Addresses Enabled"
        startExcel("y")
    }
    else{
        # Write-Warning "Collection of IP Addresses Disabled"
        startExcel("n")
    }
}
else{
        Write-Warning "`nNSX Manager version is not in the NSX 6.x release train"
}