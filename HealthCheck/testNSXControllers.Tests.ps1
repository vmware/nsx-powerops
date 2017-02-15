#VMware NSX Healthcheck test
#NSX LS/LR Control plane tests
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
# $vCenterSSHConnection = startSSHSession -serverToConnectTo $vCenterHost -credentialsToUse $myvCenterSecureCredential
$NsxControllerCredential = Get-Credential -Message "NSX Controller's Credentails" -UserName "admin"

Describe "NSX Controllers" {
    Giveneach "the NSX controller cluster"{
        [array]$NSXControllers = get-nsxcontroller -connection $NSXConnection
        if ( -not $NSXcontrollers ) {It "has no controller cluster, skipping controller tests" {}}
        else {
            #Setup... 
            #Get the cluster uuid from controller 0
            try {
                $sesh = New-SshSession -ErrorAction Ignore -Credential $NsxControllerCredential -computername $nsxcontrollers[0].ipaddress
                $lines = (Invoke-SSHCommand -SSHSession $sesh "show control-cluster status").output
                $lines | ? { $_ -match "^Cluster ID:\s+(\S+)$" } | out-null
                $clusteruuid = $matches[1]
                Remove-SshSession -SshSession $sesh | out-null
            }catch {}

            It "has the supported number of controller nodes" { 
                $NsxControllers.Count | Should be 3
            }
            
                foreach ( $controller in $NsxControllers ) {
                Giveneach "Controller $($Controller.id)" { 

                    try { 
                        $sesh = New-SshSession -ErrorAction Ignore -credential $NsxControllerCredential -computername $controller.ipaddress
                    }
                    catch {

                    }
                    
                    #Check status in API
                    
                    it "has a RUNNING status in API" { 
                        $controller.Status  | should be "RUNNING"
                    }
                    Write-Verbose $controller.status
                    
                    #is it ssh reachable?
                    it "is reachable via ssh at $($controller.ipaddress)" { 
                        $sesh.Connected | should be $true
                    }

                    if ( $sesh.Connected ) {
                        Write-Verbose "$($Sesh.Host) : $($Sesh.Connected)"

                        #Check that the clusteruuid we got back looks validish...
                        it "has a valid cluster uuid" {
                            [guid]::tryparse($clusteruuid, [ref][guid]::NewGuid()) | should be true
                        }
                        Write-Verbose "Clusteruuid from first node: $clusteruuid"

                        #Check ipsec tunnel status
                        $ipsectunnels = (Invoke-SSHCommand -SSHSession $sesh "show control-cluster network ipsec tunnels").output | ? { $_ -match 'Security Associations' }
                        it "has $($nsxcontrollers.count - 1) IPSec SAs up, and 0 connecting" {    
                            #Test that we have SAs up with other controllers.    
                            $ipsectunnels | Should BeExactly "Security Associations ($($nsxcontrollers.count - 1) up, 0 connecting):"
                            #Security Associations (2 up, 0 connecting):
                        }
                        Write-Verbose $ipsectunnels

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
    }
}