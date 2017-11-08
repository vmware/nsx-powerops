<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

#VMware NSX Healthcheck test
#NSX Manager tests
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

Describe "NSX Manager" {

    $vCenterStatus = Get-NsxManagervCenterConfig -connection $global:NsxConnection

    #vCenter Connected Check
    It "is connected to vCenter" { 
        $vCenterStatus.Connected | should be $true
    }
    Write-Verbose "vCenter Server : $($vCenterStatus.IpAddress), Connected : $($vCenterStatus.Connected)"

    #Last inventory check
    #Define the start of the universe
    [datetime]$origin = '1970-01-01 00:00:00'
    $lastInventory = $origin.AddMilliseconds($($vCenterStatus.vcInventoryLastUpdateTime))
    
    $MaxLastInventoryAgeMinutes = 30 #minutes
    $LastInventoryAgeMinutes = [math]::abs(($lastInventory - ((get-date).toUniversalTime())).totalminutes)
    It "performed an Inventory less than $MaxLastInventoryAgeMinutes minutes ago" {
        $LastInventoryAgeMinutes | Should BeLessThan $MaxLastInventoryAgeMinutes
    }

    Write-Verbose "Last Inventory was $LastInventoryAgeMinutes minutes ago"

    #Check Service State
    $ComponentSummary = (Get-NsxManagerComponentSummary -connection $global:NsxConnection).componentsByGroup.entry.components.component
    it "has the NSX Manager Service in a running state" { 
        ($ComponentSummary | ? { $_.name -match 'NSX Manager'}).status | should match RUNNING
    }
    Write-Verbose "Enabled: $(($ComponentSummary | ? { $_.name -match 'NSX Manager'}).enabled), Running $(($ComponentSummary | ? { $_.name -match 'NSX Manager'}).status)"

    it "has the vPostgres Service in a running state" { 
        ($ComponentSummary | ? { $_.name -match 'vPostgres'}).status | should match RUNNING
    }
    Write-Verbose "Enabled: $(($ComponentSummary | ? { $_.name -match 'vPostgres'}).enabled), Running $(($ComponentSummary | ? { $_.name -match 'vPostgres'}).status)"

    it "has the RabbitMQ Service in a running state" { 
        ($ComponentSummary | ? { $_.name -match 'RabbitMQ'}).status | should match RUNNING
    }
    Write-Verbose "Enabled: $(($ComponentSummary | ? { $_.name -match 'RabbitMQ'}).enabled), Running $(($ComponentSummary | ? { $_.name -match 'RabbitMQ'}).status)"

    it "has the NSX Replicator Service in a running state" {
        ($ComponentSummary | ? { $_.name -match 'NSX Replicator'}).status | should match RUNNING
    }
    Write-Verbose "Enabled: $(($ComponentSummary | ? { $_.name -match 'NSX Replicator'}).enabled), Running $(($ComponentSummary | ? { $_.name -match 'NSX Replicator'}).status)"

}

