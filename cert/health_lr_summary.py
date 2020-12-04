#############################################################################################################################################################################################
#                                                                                                                                                                                           #
# NSX-T Power Operations                                                                                                                                                                    #
#                                                                                                                                                                                           #
# Copyright 2020 VMware, Inc.  All rights reserved				                                                                                                                            #
#                                                                                                                                                                                           #
# The MIT license (the “License”) set forth below applies to all parts of the NSX Power Operations project.  You may not use this file except in compliance with the License.               #
#                                                                                                                                                                                           #
# MIT License                                                                                                                                                                               #
#                                                                                                                                                                                           #
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),                                        #
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,                                        #
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:                                                #
#                                                                                                                                                                                           #
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.                                                            #
#                                                                                                                                                                                           #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                                       #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,                             #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                #
#                                                                                                                                                                                           #
# *--------------------------------------------------------------------------------------* #                                                                                                #
# **************************************************************************************** #                                                                                                #
#   VMware NSX-T PowerOps by @dominicfoley & @stephensauer                                 #                                                                                                #
#   A day 2 operations tool for helping to document and healthcheck an NSX-T environment   #                                                                                                #
# **************************************************************************************** #                                                                                                #
# *--------------------------------------------------------------------------------------* #                                                                                                #
#                                                                                                                                                                                           #
#############################################################################################################################################################################################

import requests
import urllib3
from _cert import Crt, Key, headers, nsx_mgr

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def main():
    session = requests.session()
    session.verify = False
    session.cert = (Crt, Key)

    ########### LIST Logical Routers  ###########
    lr_list_url = '/api/v1/logical-routers'
    lr_list_json = requests.get(nsx_mgr + str(lr_list_url), headers=headers, cert=(Crt, Key), verify=session.verify).json()

    total_lrs = lr_list_json["result_count"]
    
    tier0s = 0
    tier0vrfs = 0
    tier1s = 0

    for i in lr_list_json["results"]:
        if i['router_type'] == 'TIER0': 
            tier0s +=1
        elif i['router_type'] == 'VRF': 
            tier0vrfs +=1
        elif i['router_type'] == 'TIER1':
            tier1s +=1

    print('')
    print('Tier0 Logical Routers: ',tier0s)
    print('Tier0 VRFs: ',tier0vrfs)
    print('Tier1 Logical Routers: ',tier1s)
    print('')
    print('Total Number of Logical Routers: ',total_lrs)
    print('')
    
    for i in lr_list_json["results"]:
        print('')
        print('Name: ',i['display_name'])
        print('Router Type: ',i['router_type'])
        print('HA Mode: ',i['high_availability_mode'])
    
    print('')
    print('')
    
if __name__ == "__main__":
    main()