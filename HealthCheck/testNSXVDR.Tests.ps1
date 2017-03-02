#VMware NSX Healthcheck test
#NSX VDR Port tests
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

Write-Host "Please provide the Compute Cluster name [example: Compute Cluster A1]: " -ForegroundColor Darkyellow -NoNewline
$vdrTestClusterName = Read-Host

Write-Host "Please provide Cluster's VDS name [example: Compute_VDS]: " -ForegroundColor Darkyellow -NoNewline
$vdrTestVDSName = Read-Host

Write-Host "Please provide VDN ID [example: 10000]: " -ForegroundColor Darkyellow -NoNewline
$vdrTestVDSID = Read-Host

$result = $false
Write-Host "`n"
Describe "NSX VDR Port Tests" {
    Write-Host "Cluster $vdrTestClusterName"

	Get-Cluster -Name $vdrTestClusterName | Get-VMHost | %{
		$esxcli = Get-EsxCli -VMHost $_
		$_.toString()
		$esxcli.network.vswitch.dvs.vmware.vxlan.network.port.list($vdrTestVDSName,"vdrPort",$vdrTestVDSID) | Measure-Object | %{
			#Write-Host "Count in main test file is:" $_.Count
			if ($_.Count -eq 1) {
				#$_.Count.toString()+" vdrPort was found"
				$result = $true}else{
				#Write-Host -foregroundcolor "Red" "No vdrPort found"
				$result = $false
			}
		}
	}

    it "got VDR deployed" { 
        $result | Should BeExactly $true
    }
}
