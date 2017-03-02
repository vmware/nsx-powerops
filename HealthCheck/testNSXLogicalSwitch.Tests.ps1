#VMware NSX Healthcheck test
#NSX LS tests
#Nick Bradford
#nbradford@vmware.com

<#
Copyright © 2015 VMware, Inc. All Rights Reserved.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2, as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTIBILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License version 2 for more details.

You should have received a copy of the General Public License version 2 along with this program.
If not, see https://www.gnu.org/licenses/gpl-2.0.html.

The full text of the General Public License 2.0 is provided in the COPYING file.
Some files may be comprised of various open source software components, each of which
has its own license that is located in the source code of the respective component.
#>


#I need... 
# $NsxConnection in global scope
# $NsxControllerCredential in global scope
$NsxControllerCredential = Get-Credential -Message "NSX Controller's Credentails" -UserName "admin"

Describe "Logical Switches" {

    #Setup - controller connection to all controllers
    
    $ControllerSshConnection = @{}
    $NsxControllers = Get-NsxController -connection $NSXConnection
    foreach ( $controller in $NsxControllers) {
        try { 
            $session = New-SshSession -ErrorAction Stop -credential $NsxControllerCredential $controller.ipaddress 
            $ControllerSshConnection.Add($controller.id, $session) | out-null
        }
        catch {

            Throw "Test setup failed.  SSH connection to controller $($controller.id) failed.  $_"
        }
    }
    #collection of LS from API.
    try { 
        $logicalswitches = Get-NsxLogicalSwitch -connection $NsxConnection
    }
    catch {
        Throw "Test setup failed.  Logical Switch retrieval from NSX API failed.  $_"
    }

    #Lets do it...
    $ctrlvniresults = @{}
    foreach ( $ls in $logicalswitches ) {
    Write-Host "the Logical Switch $($ls.name)" 

        if ( $ls.controlPlaneMode -eq 'MULTICAST_MODE') { 

            it "uses multicast_mode for packet replication, skipping control plane tests" {}

        }
        else { 

            Write-Host "Logical Switch control plane tests" 

            try {
                
                #Setup the vniresult member for this LS
                $ctrlvniresults.Add($ls.vdnid, @{})   | out-null 
                
                #Get the individual VNI status from each controller.
                foreach ($Controller in $ControllerSshConnection.Keys ) {
                    $ret = (Invoke-SSHCommand -SSHSession $ControllerSshConnection.$Controller "show control-cluster logical-switches vni $($ls.vdnId)").output 

                    #If I dont use the pipe to where $_ -match construct, something in PSATE eats the $matches variable....
                    $vniStatus = $ret | ? { $_ -match "$($ls.vdnId)\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+(\w+)\s+(\w+)\s+(\d+)\s*\d*$" }
                    if ( $vniStatus ) { 

                        write-debug "$vnistatus"

                        #Assuming we found the VNI on the controller...
                        write-debug "Found VNI $($ls.vdnid) on controller $($ControllerSshConnection.$Controller.host)"
                        write-debug "Controller $Controller, VNI Owner: $($matches.1), BUM Replication : $($matches.2), ARP Proxy : $($Matches.3)"

                        #add it to the vniresult array as kv 'controllerid = <hashtable of props>
                        $ctrlvniresults.$($ls.vdnid).Add(
                            "$Controller", @{
                                "LsOwningController" = $matches.1
                                "LsBumRep" = $matches.2
                                "LsArpProxy" = $matches.3
                                "Connections" = $matches.4
                            }
                        )
                    }
                }
            }
            
            catch {
                Throw "Test setup failed.  Failed retreiving VNI status from control plane for Logical Switch $($ls.name). $_"
            }
            
            $CurrLsVniResults = $ctrlvniresults.($ls.vdnid)


            it "is found on all controllers" {

                "VNI found on $($CurrLsVniResults.count) controllers" | Should BeExactly "VNI found on $($ControllerSshConnection.Count) controllers"
            }
            Write-Verbose "VNI $($ls.vdnid) found on $($CurrLsVniResults.count) controllers"

            it "has the same owning controller on all controllers" { 
                "Number of unique owning controllers for VNI : $(($CurrLsVniResults.Values.LsOwningController | sort-object -unique).count)" | should match "Number of unique owning controllers for VNI : 1" 
            }
            Write-Verbose "Number of unique owning controllers for VNI : $(($CurrLsVniResults.Values.LsOwningController | sort-object -unique).count)" 


            foreach ( $controller in $CurrLsVniResults.keys) { 

                Given "VNI state on controller $controller" {
                    $controllerip = ($NsxControllers | ? { $_.id -eq $controller } ).ipaddress

                    it "has BUM replication and Proxy ARP enabled" {
                        "BUM-Replication : $($CurrLsVniResults.$controller.LsBumRep), ARP-Proxy : $($CurrLsVniResults.$controller.LsArpProxy)" | should match "BUM-Replication : Enabled, ARP-Proxy : Enabled"
                    }

                    Write-Verbose "VNI : $($ls.vdnid), BUM-Replication : $($CurrLsVniResults.$controller.LsBumRep), ARP-Proxy : $($CurrLsVniResults.$controller.LsArpProxy)"

                    # #Using the first controller returned by the API as the source of truth to ask for the 'correct' owning controller for any VNI. 
                    # if ( $controllerip -eq $CurrLsVniResults.($nsxcontrollers[0].id).LsOwningController ) { 

                    #     it "is the owning controller and has the correct number of connections on the owning controller" {
                    #         #Bs test to ensure failure.... Need more testing to determine correct val here.
                    #         $CurrLsVniResults.$controller.Connections | should equal 100
                    #     }
                    # }
                    # else { 

                    #     it "is not the owning controller and has zero connections" {
                    #         $CurrLsVniResults.$controller.Connections | should equal 0
                    #     }
                    # }
                }
            }
        }
    }
}