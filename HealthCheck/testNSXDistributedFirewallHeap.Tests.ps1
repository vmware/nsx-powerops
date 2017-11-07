## Test for DFW Memory heap usage
#a: Anthony Burke - @pandom_
#c: (dcoghland for original idea and initial code, nbradford for sanity checks)

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
