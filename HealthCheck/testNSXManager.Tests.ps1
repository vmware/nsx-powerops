#VMware NSX Healthcheck test
#NSX Manager tests
#Nick Bradford
#nbradford@vmware.com

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

Describe "NSX Manager" {

    $vCenterStatus = Get-NsxManagervCenterConfig -connection $global:NsxConnection

    #vCenter Connected Check
    It "is connected to vCenter" { 
        $vCenterStatus | should be $true
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

    if ($Someimaginaryflagforuniversalandimaprimary ) { 

        it "has the NSX Replicator Service in a running state" { 
            ($ComponentSummary | ? { $_.name -match 'NSX Replicator'}).status | should match RUNNING
        }
        Write-Verbose "Enabled: $(($ComponentSummary | ? { $_.name -match 'NSX Replicator'}).enabled), Running $(($ComponentSummary | ? { $_.name -match 'NSX Replicator'}).status)"
    }
    else {

        it "is not a cross VC NSX deployment, skipping universal sync service check" {}
    }

}

