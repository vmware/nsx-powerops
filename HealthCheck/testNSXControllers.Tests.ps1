<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
#NSX LS/LR Control plane tests
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
# $ControllerCredential in global scope
# $vCenterSSHConnection = startSSHSession -serverToConnectTo $vCenterHost -credentialsToUse $myvCenterSecureCredential

# Need to avoid prompting if non interactive to avoid scheduled task hanging.
if ( (-not $global:ControllerCredential ) -and ( -not $nonInteractive)) { 
    $ControllerCredential = Get-Credential -Message "NSX Controller's Credentials" -UserName "admin"
}

Describe "NSX Controllers" {
    Write-Host "The NSX controller cluster"
    [array]$NSXControllers = get-nsxcontroller -connection $NSXConnection
    if ( -not $NSXcontrollers ) {It "has no controller cluster, skipping controller tests" {}}
    else {
        #Setup... 
        #Get the cluster uuid from controller 0
        try {
            $sesh = New-SshSession -ErrorAction Ignore -Credential $ControllerCredential -computername $nsxcontrollers[0].ipaddress -AcceptKey
            $lines = (Invoke-SSHCommand -SSHSession $sesh "show control-cluster status").output
            $lines | ? { $_ -match "^Cluster ID:\s+(\S+)$" } | out-null
            $clusteruuid = $matches[1]
            Remove-SshSession -SshSession $sesh | out-null
        }catch {}

        It "has the supported number of controller nodes" {$NsxControllers.Count | Should be 3}
        foreach ( $controller in $NsxControllers ) {
            Write-Host "Controller $($Controller.id)"
            try {$sesh = New-SshSession -ErrorAction Ignore -credential $ControllerCredential -computername $controller.ipaddress -AcceptKey}
            catch {}
            
            #Check status in API
            
            it "has a RUNNING status in API" {$controller.Status  | should be "RUNNING"}
            Write-Verbose $controller.status
            
            #is it ssh reachable?
            it "is reachable via ssh at $($controller.ipaddress)" {$sesh.Connected | should be $true}

            if ( $sesh.Connected ) {
                Write-Verbose "$($Sesh.Host) : $($Sesh.Connected)"

                #Check that the clusteruuid we got back looks validish...
                it "has a valid cluster uuid" {
                    [guid]::tryparse($clusteruuid, [ref][guid]::NewGuid()) | should be true
                }
                Write-Verbose "Clusteruuid from first node: $clusteruuid"

                <# Removing this test as new version of NSX doesn't support it and in that case test will fail. 
                #Check ipsec tunnel status
                $ipsectunnels = (Invoke-SSHCommand -SSHSession $sesh "show control-cluster network ipsec tunnels").output | ? { $_ -match 'Security Associations' }
                it "has $($nsxcontrollers.count - 1) IPSec SAs up, and 0 connecting" {    
                    #Test that we have SAs up with other controllers.    
                    $ipsectunnels | Should BeExactly "Security Associations ($($nsxcontrollers.count - 1) up, 0 connecting):"
                    #Security Associations (2 up, 0 connecting):
                }
                Write-Verbose $ipsectunnels
                #>

                #Check ZK status
                $zklines = (Invoke-SSHCommand -SSHSession $sesh "show control-cluster connections").output | ? { $_ -match '^persistence_server  server/2878\s{5}([Y-])\s{9}(\d)'}
                it "has a healthy Zookeeper status" {
                    #BS test until i test in 3 ctrl env
                    
                    if ( $matches[1] -eq 'Y' ) { 
                        "Persistence server leader connections : $($matches[2])" | should match "Persistence server leader connections : $($nsxcontrollers.count - 1)"
                    }
                    else { 
                        $matches[0] | should not be blank
                    }
                }
                Write-Verbose $zklines

                #Check that the ip addresses of all the controllers from the API match that listed in the startup nodes for the given controller...    
                $startupnodes = (Invoke-SSHCommand -SSHSession $sesh "show control-cluster startup-nodes").output[0].Split(",").trim() | sort-object
                it "should contain all cluster members in the startup nodes list" {
                    $startupnodes | Should BeExactly ($NSXControllers.ipaddress | sort-object)
                }
                Write-Verbose "Startup nodes from ctrl : $startupnodes.  List of Controllers : $($NSXControllers.ipaddress | sort-object)"

                #Disk space
                $ret = invoke-sshcommand "show status" -sshsession $sesh
                foreach ( $line in $ret.output) { 
                    if ( $line -match "\S+\s+\d+\s+\d+\s+\d+\s+(\d+)%\s(\/\S*)$" )  {
                        [string]$mount = $matches[2]
                        [int]$consumed = $matches[1]

                        #looks like a disk mount point.
                        it "has less than 80% consumed space on $mount" {
                            $consumed | Should BeLessThan 80
                        }
                        Write-Verbose "$mount consumed space : $consumed"
                    }
                }
                #Tear down
                Remove-SshSession -SshSession $sesh | out-null
            }
        }
        }
}