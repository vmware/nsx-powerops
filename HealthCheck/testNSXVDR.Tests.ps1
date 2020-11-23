<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
#NSX VDR Port tests
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

Write-Host "Please provide the Compute Cluster name [example: Compute Cluster A1]: " -ForegroundColor Darkyellow -NoNewline
$vdrTestClusterName = Read-Host

Write-Host "Please provide Cluster's VDS name [example: ComputeA_VDS]: " -ForegroundColor Darkyellow -NoNewline
$vdrTestVDSName = Read-Host

Write-Host "Please provide VDN ID [example: 10000]: " -ForegroundColor Darkyellow -NoNewline
$vdrTestVXLANID = Read-Host

$result = $false
Write-Host "`n"
Describe "NSX VDR Port Tests" {
    Write-Host "Cluster $vdrTestClusterName"

	Get-Cluster -Name $vdrTestClusterName | Get-VMHost | %{
		$esxcli = Get-EsxCli -VMHost $_
		Write-Host "Checking Host:", $_
		$_.toString()
		$esxcli.network.vswitch.dvs.vmware.vxlan.network.port.list($vdrTestVDSName,"vdrPort",$vdrTestVXLANID) | Measure-Object | %{
			#Write-Host "Count in main test file is:" $_.Count
			if ($_.Count -eq 1) {$result = $true}
		}
	}

    it "got VDR deployed" {$result | Should BeExactly $true}
}
