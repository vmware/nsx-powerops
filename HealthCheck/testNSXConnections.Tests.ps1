<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
#NSX Core tests
#Nick Bradford
#nbradford@vmware.com

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

Describe "Basic System Connectivity and Time Tests" {
    Write-host "NSX Manager: $($NsxConnection.Server)"
    $vCenterStatus = Get-NsxManagervCenterConfig -connection $global:NsxConnection

    #vCenter Connected Check
    It "is connected to vCenter" { 
        $vCenterStatus.Connected | should be $true
    }
    Write-Verbose "vCenter Server : $($vCenterStatus.IpAddress), Connected : $($vCenterStatus.Connected)"

    $nsxTime = Get-NsxManagerTimeSettings -connection $NsxConnection
    $MaxDriftMinutes = 5
    $totalAbsMinsDrift = [math]::abs(([datetime]($nsxTime).datetime - (get-date)).totalminutes)
    #Timezone sync test
    it "is within 5 minutes of the local system time (Note:  Local system and NSX Manager must be in same TimeZone)" { 
        $totalAbsMinsDrift | Should BeLessThan $MaxDriftMinutes  
    }
    Write-Verbose "Total absolute minutes drift between local host and NSX Manager : $totalAbsMinsDrift"
}