Copyright © 2017 VMware, Inc. All Rights Reserved.
SPDX-License-Identifier: MIT
# NSX PowerOps - An NSX-v Operationalization Project </h1>

### Overview
NSX Power Operations (nsx-powerops) is a platform that provides NSX users a way to document their NSX-v environment in Microsoft Excel and Visio files that are easily consumable and referable. The documentation not only captures the Desired State (configuration) but also the Realized State (for example: routing & forwarding tables) across the distributed environment. The platform also embeds rich healthcheck tools.

### Releases & Major Branches
Current version: BETA

### Documentation
http://www.vcdx248.com/

### Prerequisites
Required Pre-Requisites:

* Prereq 1: PowerShell 5.1 [KB3191564: https://support.microsoft.com/en-us/help/3191564/update-for-windows-management-framework-5-1-for-windows-8-1-and-window]

* Prereq 2: VMware PowerCLI 6.5.2 [https://code.vmware.com/tool/vsphere-powercli/6.5.2]
    * `install-module -name vmware.powercli`
    * [Only if needed] `Install-Module -Name VMware.VimAutomation.Sdk`

* Prereq 3: Microsoft Excel installed on the local system (tested on Office 365) [https://products.office.com/en-us/excel]

* Prereq 4: Access to NSX Manager API with privileges (min Read)

* Prereq 5: Access to vSphere Web Client and Privileges (min Read)

* Prereq 6: VMware PowerNSX 3.0.1012 (NSX PowerOps automatically install this module)

* Prereq 7: Pester (NSX PowerOps automatically install this module)

        Pester - PowerShell's Testing Framework Module - Manual Install Steps:
        [http://www.powershellmagazine.com/2014/03/12/get-started-with-pester-powershell-unit-testing-framework/]
        Highlevel steps:
            * Right click on the zip file and hit properties. Click Unblock. Do it before unzipping to save time.
            * Extract the file and put the folder under: [C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\Pester] such that all the files are under folder Pester in the Modules directory.
            * Run PowerCLI as Administrator and execute following commands
                * Get-Module -ListAvailable -Name Pester
                * Import-Module Pester
                * Get-Module -Name Pester | Select -ExpandProperty ExportedCommands

* Prereq 8: Posh-SSH (NSX PowerOps automatically install this module)

        Posh-SSH - PowerShell's SSH Module - Manual Install Steps:
        * Option 1:
            * Run PowerCLI as Administrator and execute: iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")

    	* Option 2:
        	* Download the Module [https://github.com/darkoperator/Posh-SSH/archive/master.zip]
        	* Extract the files under [C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\Posh-SSH] such that all the files are under folder Posh-SSH in the Modules directory.
        	* Run PowerCLI as Administrator and execute following commands
        		* Get-Module -ListAvailable -Name Posh-SSH
        		* Import-Module Posh-SSH
        		* Get-Module -Name Posh-SSH | Select -ExpandProperty ExportedCommands


Optional Pre-Requisites:

* MS VISIO 2013 activated (optional - some feature wont work if not installed) [https://products.office.com/en-us/microsoft-visio-2013]
NOTE: NOT supported with VISIO Trial or 365 activated version
* GIT (optional) [https://git-scm.com/]

### Download via git
    git clone https://github.com/vmware/nsx-powerops.git    

### Build & Run
Note: For PowerCLI to work correctly: 'Set-ExecutionPolicy RemoteSigned' in powercli

Step 1: Run the ./nsx-PowerOps.ps1 in PowerShell terminal [tested on VMware PowerCLI 6.5.2]

Step 2: When in nsx-PowerOps.ps1:
* To get help type 'h'
* To return to previous menu type 'x'
* To quit the program type 'q'

Step 3: Install NSX PowerOps depedency (PowerNSX, Pester, Posh-SSH) by selecting option # 1

Step 4: Connect with NSX Manager and vCenter by selecting option # 2

### Contributing
The nsx-powerops project team welcomes contributions from the community. Before you start working with nsx-powerops, please read our [Developer Certificate of Origin](https://cla.vmware.com/dco). All contributions to this repository must be signed as described on that page. Your signature certifies that you wrote the patch or have the right to pass it on as an open-source patch. For more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).

### License
NSX Power Operations

Copyright 2017 VMware, Inc.  All rights reserved				

The MIT license (the ìLicenseî) set forth below applies to all parts of the NSX Power Operations project.  You may not use this file except in compliance with the License.†

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Notice
NSX Power Operations

Copyright (c) 2017 VMware, Inc. All Rights Reserved. 

This product is licensed to you under the MIT license (the "License").  You may not use this product except in compliance with the MIT License.  

This product may include a number of subcomponents with separate copyright notices and license terms. Your use of these subcomponents is subject to the terms and conditions of the subcomponent's license, as noted in the LICENSE file. 

### Contact Info
Puneet Chawla (cpuneet@vmware.com) and Hammad Alam (halam@vmware.com)
