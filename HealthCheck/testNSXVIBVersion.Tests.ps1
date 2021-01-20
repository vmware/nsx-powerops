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


# Collecting the VIB versions from the NSX Manager

## ignore certificate validation - temp, until Trust Relationship for SSL/TLS is resolved
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()

## get web page with VIB versions
$URL = "https://$($nsxconnection.server)/bin/vdn/nwfabric.properties"
$webResponse = Invoke-WebRequest -Method get -uri $URL

## Processing the web response
$processedWebResponse = (Select-String \d[.]\d[-]\d+ -input $webResponse.RawContent -AllMatches | Foreach {$_.matches}).Value
$vibMatrix = @{}
foreach($row in $processedWebResponse){
        $vibMatrix[$row.Split("-",2)[0]] = $row.Split("-",2)[0] + ".0-0.0."+ $row.Split("-",2)[1]
}


Describe "NSX VIB Versions"{
    $ESXi_VIBVersionArray=@()
    $env_VIBVersionArray=@()

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
        $esxVersion =  $hv.version.remove(3)

        # Identify latest VIB based on the NSX Manager and ESXi server version
        $desiredVIBVersion = $vibMatrix[$esxVersion]

        # Get VIB info
        $ESXi_VIBInfo = $esxcli.software.vib.list.Invoke() | ?{($_.name -match "esx-nsxv") -or ($_.name -match "esx-v")}
            
        it "Esxcli returned VIBs info" { 
            $ESXi_VIBInfo | should not be blank
        }

        if ($ESXi_VIBInfo) {
            $a = New-Object -TypeName PSobject
            $a | Add-Member -MemberType NoteProperty -Name vibStatus -Value "Ok"
            $env_VIBVersionArray += $a
            foreach ($vib in $ESXi_VIBInfo) {       
                $ESXi_VIBVersionArray = $ESXi_VIBVersionArray+$vib.version
                it "$($vib.name) $($vib.version) VIB Version same as latest VIB version for the current NSX Manager" { 
                    $vib.version | Should BeExactly $desiredVIBVersion
                }
                if($vib.version -ne $desiredVIBVersion){
                    $env_VIBVersionArray.vibStatus = "Fail"
                }
            }
            $uniqueVIBVersionArray=$ESXi_VIBVersionArray | select -unique
            it "All VIB Versions are same accross the host $hv.name" {$uniqueVIBVersionArray.count -eq 1 | Should Be $true}
        }

        write-host
    }
    Write-Host "NSX Environment - All Hosts"
    if ($env_VIBVersionArray.count -gt 1 ) {
        $uniqueEnvVIBVersionObj=$env_VIBVersionArray.vibStatus | select -unique
        it "All VIB Versions accross the environment are up to date" {($uniqueEnvVIBVersionObj.count -eq 1) -and ($uniqueEnvVIBVersionObj -eq "Ok") | Should Be $true}
    }
}
