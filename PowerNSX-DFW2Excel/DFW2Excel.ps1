# Author:   Tony Sangha
# Updates:  Dave Moslander
# Blog:    tonysangha.com
# Version:  1.0.2
# PowerCLI v6.0
# PowerNSX v3.0
# Purpose: Document NSX for vSphere Distributed Firewall

param (
    [switch]$ShowProgress,
    [switch]$OneLine,
    [switch]$Quoted,
    [switch]$AddTables,
    [switch]$Logoff,
    [switch]$EnableIpDetection,
    [switch]$GetSecTagMembers,
    [switch]$GetSecGrpMembers,
    [switch]$GetSecGrpStats,
    [switch]$StartMinimised,
    [string]$DocumentPath
)

# Import PowerNSX Module
import-module PowerNSX

# Import PowerCLI modules, PowerCLI must be installed
if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
    if (Test-Path -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\VMware, Inc.\VMware vSphere PowerCLI' ) {
        $Regkey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\VMware, Inc.\VMware vSphere PowerCLI'

    } else {
        $Regkey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.\VMware vSphere PowerCLI'
    }
    . (join-path -path (Get-ItemProperty  $Regkey).InstallPath -childpath 'Scripts\Initialize-PowerCLIEnvironment.ps1')
}
if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
    Write-Host "VMware modules not loaded/unable to load"
    Exit 99
}

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
#  Formatting/Functions Options for Excel Spreadsheet
########################################################

    $titleFontSize = 18
    $titleFontBold = $True
    $titleFontName = "Calibri (Body)"
    $titleFontColorIndex = 6
    $titleInteriorColor = 16

    $subTitleFontSize = 10.5
    $subTitleFontBold = $True
    $subTitleFontName = "Calibri (Body)"
    $subTitleInteriorColor = 15

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

New-VIProperty -Name VMIPAddress -ObjectType VirtualMachine `
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
        $wsVMIpaddrs = $wb.WorkSheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
        $wsVMIpaddrs.Name = "VM_Info"
        vm_ip_addresses_ws($wsVMIpaddrs)
        $usedRange = $wsVMIpaddrs.UsedRange
        $usedRange.EntireColumn.Autofit()
    }

    Write-Host "`nRetrieving Services configured in NSX-v." -foregroundcolor "magenta"
    $wsServices = $wb.WorkSheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    $wsServices.Name = "Services"
    services_ws($wsServices)
    $wsServices.Cells.Item(3,2).Select() > $null
    $wsServices.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsServices.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    Write-Host "`nRetrieving Service Groups configured in NSX-v." -foregroundcolor "magenta"
    $wsSrvGrp = $wb.WorkSheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    $wsSrvGrp.Name = "Service_Groups"
    service_groups_ws($wsSrvGrp)
    $wsSrvGrp.Cells.Item(3,2).Select() > $null
    $wsSrvGrp.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsSrvGrp.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    Write-Host "`nRetrieving MACSETS configured in NSX-v." -foregroundcolor "magenta"
    $wsMacSets = $wb.WorkSheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    $wsMacSets.Name = "MACSETS"
    macset_ws($wsMacSets)
    $wsMacSets.Cells.Item(3,2).Select() > $null
    $wsMacSets.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsMacSets.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    Write-Host "`nRetrieving IPSETS configured in NSX-v." -foregroundcolor "magenta"
    $wsIpSets = $wb.WorkSheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    $wsIpSets.Name = "IPSETS"
    ipset_ws($wsIpSets)
    $wsIpSets.Cells.Item(3,2).Select() > $null
    $wsIpSets.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsIpSets.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    Write-Host "`nRetrieving Security Groups configured in NSX-v." -foregroundcolor "magenta"
    $wsSecGrp = $wb.WorkSheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    $wsSecGrp.Name = "Security_Groups"
    sg_ws($wsSecGrp)
    $wsSecGrp.Cells.Item(3,2).Select() > $null
    $wsSecGrp.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsSecGrp.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    if ($GetSecGrpMembers){
        Write-Host "`nRetrieving Security Group Members.  " -foregroundcolor "magenta"
        Write-Warning "This can take some time."
        $wsSecGrpMbrs = $wb.WorkSheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
        $wsSecGrpMbrs.Name = "Security Group Members"
        sgm_ws($wsSecGrpMbrs)
        $wsSecGrpMbrs.Cells.Item(3,2).Select() > $null
        $wsSecGrpMbrs.application.ActiveWindow.FreezePanes = $True
        $usedRange = $wsSecGrpMbrs.UsedRange
        $usedRange.EntireColumn.Autofit() > $null
    }

    if ($GetSecGrpStats){
        Write-Host "`nRetrieving Security Group Membership Statistics  " -foregroundcolor "magenta"
        Write-Warning "This can take some time."
        $wsSecGrpMbrStat = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
        $wsSecGrpMbrStat.Name = "Security Group Stats"
        sg_members_ws($wsSecGrpMbrStat)
        $wsSecGrpMbrStat.Cells.Item(3,2).Select() > $null
        $wsSecGrpMbrStat.application.ActiveWindow.FreezePanes = $True
        $usedRange = $wsSecGrpMbrStat.UsedRange
        $usedRange.EntireColumn.Autofit() > $null
    }

    Write-Host "`nRetrieving Security Tags configured in NSX-v." -foregroundcolor "magenta"
    $wsSecTags = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    $wsSecTags.Name = "Security Tags"
    sec_tags_ws($wsSecTags)
    $wsSecTags.Cells.Item(3,2).Select() > $null
    $wsSecTags.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsSecTags.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    if ($GetSecTagMembers){
        Write-Host "`nRetrieving Security Tag Members.  " -foregroundcolor "magenta"
        Write-Warning "This can take some time."
        $wsSecTagMbrs = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
        $wsSecTagMbrs.Name = "Security Tag Members"
        sec_tags_mem_ws($wsSecTagMbrs)
        $wsSecTagMbrs.Cells.Item(3,2).Select() > $null
        $wsSecTagMbrs.application.ActiveWindow.FreezePanes = $True
        $usedRange = $wsSecTagMbrs.UsedRange
        $usedRange.EntireColumn.Autofit() > $null
    }

    Write-Host "`nRetrieving VMs in DFW Exclusion List" -foregroundcolor "magenta"
    $wsDfwExl = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item($wb.Worksheets.Count))
    $wsDfwExl.Name = "DFW Exclusion list"
    ex_list_ws($wsDfwExl)
    $wsDfwExl.Cells.Item(3,2).Select() > $null
    $wsDfwExl.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsDfwExl.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    Write-Host "`nRetrieving DFW Layer 3 FW Rules" -foregroundcolor "magenta"
    $wsDfwL3Rules = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item(1))
    $wsDfwL3Rules.Name = "Layer 3 Firewall"
    dfw_ws($wsDfwL3Rules)
    $wsDfwL3Rules.Cells.Item(4,2).Select() > $null
    $wsDfwL3Rules.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsDfwL3Rules.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    Write-Host "`nRetrieving Environment Summary" -foregroundcolor "magenta"
    $wsEnvSum = $wb.Worksheets.Add([System.Reflection.Missing]::Value, $wb.Worksheets.Item(1))
    $wsEnvSum.Name = "Environment Summary"
    env_ws($wsEnvSum)
    $wsEnvSum.Cells.Item(3,2).Select() > $null
    $wsEnvSum.application.ActiveWindow.FreezePanes = $True
    $usedRange = $wsEnvSum.UsedRange
    $usedRange.EntireColumn.Autofit() > $null

    # Must cleanup manually or excel process wont quit.
    $wb.Worksheets.Item("Sheet1").Delete()
    ReleaseObject -Obj $wsServices
    ReleaseObject -Obj $wsSrvGrp
    ReleaseObject -Obj $wsMacSets
    ReleaseObject -Obj $wsIpSets
    ReleaseObject -Obj $wsSecGrp
    ReleaseObject -Obj $wsSecTags
    ReleaseObject -Obj $wsDfwExl
    ReleaseObject -Obj $wsDfwL3Rules
    ReleaseObject -Obj $wsEnvSum
    if ($GetSecGrpMembers){
        ReleaseObject -Obj $wsSecGrpMbrs
    }
    if ($GetSecGrpStats){
        ReleaseObject -Obj $wsSecGrpMbrStat
    }
    if ($GetSecTagMembers){
        ReleaseObject -Obj $wsSecTagMbrs
    }
    ReleaseObject -Obj $usedRange

    if ( $DocumentPath -and (test-path (split-path -parent $DocumentPath))) { 
        $wb.SaveAs($DocumentPath)
        $wb.close(0)
        $Excel.Quit()
        ReleaseObject -Obj $Excel
        ReleaseObject -Obj $wb
    }

    #Close vCenter & NSX Mgr connections
    if ($Logoff) {
        $tnsxmgr = ""
        $tvcsrv = ""
        $vccfg = Get-NsxManagerVcenterConfig
        $tvcsrv = $vccfg.ipAddress
        $tvcsrvsz = $tvcsrv.split(".").getupperbound(0)
        if ($tvcsrv -match "^[0-9]"){
            $tvcsrv = $vccfg.ipAddress
        }
        elseif ($tvcsrv.split(".").getupperbound(0) -gt 0) {
            $tvcsrv = $vccfg.ipAddress.split(".")[0]        
        }
#        $nsxmgr = Get-NsxManagerSystemSummary
#        $tnsxmgr = $nsxmgr.hostName
#        $tnsxmgrsz = $tnsxmgr.split(".").getupperbound(0)
#        if ($tnsxmgr -match "^[0-9]"){
#            $tnsxmgr = $nsxmgr
#        }
#        elseif ($tnsxmgr.split(".").getupperbound(0) -gt 0) {
#            $tnsxmgr = $nsxmgr.split(".")[0]
#        }
        Write-Host "`n`nDisconnecting from vCenter " -NoNewline -ForegroundColor "magenta"
        Write-Host "$tvcsrv" -NoNewline -BackgroundColor "black" -ForegroundColor "yellow"
        Write-Host " & NSX Manager " -NoNewline -ForegroundColor "magenta"
        if ($tnsxmgr){
            Write-Host "$tnsxmgr`n" -NoNewline -BackgroundColor "black" -ForegroundColor "yellow"
        }
        Disconnect-VIServer -Confirm:$false
        Disconnect-NsxServer
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
    $range1.merge() > $null

    l3_rules($sheet)

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function l3_rules($sheet){

    $sheet.Cells.Item(2,1) = "Layer 3 Rules"
    $sheet.Cells.Item(2,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(2,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(2,1).Font.Name = $titleFontName
    $sheet.Cells.Item(2,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a2", "s2")
    $range1.Interior.ColorIndex = $titleInteriorColor

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

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving L3 Firewall Rules and Information, Please wait..."
    }

    $fw_sections = Get-NSXFirewallSection

    $envstatL3fwGl = ($fw_sections | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatL3fwGl
        $prgsCnt = 1
    }

    $sheet.Cells.Item(2,1) = "$prgsNum Layer 3 Rules"
    $row = 4

    foreach($section in $fw_sections){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding L3 FW Rules & Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt++
        }

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
        $sheet.Rows($row).RowHeight = 3
        $sheet.Range("a"+$row, "s"+$row).Interior.ColorIndex = $titleInteriorColor
#        $range1 = $sheet.Range("a"+$row, "s"+$row)
#        $range1.Interior.ColorIndex = $titleInteriorColor
#        $range1.merge() > $null
        $row++
    }
    $sheet.Cells.Item(1,27) = $envstatL3fwGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
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

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Scope"
    $sheet.Cells.Item(2,3) = "Universal"
    $sheet.Cells.Item(2,4) = "Inheritance Allowed"
    $sheet.Cells.Item(2,5) = "Group Type (Dynamic/Static)"
    if ($OneLine){
        $sheet.Cells.Item(2,6) = "# Conditions"
        $sheet.Cells.Item(2,7) = "Conditional Value(s)"
        $sheet.Cells.Item(2,8) = "Object-ID"
        $oidCol = 8
        $range1 = $sheet.Range("a1", "h1")
        $range1.merge() > $null
        $range2 = $sheet.Range("a2", "h2")
    }
    else{
        $sheet.Cells.Item(2,6) = "Dynamic Query Key Value"
        $sheet.Cells.Item(2,7) = "Dynamic Query Operator"
        $sheet.Cells.Item(2,8) = "Dynamic Query Criteria"
        $sheet.Cells.Item(2,9) = "Dynamic Query Value"
        $sheet.Cells.Item(2,10) = "Object-ID"
        $oidCol = 10
        $range1 = $sheet.Range("a1", "j1")
        $range1.merge() > $null
        $range2 = $sheet.Range("a2", "j2")
    }
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    pop_sg_ws($sheet)

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_sg_ws($sheet){

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Security Group Information, Please wait..."
    }
    if ($Quoted){
        $addDelimiter = """"
    }
    else{
        $addDelimiter = ""
    }

    $row = 3
    $sg = Get-NSXSecurityGroup -scopeID 'globalroot-0'

    $envstatSecGrpGl = ($sg | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSecGrpGl
        $prgsCnt = 1
    }

    foreach ($member in $sg){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Security Group Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }

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
            $sheet.Cells.Item($row,$oidCol) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"
            $queryCond = ""
            $queryNumber = ($member.dynamicMemberDefinition.dynamicSet.dynamicCriteria | measure).count
            $queryCount = 1
            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                if ($OneLine){
                    if ($queryCount -eq 1){
                        $queryCond = $addDelimiter + $entity.key
                    }
                    else{
                        $queryCond = $queryCond + ", " + $addDelimiter + $entity.key
                    }
                    switch ($entity.criteria){
                        "belongs_to" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "contains" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "ends_with" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "equals_to" {$queryCond = $queryCond + "="}
                        "not_equals_to" {$queryCond = $queryCond + "<>"}
                        "starts_with" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "matches_regular_expression" {$queryCond = $queryCond + "=ReX" + $entity.criteria}
                        Default {$queryCond = $queryCond + $entity.criteria}
                    }
                    $queryCond = $queryCond + $entity.value + "_" + $entity.operator + $addDelimiter
                    $queryCount++
                }
                else{
                    $sheet.Cells.Item($row,6) = $entity.key
                    $sheet.Cells.Item($row,7) = $entity.operator
                    $sheet.Cells.Item($row,8) = $entity.criteria
                    $sheet.Cells.Item($row,9) = $entity.value
                    $row++
                }
            }
            if ($OneLine){
                $sheet.Cells.Item($row,6) = $queryNumber
                $sheet.Cells.Item($row,7) = $queryCond
                $row++
            }
        }
        else{
            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,$oidCol) = $member.objectId
            $sheet.Cells.Item($row,5) = "Static"
            $memList = ""
            $memNumber = ($member.member.objectId | measure).count
            $memCount = 1
            $sheet.Cells.Item($row,6) = $memNumber
            foreach ($memEntry in $member.member){
                if ($OneLine){
                    if ($memCount -eq 1){
                        $memList =  $addDelimiter + $memEntry.objecttypename + "=" + $memEntry.name + $addDelimiter
                    }
                    else{
                        $memList = $memList + ", " + $addDelimiter + $memEntry.objecttypename + "=" + $memEntry.name + $addDelimiter
                    }
                    $memCount++
                }
                else{
                    $sheet.Cells.Item($row,6) = $memEntry.objectTypeName
                    $sheet.Cells.Item($row,7) = "="
                    $sheet.Cells.Item($row,9) = $memEntry.name
                    $row++
                }
            }
            if ($OneLine){
                $sheet.Cells.Item($row,6) = $memNumber
                $sheet.Cells.Item($row,7) = $memList
            }
            $row++
        }
    }

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Universal Security Group Information, Please wait..."
    }

    $sgu = Get-NSXSecurityGroup -scopeID 'universalroot-0'

    $envstatSecGrpUn = ($sgu | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSecGrpUn
        $prgsCnt = 1
    }

    foreach ($member in $sgu){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Universal Security Group Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }

        try{
            $link_ref = "Security_Groups!" + ($sheet.Cells.Item($row,1)).address($false,$false)
            if($secgrp_ht.ContainsKey($member.objectID) -eq $false){
                $secgrp_ht.Add($member.objectID, $link_ref)
            }
        }
        catch [Exception]{
            Write-Warning $member.objectID + "already exists, manually create hyperlink reference"
        }
        if ($member.dynamicMemberDefinition){

            $sheet.Cells.Item($row,1) = $member.name
            $sheet.Cells.Item($row,2) = $member.scope.name
            $sheet.Cells.Item($row,3) = $member.isUniversal
            $sheet.Cells.Item($row,4) = $member.inhertianceAllowed
            $sheet.Cells.Item($row,10) = $member.objectId
            $sheet.Cells.Item($row,5) = "Dynamic"

            $queryCond = ""
            $queryNumber = ($member.dynamicMemberDefinition.dynamicSet.dynamicCriteria | measure).count
            $queryCount = 1
            foreach ($entity in $member.dynamicMemberDefinition.dynamicSet.dynamicCriteria){
                if ($OneLine){
                    if ($queryCount -eq 1){
                        $queryCond =  $addDelimiter + $entity.key
                    }
                    else{
                        $queryCond = $queryCond + ", " + $addDelimiter + $entity.key
                    }
                    switch ($entity.criteria){
                        "belongs_to" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "contains" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "ends_with" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "equals_to" {$queryCond = $queryCond + "="}
                        "not_equals_to" {$queryCond = $queryCond + "<>"}
                        "starts_with" {$queryCond = $queryCond + "-" + $entity.criteria + "-"}
                        "matches_regular_expression" {$queryCond = $queryCond + "=ReX" + $entity.criteria}
                        Default {$queryCond = $queryCond + $entity.criteria}
                    }
                    $queryCond = $queryCond + $entity.value + "_" + $entity.operator + $addDelimiter
                    $queryCount++
                }
                else{
                    $sheet.Cells.Item($row,6) = $entity.key
                    $sheet.Cells.Item($row,7) = $entity.operator
                    $sheet.Cells.Item($row,8) = $entity.criteria
                    $sheet.Cells.Item($row,9) = $entity.value
                    $row++
                }
            }
            if ($OneLine){
                $sheet.Cells.Item($row,6) = $queryNumber
                $sheet.Cells.Item($row,7) = $queryCond
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

            $memList = ""
            $memNumber = ($member.member.objectId | measure).count
            $memCount = 1
            $sheet.Cells.Item($row,6) = $memNumber
            foreach ($memEntry in $member.member){
                if ($OneLine){
                    if ($memCount -eq 1){
                        $memList =  $addDelimiter + $memEntry.objectTypeName + "=" + $memEntry.name + $addDelimiter
                    }
                    else{
                        $memList = $memList + ", " + $addDelimiter + $memEntry.objectTypeName + "=" + $memEntry.name + $addDelimiter
                    }
                    $memCount++
                }
                else{
                    $sheet.Cells.Item($row,6) = $memEntry.objectTypeName
                    $sheet.Cells.Item($row,7) = "="
                    $sheet.Cells.Item($row,9) = $memEntry.name
                    $row++
                }
            }
            if ($OneLine){
                $sheet.Cells.Item($row,6) = $memNumber
                $sheet.Cells.Item($row,7) = $memList
            }
            $row++
        }
    }
    if ($OneLine -and $AddTables) {
        $range3 = $sheet.Range("a2", "h"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "SecGrp"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
    $sheet.Cells.Item(1,27) = $envstatSecGrpGl
    $sheet.Cells.Item(1,28).Font.ColorIndex = 2
    $sheet.Cells.Item(1,28) = $envstatSecGrpUn
}


########################################################
#    Security Group Membership
########################################################

function sgm_ws($sheet){
    
    $sheet.Cells.Item(1,1) = "Security Group Membership"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "c1")
    $range1.merge() > $null

    $sheet.Cells.Item(2,1) = "SG Name"
    $sheet.Cells.Item(2,2) = "VM ID"
    $sheet.Cells.Item(2,3) = "VM Name"
    $range2 = $sheet.Range("a2", "c2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    pop_sgm_ws($sheet)

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_sgm_ws($sheet){

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Security Group Membership Information, Please wait..."
    }

    $row = 3
    $sg = Get-NSXSecurityGroup -scopeID 'globalroot-0'

    $envstatSecGrpMbrGl = ($sg | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSecGrpMbrGl
        $prgsCnt = 1
    }

    foreach ($member in $sg){
        if ($ShowProgress){
            $sgName = $member.name
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Checking Security Group $sgName for VM Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }

        $members = $member | Get-NSXSecurityGroupEffectiveMember
        if ($ShowProgress){
            $prgsNum2 = ($members.virtualmachine.vmnode | measure).count
            $prgsCnt2 = 1
        }

        $sheet.Cells.Item($row,1) = $member.name

        foreach ($vm in $members.virtualmachine.vmnode) {
            if ($ShowProgress){
                $PercentCompleted2 = [Math]::Round(($prgsCnt2 / $prgsNum2) * 100)
                Write-Progress -Activity "Adding VMs included in Security Group $sgName" -Id 1 -Status "$prgsCnt2 of $prgsNum2 Complete:" -PercentComplete $PercentCompleted2
                $prgsCnt2 ++
            }

            if ($AddTables) {
                $sheet.Cells.Item($row,1) = $member.name
            }
            $sheet.Cells.Item($row,2) = $vm.vmID
            $sheet.Cells.Item($row,3) = $vm.vmName

            $result = $vmaddressing_ht[$vm.vmID]
            if([string]::IsNullOrWhiteSpace($result)){
                $sheet.Cells.Item($row,3) = $vm.vmName
            }
            else{
                $link = $sheet.Hyperlinks.Add($sheet.Cells.Item($row,3), "", $result, "Virtual Machine Information", $vm.vmName)
            }
            $row++
        }
        if ($ShowProgress){
            Write-Progress -Completed "Retrieved VM's within Security Group" -Id 1
        }
    }
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "c"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "SecGrpMbrs"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
    $sheet.Cells.Item(1,27) = $envstatSecGrpMbrGl
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
    $range1.merge() > $null
    $sheet.Cells.Item(12,2) = "Statistics"
    $sheet.Cells.Item(12,3) = "Global"
    $sheet.Cells.Item(12,4) = "Universal"
    $range1 = $sheet.Range("b12", "d12")
    $range1.HorizontalAlignment = -4108
    $range1.Font.Bold = $subTitleFontBold
    $range1.Interior.ColorIndex = $subTitleInteriorColor

    $ssoconfig = Get-NsxManagerSsoConfig
    $vcconfig = Get-NsxManagerVcenterConfig
    $ver = Get-PowerNSXVersion

    $sheet.Cells.Item(2,1) = "Report Run Date"
    $sheet.Cells.Item(2,2) = [System.DateTime]::Now
    $sheet.Cells.Item(2,2).HorizontalAlignment = -4131
    $sheet.Cells.Item(3,1) = "PowerNSX version"
    $sheet.Cells.Item(3,2) = $ver.version.toString()
    $sheet.Cells.Item(4,1) = "vCenter Mapping"
    $sheet.Cells.Item(4,2) = $vcconfig.ipAddress
    $sheet.Cells.Item(6,1) = "SSO Lookup URL"
    $sheet.Cells.Item(6,2) = $ssoconfig.ssoLookupServiceUrl    
    $sheet.Cells.Item(7,1) = "SSO User Account"
    $sheet.Cells.Item(7,2) = $ssoconfig.ssoAdminUsername
    $sheet.Cells.Item(9,1) = "NSX Manager Name"
#    $sheet.Cells.Item(9,2) = $sys_sum.hostName
    $sheet.Cells.Item(9,3) = $DefaultNSXConnection.Server
   
    $sheet.Cells.Item(10,1) = "NSX Manager Version"
    $sheet.Cells.Item(10,2) = ($DefaultNSXConnection.Version + "." + $DefaultNSXConnection.buildNumber)

    $sheet.Cells.Item(13,2) = "Layer 3 FW Rules"
    $sheet.Cells.Item(13,4) = "N/A"
    $sheet.Cells.Item(14,2) = "Services"
    $sheet.Cells.Item(15,2) = "Service Groups"
    $sheet.Cells.Item(16,2) = "MACSETS"
    $sheet.Cells.Item(16,4) = "N/A"
    $sheet.Cells.Item(17,2) = "IPSets"
    $sheet.Cells.Item(18,2) = "Security Groups"
    $sheet.Cells.Item(19,2) = "Security Tags"
    $sheet.Cells.Item(19,4) = "N/A"
    $sheet.Cells.Item(20,2) = "DFW Exclusion List"
    $sheet.Cells.Item(20,4) = "N/A"

    $range1 = $sheet.Range("C13", "D22")
    $range1.HorizontalAlignment = -4108
    $range1.NumberFormat = "_(* #,##0_);_(* (#,##0);_(* ""-""??_);_(@_)"
    $sheet.Cells.Item(13,3) = $wsDfwL3Rules.Cells.Item(1,27).Text
    $sheet.Cells.Item(14,3) = $wsServices.Cells.Item(1,27).Text
    $sheet.Cells.Item(14,4) = $wsServices.Cells.Item(1,28).Text
    $sheet.Cells.Item(15,3) = $wsSrvGrp.Cells.Item(1,27).Text
    $sheet.Cells.Item(15,4) = $wsSrvGrp.Cells.Item(1,28).Text
    $sheet.Cells.Item(16,3) = $wsMacSets.Cells.Item(1,27).Text
    $sheet.Cells.Item(17,3) = $wsIpSets.Cells.Item(1,27).Text
    $sheet.Cells.Item(17,4) = $wsIpSets.Cells.Item(1,28).Text
    $sheet.Cells.Item(18,3) = $wsSecGrp.Cells.Item(1,27).Text
    $sheet.Cells.Item(18,4) = $wsSecGrp.Cells.Item(1,28).Text
    $sheet.Cells.Item(19,3) = $wsSecTags.Cells.Item(1,27).Text
    $sheet.Cells.Item(20,3) = $wsDfwExl.Cells.Item(1,27).Text
    if ($GetSecGrpMembers){
        $sheet.Cells.Item(21,2) = "Security Group Memberships"
        $sheet.Cells.Item(21,4) = "N/A"
        $sheet.Cells.Item(21,3) = $wsSecGrpMbrs.Cells.Item(1,27).Text
    }
    if ($GetSecTagMembers){
        $sheet.Cells.Item(22,2) = "Security Group Memberships"
        $sheet.Cells.Item(22,4) = "N/A"
        $sheet.Cells.Item(22,3) = $wsSecTagMbrs.Cells.Item(1,27).Text
    }
}

########################################################
#    Security Group Membership Stats
########################################################

function sg_members_ws($sheet){

    $sheet.Cells.Item(1,1) = "Security Group Membership Statistics"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "c1")
    $range1.merge() > $null

    $sheet.Cells.Item(2,1) = "Security Group Name"
    $sheet.Cells.Item(2,2) = "Translated VMs"
    $sheet.Cells.Item(2,3) = "Translated IPs"
    $range = $sheet.Range("a2", "c2")
    $range.Font.Bold = $subTitleFontBold
    $range.Interior.ColorIndex = $subTitleInteriorColor
    $range.Font.Name = $subTitleFontName

    pop_sg_members_ws($sheet)
    
        if ($ShowProgress){
            Write-Progress -Completed "Report completed."
        }
    }
    
function pop_sg_members_ws($sheet){
    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Security Groups to gather Member Statistics, Please wait..."
    }
    
    $row = 3
    $sg = Get-NSXSecurityGroup

    if ($ShowProgress){
        $prgsNum = ($sg | measure).count
        $prgsCnt = 1
    }

    foreach($item in $sg){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Security Group Membership Statistics" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }

        $sheet.Cells.Item($row,1) = $item.name

        $url_vms = "/api/2.0/services/securitygroup/" + $item.objectid + "/translation/virtualmachines"
        $url_ips = "/api/2.0/services/securitygroup/" + $item.objectid + "/translation/ipaddresses"
        
        $sec_vm_stats = Invoke-NsxRestMethod -method get -uri $url_vms
        $sheet.Cells.Item($row,2) = $sec_vm_stats.vmnodes.vmnode.Length 

        $sec_ip_stats = Invoke-NsxRestMethod -method get -uri $url_ips
        $sheet.Cells.Item($row,3) = $sec_ip_stats.ipNodes.ipNode.ipAddresses.Length

        $row ++
    }
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "c"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "SecGrpMbrStats"
        $sheetObj.TableStyle = "TableStyleLight11"
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
    $range1 = $sheet.Range("a1", "e1")
    $range1.merge() > $null

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

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_ipset_ws($sheet){

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving IPSet Information, Please wait..."
    }

    $row=3
    $ipset = get-nsxipset -scopeID 'globalroot-0'

    $envstatIpsGl = ($ipset | measure).Count
    if ($ShowProgress){
        $prgsNum = $envstatIpsGl
        $prgsCnt = 1
    }

    foreach ($ip in $ipset){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding IPSet Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }

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

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Universal IPSet Information, Please wait..."
    }

    $ipset_unv = get-nsxipset -scopeID 'universalroot-0'

    $envstatIpsUn = ($ipset_unv | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatIpsUn
        $prgsCnt = 1
    }

    foreach ($ip in $ipset_unv) {
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Universal IPSet Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }

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
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "e"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "IPSets"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatIpsGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
    $sheet.Cells.Item(1,28) = $envstatIpsUn
    $sheet.Cells.Item(1,28).Font.ColorIndex = 2
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
    $range1 = $sheet.Range("a1", "c1")
    $range1.merge() > $null

    $sheet.Cells.Item(2,1) = "Name"
    $sheet.Cells.Item(2,2) = "Value"
    $sheet.Cells.Item(2,3) = "Description"
    $range2 = $sheet.Range("a2", "c2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    pop_macset_ws($sheet)

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_macset_ws($sheet){
    if ($ShowProgress){
        Write-Progress -Activity "Retrieving MACSet Information, Please wait..."
    }

    # Grab MACSets and populate
    $row=3
    $macset = get-nsxmacset

    $envstatMacGl = ($macset | measure).Count
    if ($ShowProgress){
        $prgsNum = $envstatMacGl
        $prgsCnt = 1
    }
    foreach ($mac in $macset) {
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding MACSet Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt++
        }

        $sheet.Cells.Item($row,1) = $mac.name
        $sheet.Cells.Item($row,2) = $mac.value
        if(!$mac.description){
            $sheet.Cells.Item($row,3) = $valueNotDefined
        }
        else {$sheet.Cells.Item($row,3) = $mac.description}

        $row++ # Increment Rows
    }
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "c"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "MACSets"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatMacGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
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
    $range1.merge() > $null

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

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_services_ws($sheet){

    # Grab Services and populate
    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Services Information, Please wait..."
    }

    $row=3
    $services = get-nsxservice -scopeID 'globalroot-0'

    $envstatSrvGl = ($services | measure).Count
    if ($ShowProgress){
        $prgsNum = $envstatSrvGl
        $prgsCnt = 1
    }

    foreach ($svc in $services) {
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Services Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt++
        }

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

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Universal Services Information, Please wait..."
    }

    $services_unv = get-nsxservice -scopeID 'universalroot-0'

    $envstatSrvUn = ($services_unv | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSrvUn
        $prgsCnt = 1
    }

    foreach ($svc in $services_unv) {
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Universal Services Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt++
        }

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
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "f"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "Services"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatSrvGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
    $sheet.Cells.Item(1,28) = $envstatSrvUn
    $sheet.Cells.Item(1,28).Font.ColorIndex = 2
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
    $range1 = $sheet.Range("a1", "e1")
    $range1.merge() > $null

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

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_service_groups_ws($sheet){

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Service Group Information, Please wait..."
    }
    if ($Quoted){
        $addDelimiter = """"
    }
    else{
        $addDelimiter = ""
    }

    $row=3
    $SG = Get-NSXServiceGroup -scopeID 'globalroot-0'

    $envstatSrvGrpGl = ($SG | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSrvGrpGl
        $prgsCnt = 1
    }

    foreach ($svc_mem in $SG){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Service Group Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }

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
            $sgCond = ""
            $sgCount = 1
            foreach ($member in $svc_mem.member){
                if ($OneLine){
                    if ($sgCount -eq 1){
                        $sgCond =  $addDelimiter + $member.name + $addDelimiter
                   }
                    else{
                        $sgCond = $sgCond + ", " + $addDelimiter + $member.name + $addDelimiter
                    }
                    $sgCount++
                }
                else{
                    $result = $services_ht[$member.objectid]
                    if([string]::IsNullOrWhiteSpace($result)){
                         $sheet.Cells.Item($row,4) = $member.name
                         $row++ # Increment Rows
                    }
                    else{
                        $link = $sheet.Hyperlinks.Add($sheet.Cells.Item($row,4), "", $result, $member.objectid, $member.name)  
                        $row++ # Increment Rows
                    }
                }
            }
            if ($OneLine){
                $sheet.Cells.Item($row,4) = $sgCond
                $row++
            }
        }
    }

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Universal Service Group Information, Please wait..."
    }
    
    $SGU = Get-NSXServiceGroup -scopeID 'universalroot-0'

    $envstatSrvGrpUn = ($SGU | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSrvGrpUn
        $prgsCnt = 1
    }

    foreach ($svc_mem in $SGU){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Universal Service Group Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }
        
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
            Write-Warning $svc_mem.objectID + "already exists, manually create hyper link reference"
        }

        if (!$svc_mem.member) 
        {
                $row++ # Increment Rows
        }
        else 
        {
            $sgCond = ""
            $sgCount = 1
            foreach ($member in $svc_mem.member){
                if ($OneLine){
                    if ($sgCount -eq 1){
                        $sgCond =  $addDelimiter + $member.name + $addDelimiter
                    }
                    else{
                        $sgCond = $sgCond + $addDelimiter + $member.name + $addDelimiter
                    }
                    $sgCount++
                }
                else{
                    $result = $services_ht[$member.objectid]        
                    if([string]::IsNullOrWhiteSpace($result)){
                         $sheet.Cells.Item($row,4) = $member.name
                         $row++ # Increment Rows
                    }
                    else{
                        $link = $sheet.Hyperlinks.Add($sheet.Cells.Item($row,4), "", $result, $member.objectid, $member.name)
                        $row++ # Increment Rows
                    }
                }
            }
            if ($OneLine){
                $sheet.Cells.Item($row,4) = $sgCond
                $row++
            }
        }
    }
    if ($OneLine -and $AddTables) {
        $range3 = $sheet.Range("a2", "e"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "SrvGrps"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatSrvGrpGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
    $sheet.Cells.Item(1,27) = $envstatSrvGrpUn
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
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
    $range1 = $sheet.Range("a1", "d1")
    $range1.merge() > $null

    $sheet.Cells.Item(2,1) = "Security Tag Name"
    $sheet.Cells.Item(2,2) = "Built-In"
    $sheet.Cells.Item(2,3) = "VM Members"
    $sheet.Cells.Item(2,4) = "Is Universal"
    $range2 = $sheet.Range("a2", "d2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    pop_sec_tags_ws($sheet)

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_sec_tags_ws($sheet){

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Security Tags, Please wait..."
    }

    $row=3
    $ST = get-nsxsecuritytag -includesystem

    $envstatSecTgGl = ($ST | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSecTgGl
        $prgsCnt = 1
    }

    foreach ($tag in $ST) {
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Security Tag Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }
        $sheet.Cells.Item($row,1) = $tag.name
        $sheet.Cells.Item($row,2) = $tag.systemResource
        $sheet.Cells.Item($row,3) = $tag.vmCount
        $sheet.Cells.Item($row,4) = $tag.isUniversal
        $row++ # Increment Rows
    }
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "d"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "SecTags"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatSecTgGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
}

########################################################
#    Security Tag Membership Worksheet
########################################################

function sec_tags_mem_ws($sheet) {

    $sheet.Cells.Item(1,1) = "Security Tag Members"
    $sheet.Cells.Item(1,1).Font.Size = $titleFontSize
    $sheet.Cells.Item(1,1).Font.Bold = $titleFontBold
    $sheet.Cells.Item(1,1).Font.ColorIndex = $titleFontColorIndex
    $sheet.Cells.Item(1,1).Font.Name = $titleFontName
    $sheet.Cells.Item(1,1).Interior.ColorIndex = $titleInteriorColor
    $range1 = $sheet.Range("a1", "b1")
    $range1.merge() > $null

    $sheet.Cells.Item(2,1) = "Security Tag Name"
    $sheet.Cells.Item(2,2) = "VM Name"
    $range3 = $sheet.Range("a2", "b2")
    $range3.Font.Bold = $subTitleFontBold
    $range3.Interior.ColorIndex = $subTitleInteriorColor
    $range3.Font.Name = $subTitleFontName

    pop_sec_tags_mem_ws($sheet)
    
    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}
    
function pop_sec_tags_mem_ws($sheet){
    
    if ($ShowProgress){
        Write-Progress -Activity "Retrieving Security Tag Members, Please wait..."
    }
    $row = 3
    $ST = get-nsxsecuritytag -includesystem

    # Retrieve a list of all Tag Assignments
    $tag_assign = $ST | Get-NsxSecurityTagAssignment        
    
    $envstatSecTgMbrGl = ($tag_assign | measure).count
    if ($ShowProgress){
        $prgsNum = $envstatSecTgMbrGl
        $prgsCnt = 1
    }

    foreach ($mem in $tag_assign){
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding Security Tag Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }
    
        $sheet.Cells.Item($row,1) = $mem.SecurityTag.name
        $sheet.Cells.Item($row,2) = $mem.VirtualMachine.name
        $row++
    }
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "b"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "SecTagMbrs"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatSecTgMbrGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
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
    $range1 = $sheet.Range("a1", "b1")
    $range1.merge() > $null

    $sheet.Cells.Item(2,1) = "VM Name"
    $sheet.Cells.Item(2,2) = "VM ID"
    $range2 = $sheet.Range("a2", "b2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    pop_ex_list_ws($sheet)

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_ex_list_ws($sheet){

    $row=3
    $guests = Get-NsxFirewallExclusionListMember

    $envstatExclGl = ($guests  | measure).count
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
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "b"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "ExclList"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatExclGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
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
    $range1 = $sheet.Range("a1", "c1")
    $range1.merge() > $null

    $sheet.Cells.Item(2,1) = "VM Name"
    $sheet.Cells.Item(2,2) = "Guest IP Address"
    $sheet.Cells.Item(2,3) = "VM ID"
    $range2 = $sheet.Range("a2", "c2")
    $range2.Font.Bold = $subTitleFontBold
    $range2.Interior.ColorIndex = $subTitleInteriorColor
    $range2.Font.Name = $subTitleFontName

    pop_ip_address_ws($sheet)

    if ($ShowProgress){
        Write-Progress -Completed "Report completed."
    }
}

function pop_ip_address_ws($sheet){

    if ($ShowProgress){
        Write-Progress -Activity "Retrieving VM IP Addressing information for vNIC-1, please wait..."
    }

    $row=3
    $guests = Get-VM | Select Name, VMIPAddress, id

    $envstatVmGstGl = ($guests | measure).Count
    if ($ShowProgress){
        $prgsNum = $envstatVmGstGl
        $prgsCnt = 1
    }

    foreach ($vm in $guests) {
        if ($ShowProgress){
            $PercentCompleted = [Math]::Round(($prgsCnt / $prgsNum) * 100)
            Write-Progress -Activity "Adding VM vNIC-1 IP Addressing Information" -Status "$prgsCnt of $prgsNum Complete:" -PercentComplete $PercentCompleted
            $prgsCnt ++
        }
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
    if ($AddTables) {
        $range3 = $sheet.Range("a2", "c"+($row-1))
        $sheetObj = $sheet.ListObjects.Add([Microsoft.Office.Interop.Excel.XlListObjectSourceType]::XlSrcRange, $range3, $null, [Microsoft.Office.Interop.Excel.XlYesNoGuess]::xlYes)
        $sheetObj.Name = "VmAddr"
        $sheetObj.TableStyle = "TableStyleLight11"
    }
    $sheet.Cells.Item(1,27) = $envstatVmGstGl
    $sheet.Cells.Item(1,27).Font.ColorIndex = 2
}

########################################################
#    Global Functions
########################################################

Clear-Host
Write-Host "`n`n+----------------------------------------------------------+" -ForegroundColor Green
Write-Host "|  Document NSX Security Configuration to Excel workbook.  |" -ForegroundColor Green
Write-Host "+----------------------------------------------------------+`n`n" -ForegroundColor Green
Write-Host "`nScript Options Selected:" -ForegroundColor Green

if ($ShowProgress) {
    $disp_progress = "y"
    Write-Host "Display Progress Bar for each step"
} 
elseif (-not $PSBoundParameters.ContainsKey("ShowProgress")) { 
    $disp_progress = "n"
    Write-Warning "No Progress Bar will be displayed"
}

if ( $OneLine -and $Quoted ) {
    $one_line = "y"
    $ol_quoted = "y"
    Write-Host "Object members used by Service & Security Groups will be Quotes """" and listed on the samne line"
}
elseif ( $OneLine ) {
    $one_line = "y"
    $ol_quoted = "n"
    Write-Host "Object members in Service & Security Groups will be listed on same line"
}
elseif (-not $PSBoundParameters.ContainsKey("OneLine")) { 
    $one_line = "n"
    $ol_quoted = "n"
    Write-Warning "Conditional Queries & Service Member Objects will be listed on separate lines"
}

if ($AddTables) {
    $add_tables = "y"
    Write-Host "Display Results in Tables on most Worksheets"
} 
elseif (-not $PSBoundParameters.ContainsKey("AddTables")) { 
    $add_tables = "n"
    Write-Warning "Display Results Normally on all Worksheets"
}

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

if ( $GetSecGrpStats ) {
    $collect_vm_members = "y"
    Write-Host "Collection of Security Group Membership Statistics Enabled"
} 
elseif (-not $PSBoundParameters.ContainsKey("GetSecGrpStats")) { 
    $collect_vm_members = "n"
    Write-Warning "Collection of Security Group Membership Statistics Disabled"
}

If (-not $DefaultNSXConnection){
    Write-Warning "Connection to NSX Manager and vCenter Server needs to be established"
    #$nsx_mgr = Read-Host "`nIP or FQDN of NSX Manager? "
    #Connect-NSXServer -NSXServer $nsx_mgr
    $vc_srv = Read-Host "`nIP or FQDN of vCenter Server? "
    if ( $vc_srv ){
        Connect-NSXServer -vCenterServer $vc_srv
    }
}
# Only tested to run on NSX 6.2.x & 6.3.x installations
if ($DefaultNSXConnection.version -match "^6\.[2-4]\."){
    startExcel($collect_vm_ips)
}
elseif ( $vc_srv ){
    Write-Host "`n"
    Write-Warning "NSX Manager version is not in the NSX 6.x release train"
}
else{
    Write-Host "`n"
    Write-Warning "No vCenter Server entered, ending Script"
}
