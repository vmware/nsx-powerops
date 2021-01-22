Copyright © 2020 VMware, Inc. All Rights Reserved.
SPDX-License-Identifier: MIT
# NSX Power Operations - An NSX-T Operationalization Project

![logo](logo.png)

### Overview
The NSX-T PowerOps OVA works in conjunction with NSX-T PowerOps.  For easy installation and use, download and deploy this OVA, then clone nsx-powerops to the virtual machine in the /home/powerops directory

### Build & Run
To run NSX-T PowerOps:

1. Download and deploy the nsxt-powerops OVA

2. Once deployed, git clone the repo:
    * cd /home/powerops
    * git clone https://github.com/vmware/nsx-powerops.git

2. Modify the config.yml with all your informations (NSX IP or FQDN, output folder for XLS files)

3. Upload the certificate and key files to /home/powerops/cert if using certificate based Principal Identity
    
4. Source 'run_powerops' from /home/powerops/nsx-powerops (source ./run_powerops) 

