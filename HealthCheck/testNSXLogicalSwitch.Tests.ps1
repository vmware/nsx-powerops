<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
#NSX Manager tests
#Nick Bradford
#nbradford@vmware.com

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


#I need... 
# $NsxConnection in global scope
# Need to avoid prompting if non interactive to avoid scheduled task hanging.
if ( (-not $global:ControllerCredential ) -and ( -not $nonInteractive)) { 
    $ControllerCredential = Get-Credential -Message "NSX Controller's Credentials" -UserName "admin"
}
Describe "Logical Switches" {

    #Setup - controller connection to all controllers
    
    $ControllerSshConnection = @{}
    $NsxControllers = Get-NsxController -connection $NSXConnection
    foreach ( $controller in $NsxControllers) {
        try { 
            $session = New-SshSession -ErrorAction Stop -credential $ControllerCredential $controller.ipaddress -AcceptKey
            $ControllerSshConnection.Add($controller.id, $session) | out-null
        }
        catch {

            Throw "Test setup failed.  SSH connection to controller $($controller.ipaddress) failed.  $_"
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

                Write-Host "VNI state on controller $controller" 
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