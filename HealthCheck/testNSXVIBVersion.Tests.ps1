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

Write-Host "`nProvide one password for all hosts? Y or N [default Y]: " -ForegroundColor Darkyellow -NoNewline
$singlrHostsPass = Read-Host
Write-Host "You have Entered: $singlrHostsPass"

if ($singlrHostsPass -eq 'Y' -or $singlrHostsPass -eq 'y' -or $singlrHostsPass -eq ''){
    $esxicred = Get-Credential -Message "All ESXi Host(s) Credentail" -UserName "root"
    $HostCredentialHash["ALL"] = $esxicred
}

Describe "NSX VIB Versions"{
    Write-Host -ForegroundColor Yellow "WARNING: Currently this test checks all clusters including those NOT prepared for NSX."
    Write-Host -ForegroundColor Yellow "Please ignore them as false alerts."
    $vSphereHosts = get-vmhost -Server $NSXConnection.ViConnection
    #Getting all hosts.
    foreach ( $hv in $vSphereHosts ) {
        $ESXi_VIBVersionArray=@()
        Write-Host "vSphere Host $($hv.name)"
        #Test setup
        #If host has specific credentials, then use them, otherwise, use the default.
        if ( $HostCredentialHash.Contains($hv) ) {
            $esxicred = $HostCredentialHash.$hv.Credential
        }elseif ($HostCredentialHash.Contains("ALL") ) {}
        else {$esxicred = Get-Credential -Message "ESXi Host $hv.name Credentails" -UserName "root"}

        #Connect
        $esxi_SSH_Session = New-SSHSession -ComputerName $hv -Credential $esxicred -AcceptKey -ErrorAction Ignore

        it "ESXi is reachable via ssh" {
            $esxi_SSH_Session.Connected | should be $true
        }
        
        if ( $esxi_SSH_Session.Connected -eq $true ) {

            #Get VIB info.
            #$ESXi_VIBInfo = Invoke-SSHCommand -SshSession $esxi_SSH_Session -Command "esxcli software vib get --vibname esx-vxlan" -EnsureConnection -ErrorAction Ignore
            $ESXi_VIBInfo = Invoke-SSHCommand -SshSession $esxi_SSH_Session -Command "esxcli software vib list | grep esx-v" -EnsureConnection -ErrorAction Ignore

            it "SSH returned VIBs info" { 
                $ESXi_VIBInfo | should not be blank
            }

            if ( $ESXi_VIBInfo ) {
                foreach ($vib in $ESXi_VIBInfo.output) {
                    $cleanvib = $vib -replace '\s+', ' '
                    $a,$b,$c = $cleanvib.split(' ')
                    $ESXi_VIBVersion =  $b
                    $ESXi_VIBVersionArray = $ESXi_VIBVersionArray+$ESXi_VIBVersion
                    $global:env_VIBVersionArray = $global:env_VIBVersionArray+$ESXi_VIBVersion
                    it "$a VIB Version same as desired VIB version" { 
                        $ESXi_VIBVersion | Should BeExactly $desiredVIBVersion
                    }
                }
                $uniqueVIBVersionArray=$ESXi_VIBVersionArray | select -unique
                it "All VIB Versions are same accross the host $hv.name" {$uniqueVIBVersionArray.count -eq 1 | Should Be $true}
            }
                Remove-SshSession -SshSession $esxi_SSH_Session | out-null
        }
    }
    Write-Host "NSX Environment - All Hosts"
    if ( $global:env_VIBVersionArray.count -gt 1 ) {
        $uniqueEnvVIBVersionObj=$env_VIBVersionArray | select -unique
        it "All VIB Versions are same accross the Environment" {$uniqueEnvVIBVersionObj.count -eq 1 | Should Be $true}
    }
}