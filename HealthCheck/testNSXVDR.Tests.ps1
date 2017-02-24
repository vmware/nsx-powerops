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

Describe "Basic System Time Tests" {
    Given "NSX Manager $($NsxConnection.Server)" {
        $router = Get-NsxLogicalRouter -connection $NsxConnection
        $routerStatus = $router.status
        it "is got VDR deployed" { 
            $routerStatus | Should BeExactly "deployed"
        }
        Write-Verbose "Status of VDR is : $routerStatus"
    }
}