# NSX Power Operations - An NSX-T Operationalisation Project


## Overview
NSX Power Operations is a platform that provides NSX users a way to document and healthcheck their VMware NSX-T environment. Through a series of API calls, you have the ability to output healthchecks and export it in Microsoft Excel, CSV, JSON and YAML formats, that are easily consumable and referable. The documentation not only captures the Desired State (configuration) but also the Realized State (for example: routing & forwarding tables) across the distributed environment.
You also have the ability to make some comparaison between an old state (by loading a precedent JSON or YAML export file) and the current on each healthchecks.

![Semantic description of image](src/assets/images/screenshot.png)

## Releases & Major Branches
Current version: Supports NSX-T 3.x API (December 2020)

## PowerOps Docker install
Powerops UI is a Web app application. It need a small web server for hosting, and use also a small API proxy python script on this server, to relay API calls from the web browser to NSX-T Manager. 

Build Powerops from the given dockerfile (don't forget the dot at the end of the command): 

docker build -t powerops .

Run the docker command: 
docker run -it -d --name powerops -p 8100:80 -p8080:8080  powerops

## Build PowerOps from github (Angular)
To build PowerOps

1. From /home/powerops git clone the NSX-T-PowerOps-UI branch of the repo:
    * `git clone https://github.com/vmware/nsx-powerops.git --branch NSX-T-PowerOps-UI --single-branch`

2. Run `ng build --prod --build-optimizer=false` to build PowerOps. The build artifacts will be stored in the `dist/` directory.


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
Dominic Foley (dfoley@vmware.com), Stephen Sauer (sauers@vmware.com), Yann Simonet (ysimonet@vmware.com)

