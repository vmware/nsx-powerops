# ***************************** #
# Function to get NSX prep Host #
# ***************************** #
function getNSXPrepairedHosts() {
    $allEnvClusters = get-cluster -Server $NSXConnection.ViConnection | %{
        $nsxCluster = $_
        get-cluster $_ | Get-NsxClusterStatus | %{
            if($_.featureId -eq "com.vmware.vshield.vsm.nwfabric.hostPrep" -And $_.installed -eq "true"){
                $global:listOfNSXPrepHosts += $nsxCluster | get-vmhost}}
    }
    $global:listOfNSXPrepHosts = $global:listOfNSXPrepHosts | Sort-Object -unique
}

# ********************************************* #
# Create empty excel sheet here w/ correct name # 
# ********************************************* #
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
} # End of function create New Excel

# ***************************** #
# Function to start SSH Session #
# ***************************** #
function startSSHSession($serverToConnectTo, $credentialsToUse){
    $newSSHSession = New-Sshsession -computername $serverToConnectTo -Credential $credentialsToUse
    return $newSSHSession
}

# **************************************************************************************** #
# Function to get global list if host VMKnic Data dic w/ all host and their VMKnic and IPs #
# **************************************************************************************** #
function getHostAndTheirVMKnics(){
    if ($global:listOfNSXPrepHosts.count -eq 0){
        ##Write-Host -ForegroundColor DarkRed "`n  NO NSX Prepaired Host found! Please Run 'Document ESXi Host(s) Info' first"
        ##exit
        getNSXPrepairedHosts
    }
    $vmHosts = $global:listOfNSXPrepHosts
    #Write-Host " Number of NSX Prepaired vmHosts are:" $vmHosts.length
    foreach ($eachVMHost in $vmHosts){
        $esxcli = $eachVMHost | Get-EsxCli -v2
        $myHostID = $eachVMHost.id
        $myHostName = $eachVMHost.Name
        $myParentClusterID = $eachVMHost.ParentId
        $vdsVMKnicData = @{}

        ##Write-Host "`nON HOST: $myHostName"
        get-cluster -Server $NSXConnection.ViConnection | %{ if ($_.id -eq $myParentClusterID){
            ##Write-Host "Checking cluster: $($_.id)"
            get-cluster $_ | Get-NsxClusterStatus | %{ if($_.featureId -eq "com.vmware.vshield.vsm.vxlan" -And $_.installed -eq "true"){
                ##Write-Host "Cluster prepaired for VxLAN"
                try{
                    $vdsInfo = $esxcli.network.vswitch.dvs.vmware.vxlan.list.invoke()
                    $myVDSName = $vdsInfo.VDSName
                    ##Write-Host "VDS Name is: $myVDSName"

                    $vmknicInfo = $esxcli.network.vswitch.dvs.vmware.vxlan.vmknic.list.invoke(@{"vdsname" = $myVDSName})
                    $myVmknicName = $vmknicInfo.VmknicName
                    ##Write-Host "VMKNIC Name is: $myVmknicName"
                    
                    $tempCountVMKnic = 0
                    if ($vdsInfo.VmknicCount -gt 1){
                        $myVmknicName | %{
                            #$tempvmknicLableList = $tempvmknicLableList + ("VmknicName$tempCountVMKnic", "IP$tempCountVMKnic", "Netmask$tempCountVMKnic")
                            $vdsVMKnicData.add($myVmknicName[$tempCountVMKnic], $($vmknicInfo.IP[$tempCountVMKnic]))
                            $global:listOfHostsVMKnicIPs = $global:listOfHostsVMKnicIPs + $vmknicInfo.IP[$tempCountVMKnic]
                            $tempCountVMKnic ++
                        }
                    }else{
                        ##Write-Host "Only one vmknic on this Host."
                        $vdsVMKnicData.add($myVmknicName, $($vmknicInfo.IP))
                        $global:listOfHostsVMKnicIPs = $global:listOfHostsVMKnicIPs + $vmknicInfo.IP
                    }
                }catch{$ErrorMessage = $_.Exception.Message
                    if ($ErrorMessage -eq "You cannot call a method on a null-valued expression."){
                        Write-Host " Warning: No VxLAN data found on this Host $myHostName" -ForegroundColor Red
                    }else{Write-Host $ErrorMessage}
                }
            }}
        }}
        $hostVMKnicData.Add($myHostName, $vdsVMKnicData)
    }
    # returns dic with structure:
    # {
    #   HostName1: {vmknic1: vmknic1_IP},
    #   HostName2: {vmknic1: vmknic1_IP} {vmknic2: vmknic2_IP}
    # }
    #return $hostVMKnicData
}

# **************************************************************************** #
# Function to make netstack ping from one provided host to list of VMKnics IPs #
# **************************************************************************** #
function checkVMKNICPing($fromHost, $fromVMKnic, $MTUSize, $hostCredentails=$Null, $excelSheet){
    if ($hostCredentails -eq $Null){$hostCredentails = Get-Credential -Message "Credentials for ESXi Host: $fromHost" -UserName "root"}
    $newSSHSession = startSSHSession -serverToConnectTo $fromHost -credentialsToUse $hostCredentails
    
    if ($newSSHSession -eq $null){
        #Write-Host -ForegroundColor DarkRed "`n Error connecting to SSH!"
        $SSH_Connection_Error = "SSH Connection Failed! For Host: $fromHost`n"
        Throw $SSH_Connection_Error
        #exit
    }

    Write-Host -ForegroundColor DarkGreen "`n ******************************"
    Write-Host -ForegroundColor DarkGreen " Pinging From Host: $fromHost"
    Write-Host -ForegroundColor DarkGreen " Pinging From VMKnic: $fromVMKnic"
    Write-Host -ForegroundColor DarkGreen " Ping MTU Size is: $MTUSize"
    Write-Host -ForegroundColor DarkGreen " ******************************"

    $global:excelRowCursor++
    $global:excelRowCursor++
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = " Pinging From Host:"
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor+1) = $fromHost
    $global:excelRowCursor++
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = " Pinging From VMKnic:"
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor+1) = $fromVMKnic
    $global:excelRowCursor++
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = " Ping MTU Size is:"
    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor+1) = $MTUSize
    $global:excelRowCursor++

    $listOfHosts = $hostVMKnicData.keys
    $listOfHosts | %{
        $myHost=$_
        Write-Host -ForegroundColor Darkyellow "`n Pinging To Host: $myHost"
        $global:excelRowCursor++
        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = " Pinging To Host:"
        $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor+1) = $myHost
        
        $listOfHostsVMKnics = $hostVMKnicData[$_].keys
        if ($listOfHostsVMKnics.count -eq 0){
            Write-Host -ForegroundColor DarkRed "No VMKnic found on this Host!"
            $global:excelRowCursor++
            $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = "No VMKnic found on this Host!"
        }else{
            $listOfHostsVMKnics | %{
                Write-Host " Pinging To its VMKnic: $_"
                $global:excelRowCursor++
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = " Pinging To its VMKnic:"
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor+1) = $_

                $vmknicIPToPing = $hostVMKnicData[$myHost].$_
                Write-Host " Pinging To its IP: $vmknicIPToPing"
                $global:excelRowCursor++
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = " Pinging To its IP:"
                $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor+1) = $vmknicIPToPing

                $pingStatus = invoke-sshcommand -SessionId $newSSHSession.SessionId -command "ping ++netstack=vxlan -I $fromVMKnic $vmknicIPToPing -d -s $MTUSize"
                if ($pingStatus.exitstatus -eq 0){
                    Write-Host -ForegroundColor Green " Ping Passed!"
                    Write-Host -ForegroundColor Green " "+ $($pingStatus.Output)[-1]
                    $global:excelRowCursor++
                    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = " Ping Passed!"
                    $global:excelRowCursor++
                    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = $($pingStatus.Output)[-1]
                                        
                    #return $pingStatus.Output
                }else{ 
                    Write-Host -ForegroundColor DarkRed "Ping failed! From host: $fromHost, its vmknic: $fromVMKnic. `nError is: $($pingStatus.Output)."
                    $global:excelRowCursor++
                    $excelSheet.Cells.Item($global:excelRowCursor,$global:excelColumnSursor) = "Ping failed! From host: $fromHost, its vmknic: $fromVMKnic. `nError is: $($pingStatus.Output)."
                }
            }
        }
    }
    <# Working code for global list of all VMKnic's IP.
    $listOfHostsVMKnicIPs | %{
        Write-Host -ForegroundColor Darkyellow " Pinging to IP: $_"
        $pingStatus = invoke-sshcommand -SessionId $newSSHSession.SessionId -command "ping ++netstack=vxlan -I $fromVMKnic $_ -d -s $MTUSize"
        if ($pingStatus.exitstatus -eq 0){return $pingStatus}
        else{ Write-Host -ForegroundColor DarkRed "Ping failed! for host: $fromHost, its vmknic: $fromVMKnic. Error is: $($pingStatus.error)." }
    }
    #>
}

# ************************* #
# Main Function starts here #
# ************************* #
$global:hostVMKnicData = @{}
$global:listOfHostsVMKnicIPs = @()
$getHostAndVMKnicDic=@{}
$global:excelRowCursor =1
$global:excelColumnSursor =1

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
    Write-Host "`n>> Please provide the Host ID:" -ForegroundColor DarkGreen -NoNewline
    $testHostIP = Read-Host
    getHostAndTheirVMKnics

    if ($hostVMKnicData[$testHostIP]){
        #Creating the excel sheet here...
        $newExcelWB = createNewExcel("VMKnicPingTestOutput")
        $sheet = $newExcelWB.WorkSheets.Add()
        $sheet.Name = "Summery"
        $sheet.Cells.Item(1,1) = "VMKnic Ping Test Output"

        $detailsOfHost = $hostVMKnicData.$testHostIP
        $detailsOfHost.keys | %{
            try{
                checkVMKNICPing -fromHost $testHostIP -fromVMKnic $_ -MTUSize $testMTUSize -hostCredentails $Null -excelSheet $sheet
            }Catch{
                $ErrorMessage = $_.Exception.Message
                Write-Host -ForegroundColor DarkRed " Error is: $ErrorMessage"
                $ErrorActionPreference = "Continue"
                #exit
            }
        }
        $global:newExcel.ActiveWorkbook.SaveAs()
        $global:newExcel.Workbooks.Close()
        $global:newExcel.Quit()
    }
}elseif ($numberOfHostToTest -eq "all" -or $numberOfHostToTest -eq "ALL" -or $numberOfHostToTest -eq ''){
        # Check if one credential for all host?
        Write-Host "`n>> Provide one password for all hosts? Y or N [default Y]: " -ForegroundColor Darkyellow -NoNewline
        $oneHostCredentialsFlag = Read-Host
        if ($oneHostCredentialsFlag -eq 'Y' -or $oneHostCredentialsFlag -eq 'y' -or $oneHostCredentialsFlag -eq ''){
            $esxicred = Get-Credential -Message "All ESXi Host(s) Credentail" -UserName "root"
        }else{$esxicred=$Null}

        # get global hostVMKnicData by running function getHostAndTheirVMKnics
        getHostAndTheirVMKnics
        
        #Creating the excel sheet here...
        $newExcelWB = createNewExcel("VMKnicPingTestOutput")
        $sheet = $newExcelWB.WorkSheets.Add()
        $sheet.Name = "Summery"
        $sheet.Cells.Item(1,1) = "VMKnic Ping Test Output"

        # get list of hosts and run a loop through them to call function check VMKNIC Ping to ping 
        # from each host's each vmknic to all Host's vmknics.
        $listOfHosts = $hostVMKnicData.keys
        $listOfHosts | %{
            try{
                $myHost=$_
                #Write-Host "`nfromHost is: $_"
                $listOfHostsVMKnics = $hostVMKnicData[$_].keys
                $listOfHostsVMKnics | %{
                    checkVMKNICPing -fromHost $myHost -fromVMKnic $_ -MTUSize $testMTUSize -hostCredentails $esxicred -excelSheet $sheet
                }
            }Catch{
                $ErrorMessage = $_.Exception.Message
                Write-Host -ForegroundColor DarkRed " Error is: $ErrorMessage"
                $ErrorActionPreference = "Continue"
                #exit
            }
        }
$global:newExcel.ActiveWorkbook.SaveAs()
$global:newExcel.Workbooks.Close()
$global:newExcel.Quit()
}else{
    Write-Host -ForegroundColor DarkRed "You have made an invalid choice!"
    exit
}

<#
Write-Host "Still passing the try block!!"
    }Catch{
        $Error[0].Exception
        $ErrorMessage = $_.Exception.Message
        Write-Host -ForegroundColor DarkRed "Error is: $ErrorMessage"
        $ErrorActionPreference = "Continue"
    }
#>
