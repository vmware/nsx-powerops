Copyright © 2020 VMware, Inc. All Rights Reserved.
SPDX-License-Identifier: MIT
# NSX Power Operations - An NSX-T Operationalization Project

![logo](logo.png)

### Overview
NSX Power Operations is a platform that provides NSX users a way to document and healthcheck their VMware NSX-T environment.  Through a series of python scripts, you have the ability to output healthchecks to the terminal or output documentation option in Microsoft Excel format that are easily consumable and referable. The documentation not only captures the Desired State (configuration) but also the Realized State (for example: routing & forwarding tables) across the distributed environment. 

### Releases & Major Branches
Current version: Supports NSX-T 3.x API (December 2020)
Current version of NSX-T PowerOps supports 1000 objects per API call.  Pagination issues currently being worked on.

#### Required Pre-Requisites:

Prepare an environment (for example an 'NSX-T PowerOps' Virtual Machine) with the following:

1. Python 3.6
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
    * pip install xlwt
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
    * NSX-T-PowerOps (/home/powerops/NSX-T-PowerOps)
    * NSX-T-PowerOps/lib/powerops/master (/home/powerops/NSX-T-PowerOps/lib/powerops/master)
    * powerops_documentation (/home/powerops/powerops_documentation)
7. Create a 'powerops_basic' file under /home/powerops
    * A single line 'powerops_basic' file as: 'python3 /home/powerops/lib/powerops_master/nsx-powerops/basic/_poweropsmain.py'
8. Create a 'powerops_cert' file under /home/powerops
    * A single line 'powerops_cert' file as: 'python3 /home/powerops/lib/powerops_master/nsx-powerops/cert/_poweropsmain.py'

#### Option Pre-Requisite:

If you wish to use PowerOps with a Pricipal Identity Certificate Based user, please create your Principal Identity user in NSX-T and have accees to
the certificate and key files

1.  Copy the certificate and key files to /home/powerops/cert
2.  Modify the '_cert.py' file with correct filenames (see instructions in file) - CAN ONLY BE DONE AFTER GIT REPO HAS BEEN CLONED

If you wish to use PowerOps with a user different to 'powerops':

1. Modify the following line in the '_createdir.py' file (under both 'cert' and 'basic' folders):
    * 'source = '/home/powerops/powerops_documentation/POps_doc_' '
    * Modify 'powerops' to be your username (DO NOT CHANGE the 'powerops_documentation' part of the line)
2. Modify the /home/<USER>/powerops_cert file 

### Build & Run
To run NSX-T PowerOps:

1. Git clone the repo ( following will clone the correct branch of NSx PowerOps):
    * cd /NSX-T-PowerOps/lib/powerops_master
    * `git clone -b NSX-T-PowerOps --single-branch https://github.com/vmware/nsx-powerops.git`

1. Using basic authentication (username / password):
    * From /home/powerops
        * source ./powerops_basic
2. Using certificate based principal identity:
    * From /home/powerops
        * source ./powerops_cert

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
