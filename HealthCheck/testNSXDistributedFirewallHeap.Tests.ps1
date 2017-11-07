Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
## Test for DFW Memory heap usage
#a: Anthony Burke - @pandom_
#c: (dcoghland for original idea and initial code, nbradford for sanity checks)

<#
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

## Initiate Test sequence
$dfwheaplimit = 20
[pscustomobject]$HostCredentialHash=@{}
Write-Host "`nProvide one password for all hosts? Y or N [default Y]: " -ForegroundColor Darkyellow -NoNewline
$singlrHostsPass = Read-Host
Write-Host "You have Entered: $singlrHostsPass"

if ($singlrHostsPass -eq 'Y' -or $singlrHostsPass -eq 'y' -or $singlrHostsPass -eq ''){
    $esxicred = Get-Credential -Message "All ESXi Host(s) Credentail" -UserName "root"
    $HostCredentialHash["ALL"] = $esxicred
}

Describe "Distributed Firewall Memory heaps"{    
    #Filter vSphere clusters for DFW enabled ones.
    $DfwClusters = get-cluster -Server $NSXConnection.ViConnection | % {
        $currclus = $_
        if (($currclus | get-nsxclusterstatus -connection $NSXConnection| ? { $_.featureId -eq 'com.vmware.vshield.firewall' }).Installed -eq 'true') {
            $currclus
        }
    }

    $vSphereHosts = $DfwClusters | get-vmhost -Server $NSXConnection.ViConnection
    #Iterate the dfw enabled hosts.
    foreach ( $hv in $vSphereHosts ) {
        Write-Host "vSphere Host $($hv.name)"
        #Test setup
        #If host has specific credentials, then use them, otherwise, use the default.
        if ( $HostCredentialHash.Contains($hv) ) {
            $esxicred = $HostCredentialHash.$hv.Credential
        }elseif ($HostCredentialHash.Contains("ALL") ) {}
        else {
            ##$esxicred = $DefaultHostCredential
            $esxicred = Get-Credential -Message "ESXi Host $hv.name Credentails" -UserName "root"
        }

        #Connect
        $esxi_SSH_Session = New-SSHSession -ComputerName $hv -Credential $esxicred -AcceptKey -ErrorAction Ignore

        it "is reachable via ssh" {
            $esxi_SSH_Session.Connected | should be $true
        }
        
        if ( $esxi_SSH_Session.Connected -eq $true ) {

            #Get system heaps.
            $vsish_object_1 = Invoke-SSHCommand -SshSession $esxi_SSH_Session -Command "vsish -e ls /system/heaps|grep vsip" -EnsureConnection -ErrorAction Ignore

            it "returns system heaps" { 
                $vsish_object_1 | should not be blank
            }

            if ( $vsish_object_1 ) { 
                foreach ($heap in $vsish_object_1.output) {

                    #For each heap listed, to check heap memory remaining.
                    $line = (Invoke-SSHCommand -SshSession $esxi_SSH_Session -Command "vsish -e get /system/heaps/$heap'stats'" -EnsureConnection).output | ? { $_ -match "(percent free of max size):(\d{1,3})" }
                    
                    # Based on the regex output, use matches and PShould to determine remaining memory is more than limit (ex:80 is more than 20)
                    It "has not exceeded the $(100-$dfwheaplimit)% memory threshold on memory heap $heap for $hv" {
                        $matches[2] | Should BeGreaterThan $dfwheaplimit
                    }
                    Write-Verbose "Heap $heap : $line"
                }
                Remove-SshSession -SshSession $esxi_SSH_Session | out-null
            }
        }
    }
}
