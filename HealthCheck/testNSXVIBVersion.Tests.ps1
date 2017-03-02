#VMware NSX Healthcheck test
#NSX Core tests
#Puneet Chawla
#cpuneet@vmware.com

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
    $vSphereHosts = get-vmhost -Server $NSXConnection.ViConnection
    #Getting all hosts.
    foreach ( $hv in $vSphereHosts ) {
        $ESXi_VIBVersionArray=@()
        GivenEach "vSphere Host $($hv.name)" {
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
    }
    GivenEach "NSX Environment - All Hosts" {
        if ( $global:env_VIBVersionArray.count -gt 1 ) {
            $uniqueEnvVIBVersionObj=$env_VIBVersionArray | select -unique
            it "All VIB Versions are same accross the Environment" {$uniqueEnvVIBVersionObj.count -eq 1 | Should Be $true}
        }
    }
}