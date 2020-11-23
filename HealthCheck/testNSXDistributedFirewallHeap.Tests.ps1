<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
## Test for DFW Memory heap usage
#a: Anthony Burke - @pandom_
#c: (dcoghland for original idea and initial code, nbradford for sanity checks)

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

$script:yesnochoices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
$script:yesnochoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
$script:yesnochoices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

Describe "Distributed Firewall Memory heaps"{   
    
    BeforeAll { 
        $script:dfwheaplimit = 20
        if ( -not $nonInteractive ) {

            if ( -not $global:EsxiHostCredential ) { 
                $message  = "No default credentials available."
                $question = "Provide default credentials for all hosts?"
                $decision = $Host.UI.PromptForChoice($message, $question, $yesnochoices, 1)
                
                if ($decision -eq 0 ){
                    $script:EsxiHostCredential = Get-Credential -Message "All ESXi Host(s) Credential" -UserName "root"
                }
            }
        }
        
        #Filter vSphere clusters for DFW enabled ones.
        $DfwClusters = get-cluster -Server $NSXConnection.ViConnection | % {
            $currclus = $_
            if (($currclus | get-nsxclusterstatus -connection $NSXConnection| ? { $_.featureId -eq 'com.vmware.vshield.firewall' }).Installed -eq 'true') {
                $currclus
            }
        }

        $script:vSphereHosts = $DfwClusters | get-vmhost -Server $NSXConnection.ViConnection

    }

    #Iterate the dfw enabled hosts.
    foreach ( $hv in $script:vSphereHosts ) {
        #Connect
        try { 
            $esxi_SSH_Session = New-SSHSession -ComputerName $hv -Credential $EsxiHostCredential -AcceptKey -erroraction stop
        }
        catch [Renci.SshNet.Common.SshAuthenticationException] {
            if ( -not $noninteractive ) { 
                write-warning "Default host credentials were not accepted by $($hv.name)."
                $EsxiHostCredential = Get-Credential -Message "ESXi Host $hv.name Credentails" -UserName "root" -ErrorAction ignore    
                $esxi_SSH_Session = New-SSHSession -ComputerName $hv -Credential $EsxiHostCredential -AcceptKey 
            }
            else { 
                throw "Default host credentials were not accepted by $($hv.name) and test is running in non-interactive mode."
            }
        }
        catch {
            write-warning "An unhandled exception occured connecting to host $($hv.name).  $_"
        }

        it "$($hv.name) is reachable via ssh" {
            $esxi_SSH_Session.Connected | should be $true
        }
        
    

        #Get system heaps.
        $vsish_object_1 = Invoke-SSHCommand -SshSession $esxi_SSH_Session -Command "vsish -e ls /system/heaps|grep vsip" -EnsureConnection -ErrorAction Ignore

        it "$($hv.name) returns system heaps" -skip:(-not $esxi_SSH_Session.Connected) { 
            $vsish_object_1 | should not be blank
        }

        if ( $vsish_object_1 ) { 
            foreach ($heap in $vsish_object_1.output) {

                #For each heap listed, to check heap memory remaining.
                $line = (Invoke-SSHCommand -SshSession $esxi_SSH_Session -Command "vsish -e get /system/heaps/$heap'stats'" -EnsureConnection).output | ? { $_ -match "(percent free of max size):(\d{1,3})" }
                
                # Based on the regex output, use matches and PShould to determine remaining memory is more than limit (ex:80 is more than 20)
                It "$($hv.name) has not exceeded the $(100-$dfwheaplimit)% memory threshold on memory heap $heap for $hv" {
                    $matches[2] | Should BeGreaterThan $dfwheaplimit
                }
                Write-Verbose "Heap $heap : $line"
            }
            Remove-SshSession -SshSession $esxi_SSH_Session | out-null
        }
    }
}
