<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
#NSX Core tests
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


#I need... 
# $NsxConnection in global scope
# Use this test to confirm connectivity / readiness of system to run test suite.

$ESXi_VIBVersionArray=@()
$global:env_VIBVersionArray=@()
[pscustomobject]$HostCredentialHash=@{}
Write-Host "`nPlease Enter the desired VIB version (eg: 6.0.0-0.0.4249023):" -ForegroundColor Darkyellow -NoNewline
$desiredVIBVersion = Read-Host

# Get NSX Server version
[int]$nsxVersion = [convert]::ToInt32($NsxConnection.Version.Replace(".",""),10)

Describe "NSX VIB Versions"{
    # collect hosts from NSX prepared clusters only
    $vSphereHosts = @()
    Get-cluster | %{
        if((Get-NsxClusterStatus $_ | ?{$_.featureid -eq "com.vmware.vshield.vsm.nwfabric.hostPrep"}).installed -eq "true"){
            $vSphereHosts += $_ | Get-VMHost -Server $NSXConnection.ViConnection
        }
    }

    #Getting all hosts.
    foreach ( $hv in $vSphereHosts ) {

        # Reset VIB Version array for every host
        $ESXi_VIBVersionArray=@()
        
        # Initialise Esxcli
        $esxcli = Get-EsxCli -VMHost $hv.name -v2

        # Get ESXi server version
        [int]$esxVersion = [convert]::ToInt32($esxcli.system.version.get.Invoke().version.replace(".",""),10)

        # Get VIB info
        if (($nsxVersion -ge 633) -and ($esxVersion -ge 600)) {
            $ESXi_VIBInfo = $esxcli.software.vib.list.Invoke() | ?{$_.name -match "esx-nsxv"}
            
            # In case VIBs are not upgraded yet
            if(!$ESXi_VIBInfo){
                $ESXi_VIBInfo = $esxcli.software.vib.list.Invoke() | ?{$_.name -match "esx-v"}
            }
        }
        else{
            $ESXi_VIBInfo = $esxcli.software.vib.list.Invoke() | ?{$_.name -match "esx-v"}
        }
            
        it "Esxcli returned VIBs info" { 
            $ESXi_VIBInfo | should not be blank
        }

        if ($ESXi_VIBInfo) {
            foreach ($vib in $ESXi_VIBInfo) { 
                $ESXi_VIBVersionArray = $ESXi_VIBVersionArray+$vib.version
                $global:env_VIBVersionArray = $global:env_VIBVersionArray+$vib.version
                it "$($vib.name) VIB Version same as desired VIB version" { 
                    $vib.version | Should BeExactly $desiredVIBVersion
                }
            }
            $uniqueVIBVersionArray=$ESXi_VIBVersionArray | select -unique
            it "All VIB Versions are same accross the host $hv.name" {$uniqueVIBVersionArray.count -eq 1 | Should Be $true}
        }

        write-host
    }
    Write-Host "NSX Environment - All Hosts"
    if ( $global:env_VIBVersionArray.count -gt 1 ) {
        $uniqueEnvVIBVersionObj=$env_VIBVersionArray | select -unique
        it "All VIB Versions are same accross the Environment" {$uniqueEnvVIBVersionObj.count -eq 1 | Should Be $true}
    }
}