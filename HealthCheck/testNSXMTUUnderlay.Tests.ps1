<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
#NSX vTEP to vTEP Connectivity tests
#Puneet Chawla
#@thisispuneet

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

#region Functions

# ********************************************* #
# Create empty excel sheet here w/ correct name # 
# ********************************************* #

function createNewExcel{ 
    Write-Progress -Activity "Creating Excel Document" -Status "Create new Excel document"    
    $global:newExcel = New-Object -Com Excel.Application
    $global:newExcel.visible = $false
    $global:newExcel.DisplayAlerts = $false
    $wb = $global:newExcel.Workbooks.Add()
    Write-Progress -Activity "Creating Excel Document" -Status "Create new Excel document" -Completed    

    return $wb
} # End of function createNewExcel

# **************************************************************************************** #
# Function to get list if NSX prepared hosts and their VMKnic and IPs #
# **************************************************************************************** #
function get-HostsAndVteps{
    param($server)
    #Collect all hosts in Connected state
    $hostnames = (Get-VMHost -Server $server | ?{$_.ConnectionState -eq "Connected"}).name
    
    # Collect VTEP
    foreach($vmhost in $hostnames){
        #create esxcli object for a host
        $esxcli = Get-ESXCLI -VMHost $vmhost -V2 -Server $server
        $esxVersion = ($esxcli.system.version.get.Invoke()).version

        #collecting VTEP VMK names and IP Addresses
        $vteps = $esxcli.network.ip.interface.list.Invoke() | ?{$_.netstackinstance -eq "vxlan"} | select Name, Enabled, MTU

        #collect IP addresses for each VTEP
        if($vteps){
            $VMKnicData = @{}
            foreach($vmk in $vteps){
                $ipv4 = ($esxcli.network.ip.interface.ipv4.get.Invoke() | ?{$_.name -eq $vmk.name}).IPv4Address
                $VMKnicData.add($vmk.name,$ipv4)
            }
            $hostVMKnicData.Add($vmhost, $VMKnicData)
            
            # collect combination of ESXi Host and its vCenter - for Cross-VC NSX Deployments
            $hostvCenterData.add($vmhost,$server)
        }
    }       
}

# **************************************************************************** #
# Function to make netstack ping from one provided host to list of VMKnics IPs #
# **************************************************************************** #
function checkVMKNICPing{
    
    param(
        [string]$fromHost,
        [string]$fromVMKnic,
        [string]$MTUSize,
        $server,
        $excelSheet,
        $summaryExcelSheet
    )

    $titleFontSize = 8
    $titleFontBold = $True
    $titleFontColorIndex = 2
    $titleFontName = "Calibri (Body)"
    $titleInteriorColor = 49

    $vmknicIPToPingFrom = $hostVMKnicData[$fromHost].$fromVMKnic

    Write-Host -ForegroundColor DarkGreen "`n ******************************"
    Write-Host -ForegroundColor DarkGreen " Pinging From Host: $fromHost"
    Write-Host -ForegroundColor DarkGreen " Pinging From VMKnic: $fromVMKnic"
    Write-Host -ForegroundColor DarkGreen " Pinging From VMKnic IP: $vmknicIPToPingFrom"
    Write-Host -ForegroundColor DarkGreen " Ping MTU Size is: $MTUSize"
    Write-Host -ForegroundColor DarkGreen " ******************************"

    $global:excelRowCursor++
    $global:excelRowCursor++
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Pinging From Host:"
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Size = $titleFontSize
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Bold = $titleFontBold
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Name = $titleFontName
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor+1) = $fromHost

    $global:excelRowCursor++
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Pinging From VMKnic:"
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Size = $titleFontSize
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Bold = $titleFontBold
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Name = $titleFontName
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor+1) = $fromVMKnic
    $global:excelRowCursor++
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Pinging From VMKnic IP:"
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Size = $titleFontSize
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Bold = $titleFontBold
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Name = $titleFontName
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor+1) = $vmknicIPToPingFrom
    $global:excelRowCursor++
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Ping MTU Size is:"
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Size = $titleFontSize
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Bold = $titleFontBold
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Font.Name = $titleFontName
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor+1) = $MTUSize
    $global:excelRowCursor++

    $listOfHosts = $hostVMKnicData.keys
    $listOfHosts | %{
        $myHost=$_
        Write-Host -ForegroundColor Darkyellow "`n Pinging To Host: $myHost"
        $global:excelRowCursor++
        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Pinging To Host:"
        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor+1) = $myHost
        
        $listOfHostsVMKnics = $hostVMKnicData[$_].keys
        if ($listOfHostsVMKnics.count -eq 0){
            Write-Host -ForegroundColor DarkRed "No VMKnic found on this Host!"
            $global:excelRowCursor++
            $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = "No VMKnic found on this Host!"
        }else{
            $listOfHostsVMKnics | %{
                $vmknicNameToPing = $_
                Write-Host " Pinging To its VMKnic: $vmknicNameToPing"
                $global:excelRowCursor++
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Pinging To its VMKnic:"
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor+1) = $vmknicNameToPing

                $vmknicIPToPing = $hostVMKnicData[$myHost].$vmknicNameToPing
                Write-Host " Pinging To its IP: $vmknicIPToPing"
                $global:excelRowCursor++
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Pinging To its IP:"
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor+1) = $vmknicIPToPing

                $global:totalPings++

                #Preparing arguments
                $arguments = @{}
                $esxcli = Get-ESXCLI -vmhost $fromHost -V2 -Server $server

                $arguments = $esxcli.network.diag.ping.CreateArgs()
                $arguments.host = $vmknicIPToPing
                $arguments.count = 3
                $arguments.netstack = "vxlan"
                $arguments.df = $true
                $arguments.interface = $fromVMKnic
                $arguments.size = $MTUSize

                try{
                    $pingStatus = $esxcli.network.diag.ping.Invoke($arguments)
                    if($pingStatus.summary | Get-Member | ?{$_.Name -eq "RoundtripAvg"}){
                        $RoundtripMinMS = [convert]::ToInt32($pingStatus.summary.RoundtripMin, 10)/1000
                        $RoundtripAvgMS = [convert]::ToInt32($pingStatus.summary.RoundtripAvg, 10)/1000
                        $RoundtripMaxMS = [convert]::ToInt32($pingStatus.summary.RoundtripMax, 10)/1000
                        $output = "  [+] round-trip min/avg/max=" + $RoundtripMinMS+"/"+$RoundtripAvgMS+"/"+$RoundtripMaxMS+"ms"
                    }
                    else{
                        $RoundtripMinMS = [convert]::ToInt32($pingStatus.summary.RoundtripMinMS, 10)/1000
                        $RoundtripAvgMS = [convert]::ToInt32($pingStatus.summary.RoundtripAvgMS, 10)/1000
                        $RoundtripMaxMS = [convert]::ToInt32($pingStatus.summary.RoundtripMaxMS, 10)/1000
                        $output = "  [+] round-trip min/avg/max=" + $RoundtripMinMS+"/"+$RoundtripAvgMS+"/"+$RoundtripMaxMS+"ms"
                    }
                      
                    it "Ping test result" {
                        $pingStatus.summary.PacketLost -eq 0 | Should Be $true
                    }
                    if ($pingStatus.summary.PacketLost -eq 0){                    
                        Write-Host -ForegroundColor Green $output
                        $global:excelRowCursor++
                        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = " Ping Passed!"
                        $global:excelRowCursor++
                        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = $output
                                        
                        #return $pingStatus.Output
                    }
                    elseif($pingStatus.summary.PacketLost -lt 100){ 
                        $global:totalFailedPings++
                        Write-Host -ForegroundColor Yellow "Some pings failed! From host: $fromHost, its vmknic: $fromVMKnic."
                        Write-Host "Packet loss is: $($pingStatus.summary.PacketLost)%"
                        $global:excelRowCursor++
                        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = "Ping failed!"
                        Log-FailedPing -fromHost $fromHost -fromVMKnic $fromVMKnic -vmknicIPToPingFrom $vmknicIPToPingFrom -vmknicIPToPing $vmknicIPToPing -vmknicNameToPing $vmknicNameToPing -myHost $myHost -summaryExcelSheet $summaryExcelSheet
                    }
                    else{
                        $global:totalFailedPings++
                        Write-Host -ForegroundColor Red "Ping failed! From host: $fromHost, its vmknic: $fromVMKnic."
                        #Write-Host "Total Failed Pings are: $global:totalFailedPings"
                        $global:excelRowCursor++
                        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = "Ping failed!"
                        Log-FailedPing -fromHost $fromHost -fromVMKnic $fromVMKnic -vmknicIPToPingFrom $vmknicIPToPingFrom -vmknicIPToPing $vmknicIPToPing -vmknicNameToPing $vmknicNameToPing -myHost $myHost -summaryExcelSheet $summaryExcelSheet
                    }
                }
                catch{
                    
                    it "Ping test result" {
                        $pingStatus.summary.PacketLost -eq 0 | Should Be $true
                    }

                    if($_.Exception.Message -match "Message too long"){
                        write-host -Fore:Red " Error is: Ping failed because the MTU of source VMK MTU is too small to fit test packet`n"
                    }                      
                    else{
                        Write-Host -ForegroundColor DarkRed " Error is: $($_.Exception.Message)"
                    }
                    $global:totalFailedPings++
                    $global:excelRowCursor++
                    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnCursor) = "Ping failed!"
                    Log-FailedPing -fromHost $fromHost -fromVMKnic $fromVMKnic -vmknicIPToPingFrom $vmknicIPToPingFrom -vmknicIPToPing $vmknicIPToPing -vmknicNameToPing $vmknicNameToPing -myHost $myHost -summaryExcelSheet $summaryExcelSheet
                }
            }
        }
    }
}

# *******************************************************************#
# Function to update the summary page with headers and overall stats #
# *******************************************************************#
function Update-SummaryExcelSheet{
    
    param(
    $summaryExcelSheet
    )

    $titleFontSize = 8
    $titleFontBold = $True
    $titleFontColorIndex = 2
    $titleFontName = "Calibri (Body)"
    $titleInteriorColor = 49

    $global:summaryExcelRowCursor = 3
    $global:summaryExcelColumnCursor = 1
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = " Total Number of Ping Tests:"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor+1) = $global:totalPings
    $global:summaryExcelRowCursor++

    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = " Total Tests Passed:"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor+1) = $global:totalPings-$global:totalFailedPings
    $global:summaryExcelRowCursor++

    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = " Total Test Failed:"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor+1) = $global:totalFailedPings
    $global:summaryExcelRowCursor++

    $global:summaryExcelRowCursor = 3
    $global:summaryExcelColumnCursor = 6
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = "List of Failed Ping(s)"
    $global:summaryExcelRowCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = "From Host"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).HorizontalAlignment = -4108
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = "From VMKnic"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).HorizontalAlignment = -4108
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = "From IP"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).HorizontalAlignment = -4108
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = "To IP"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).HorizontalAlignment = -4108
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = "To VMKnic"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).HorizontalAlignment = -4108
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = "To Host"
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Size = $titleFontSize
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Bold = $titleFontBold
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.ColorIndex = $titleFontColorIndex
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Font.Name = $titleFontName
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).Interior.ColorIndex = $titleInteriorColor
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor).HorizontalAlignment = -4108
    $global:summaryExcelColumnCursor++

}

# ************************************************************************#
# Function to log details of failed ping tests to the excel summary sheet #
# ************************************************************************#
function Log-FailedPing{

    param(
        $fromHost,
        $fromVMKnic,
        $vmknicIPToPingFrom,
        $vmknicIPToPing,
        $vmknicNameToPing,
        $myHost,
        $summaryExcelSheet
    )

    $global:summaryExcelRowCursor++
    $global:summaryExcelColumnCursor = 6
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = $fromHost
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = $fromVMKnic
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = $vmknicIPToPingFrom
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = $vmknicIPToPing
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = $vmknicNameToPing
    $global:summaryExcelColumnCursor++
    $summaryExcelSheet.Cells.Item($global:summaryExcelRowCursor,$global:summaryExcelColumnCursor) = $myHost
}

#endregion

# ************************* #
# Main Function starts here #
# ************************* #
Describe "NSX Manager" {
    $global:hostVMKnicData = @{}
    $global:hostvCenterData = @{}
    $global:totalPings = 0
    $global:totalFailedPings = 0
    $global:failedPingDic=@{}
    $global:listOfHostsVMKnicIPs = @()
    $getHostAndVMKnicDic=@{}
    $global:excelRowCursor =1
    $global:excelColumnCursor =1
    $global:summaryExcelRowCursor =4
    $global:summaryExcelColumnCursor =6

    # Check the NSX Manager Role
    $nsxManagerRole = (Get-NsxManagerRole -Connection $NSXConnection).Role

    if($nsxManagerRole -ne "STANDALONE"){
        Write-Host "`nNSX Manager Role is $nsxManagerRole"
        do{
            $answer = Read-Host "Do you want to run this test across Primary and Secondary NSX Managers? (y/n)"
        }while($answer -notmatch "^[yn]$")
    }

    if($answer -eq "y"){
        
        Write-Host -fore:DarkYellow "`nPlease provide the connection details for the second vCenter Server"
        
        $secondaryVC = Read-Host ">> Enter vCenter Server FQDN or IP Address"
        $secondaryVcUsername = Read-Host ">> Enter user name"
        $secondaryVcPassword = read-host -assecurestring ">> Enter password" 
        $secondaryVcCred = New-Object System.Management.Automation.PSCredential $secondaryVcUsername, $secondaryVcPassword
        $secondaryVcConnection = Connect-VIServer -Server $secondaryVC -Credential $secondaryVcCred
        
    
        if($secondaryVcConnection){    
            write-host -fore:Green "Successfully connected to the second vCenter Server."        
        }
        else{
            write-host -fore:Red "Failed to connect to the second vCenter Server."
        }
    }


    # Get the MTU size to test the ping command with.
    Write-Host "`n>> Please provide the MTU size to test [Default: 1572]:" -ForegroundColor Darkyellow -NoNewline
    $testMTUSize = Read-Host

    if ($testMTUSize -eq ''){
        $testMTUSize = 1572
    }


    # get the one or all host options from the user.
    Write-Host "`n>> Run this test from 'one' host or 'all' [Default: all]:" -ForegroundColor Darkyellow -NoNewline
    [string]$numberOfHostToTest = Read-Host

    # Check if user entered one or all. Call getHostAndTheirVMKnics appropriatelly as per the user choice.
    if ($numberOfHostToTest -eq 1 -or $numberOfHostToTest -eq "one"){
        Write-Host "`n>> Please provide the Host Name or IP (as shown in vCenter):" -ForegroundColor DarkGreen -NoNewline
        $testHostIP = Read-Host
        # get global hostVMKnicData by running function getHostAndTheirVMKnics
        get-HostsAndVteps -server $NSXConnection.VIConnection
        if($secondaryVcConnection){
            get-HostsAndVteps -server $secondaryVcConnection
        }

        if ($hostVMKnicData[$testHostIP]){
            #Creating 'Ping Result' excel sheet.
            $newExcelWB = createNewExcel
            $sheet = $newExcelWB.WorkSheets.Add()
            $sheet.Name = "Ping Result"
            $sheet.Cells.Item(1,1) = "VMKnic Ping Test Output"
            
            #Creating 'Summary' excel sheet
            $summarySheet = $newExcelWB.WorkSheets.Add()
            $summarySheet.Name = "Summary"
            $summarySheet.Cells.Item(1,1) = "Summary of VMKnic Ping Test"

            $detailsOfHost = $hostVMKnicData.$testHostIP
            $server = $hostvCenterData[$testHostIP]
            $detailsOfHost.keys | %{
                checkVMKNICPing -fromHost $testHostIP -fromVMKnic $_ -MTUSize $testMTUSize -excelSheet $sheet -summaryExcelSheet $summarySheet -server $server
            }
        }

        #Update 'Summary' excel sheet
        Update-SummaryExcelSheet -summaryExcelSheet $summarySheet

        # Remove Default Sheet1
        $newExcelWB.worksheets.item("Sheet1").Delete()

        # Save Excel file
        $currentdocumentpath = "$documentlocation\VMKnicPingTestOutput-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xlsx" -f (get-date)
        $newExcelWB.SaveAs($currentdocumentpath)
        $newExcelWB.close()
        $global:newExcel.Quit()
        releaseObject -obj $newExcelWB
        releaseObject -obj $newExcel

    }
    elseif ($numberOfHostToTest -eq "all" -or $numberOfHostToTest -eq "ALL" -or $numberOfHostToTest -eq ''){

        # get global hostVMKnicData by running function getHostAndTheirVMKnics
        get-HostsAndVteps -server $NSXConnection.VIConnection
        if($secondaryVcConnection){
           get-HostsAndVteps -server $secondaryVcConnection
        }

        #Creating 'Ping Result' excel sheet
        $newExcelWB = createNewExcel
        $sheet = $newExcelWB.WorkSheets.Add()
        $sheet.Name = "Ping Result"
        $sheet.Cells.Item(1,1) = "VMKnic Ping Test Output"

        #Creating 'Summary' excel sheet
        $summarySheet = $newExcelWB.WorkSheets.Add()
        $summarySheet.Name = "Summary"
        $summarySheet.Cells.Item(1,1) = "Summary of VMKnic Ping Test"

        # get list of hosts and run a loop through them to call function check VMKNIC Ping to ping 
        # from each host's each vmknic to all Host's vmknics.
        $listOfHosts = $hostVMKnicData.keys
        $listOfHosts | %{
            $server = $hostvCenterData[$_]
            $myHost=$_
            $listOfHostsVMKnics = $hostVMKnicData[$_].keys
            $listOfHostsVMKnics | %{
                checkVMKNICPing -fromHost $myHost -fromVMKnic $_ -MTUSize $testMTUSize  -excelSheet $sheet -summaryExcelSheet $summarySheet -server $server
            }
        }

        #Update 'Summary' excel sheet
        Update-SummaryExcelSheet -summaryExcelSheet $summarySheet

        # Remove Default Sheet1
        $global:newExcel.worksheets.item("Sheet1").Delete()
        
        # Save Excel file
        $currentdocumentpath = "$documentlocation\VMKnicPingTestOutput-{0:yyyy}-{0:MM}-{0:dd}_{0:HH}-{0:mm}.xlsx" -f (get-date)
        $newExcelWB.SaveAs($currentdocumentpath)
        $newExcelWB.close()
        $global:newExcel.Quit()
        releaseObject -obj $newExcelWB
        releaseObject -obj $newExcel
    }
    else{
        Write-Host -ForegroundColor DarkRed "You have made an invalid choice!"
        exit
    }

}