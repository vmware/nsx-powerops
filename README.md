Copyright © 2020 VMware, Inc. All Rights Reserved.
SPDX-License-Identifier: MIT
# NSX Power Operations - An NSX-T Operationalisation Project

![logo](logo.png)

### Overview
NSX Power Operations is a platform that provides NSX users a way to document and healthcheck their VMware NSX-T environment.  Through a series of python scripts, you have the ability to output healthchecks to the terminal or output documentation option in Microsoft Excel format that are easily consumable and referable. The documentation not only captures the Desired State (configuration) but also the Realized State (for example: routing & forwarding tables) across the distributed environment. 

### Releases & Major Branches
Current version: Supports NSX-T 3.x API (December 2020)

NSX-T PowerOps does not perform any ESXi Commands to retrieve data.

NSX-T PowerOps authenticates to NSX-T Manager only

NSX-T PowerOps Master branch is for PowerOps-CLI (see below for PowerOps-UI)

### NSX-T PowerOps-UI
For the UI Version of NSX-T PowerOps, please go to: https://github.com/vmware/nsx-powerops/tree/NSX-T-PowerOps-UI

### PowerOps OVA Install
1. The easiest method to build and run NSX-T PowerOps is to download the nsxt-powerops ova:

       https://drive.google.com/file/d/1VMFGne92ygtY6vhYXACy5_pXti1EuW3N/view?usp=sharing
       
2. Once deployed, login to the powerops VM and ensure you are in /home/powerops

       Default Username / Password:  powerops/powerops

3. Git clone the NSX-T-PowerOps repo:
       
       git clone https://github.com/vmware/nsx-powerops.git

4. Modify the config.yml with all the relevant information (NSX IP or FQDN, cert path, output folder for XLS files)

      Please see 'Optional Pre-Requisite' below for details on Principal Identity certificate authentication

5. Source 'run_powerops' from /home/powerops/nsx-powerops (source ./run_powerops)


#### Required Pre-Requisites for manual installation:

If you prefer a manual installation, you will need to prepare an environment (for example an 'NSX-T PowerOps' Virtual Machine) with the following:

1. Python 3.x (3.8 preference)
2. Python Module 'xlwt'
3. VMware NSX-T Python SDK
4. Git
5. Access to NSX Manager API with Read Privileges
6. Correct Directory Structure

Example installation using Ubuntu 20.04:

1. Create Ubuntu PowerOps Virtual Machine:
    * Set IP address, Hostname, DNS, etc...
    * Ubuntu 20.04 comes wityh Python 3.8.6 pre-installed
2. Install 'xlwt':
    * pip3 install xlwt
3. Download and install the NSX-T SDK for Python:
    * Download the VMware NSX-T Data Center Automation SDK 3.0.0 for Python from https://code.vmware.com/web/sdk/3.0/nsx-t-python
        * Download all files and copy to VM
    * Install the SDK .whl files using pip3
        * Example: 'python3.8 -m pip install vapi_runtime-2.14.0-py2.py3-none-any.whl' 
4. Install Git
    * sudo apt-get install git
5. Create a 'powerops' user (by default scripts refer to 'powerops' user)
6. Create the following directories under /home/powerops:
    * cert (/home/powerops/cert)
    * powerops_documentation (/home/powerops/powerops_documentation)

#### Optional Pre-Requisite:
If you wish to use PowerOps with a Pricipal Identity Certificate Based user, please create your Principal Identity user in NSX-T and have access to the certificate and key files. Files must be in .crt and .key extension.

1. Copy the certificate and key files into a folder
2. Modify the config.yml (/home/powerops/nsx-powerops/config.yml) file with the folder containing cert and key file 
   (you must do this AFTER cloning the nsx-powerops repo)

### Build & Run
To run NSX-T PowerOps:

1. From /home/powerops git clone the repo (following will clone the master branch of NSX-T PowerOps):
    * `git clone https://github.com/vmware/nsx-powerops.git`

2. Modify the config.yml with all the relevant information (NSX IP or FQDN, cert path, output folder for XLS files)
    
3. Source 'run_powerops' from /home/powerops/nsx-powerops (source ./run_powerops) 

### Contributing
The NSX-PowerOps project team welcomes contributions from the community. Before you start working with NSX-PowerOps, please read our [Developer Certificate of Origin](https://cla.vmware.com/dco). All contributions to this repository must be signed as described on that page. Your signature certifies that you wrote the patch or have the right to pass it on as an open-source patch. For more detailed information, refer to the [Contribution Guidelines](CONTRIBUTING.md).

### License 
NSX Power Operations

Copyright 2020 VMware, Inc.  All rights reserved                

The MIT license (the ìLicenseî) set forth below applies to all parts of the NSX Power Operations project.  You may not use this file except in compliance with the License.†

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Notice
NSX Power Operations

Copyright (c) 2020 VMware, Inc. All Rights Reserved. 

This product is licensed to you under the MIT license (the "License").  You may not use this product except in compliance with the MIT License.  

This product may include a number of subcomponents with separate copyright notices and license terms. Your use of these subcomponents is subject to the terms and conditions of the subcomponent's license, as noted in the LICENSE file. 

### Contact Info
Dominic Foley (dfoley@vmware.com) and Stephen Sauer (sauers@vmware.com)
