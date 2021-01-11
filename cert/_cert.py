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
#
###  IN ORDER TO USE NSX-T PRINCIPAL IDENTITY CERTIFICATE BASED AUTHENTICATION, PLEASE ADHERE TO THE FOLLOWING:
###
###  1) CREATE A CERTIFICATE FOR USE WITH POWEROPS
###  2) CREATE AN NSX-T PRINCIPAL IDENTITY USER WITH THE CERTIFICATE AND KEY FILE FROM STEP 1) - AUDIT RIGHTS IS FINE
###  3) COPY THE .crt AND .key FILES to /home/powerops/cert FOLDER
###  4) MODIFY THE BELOW 'Crt' & 'Key' LINES TO REFLECT THE CORRECT FILENAMES
###  5) MODIFY THE 'nsx_mgr' LINE BELOW TO BE THE FQDN OF YOUR NSX-T MANAGER - 'https://<FQDN>
###
#############################################################################################################################################################################################

Crt = "/home/powerops/cert/<CERTIFICATE NAME>.crt"
Key = "/home/powerops/cert/<CERTIFICATE KEY>.key"
headers = {'Content-type': 'application/json'}
nsx_mgr = 'https://<NSX MANAGER FQDN>'

import requests
import json
import urllib, urllib3
import getpass

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

session = requests.session()
session.verify = False
session.cert = (Crt, Key)
try:
    req = requests.get(nsx_mgr + '/api/v1/node', headers=headers, cert=session.cert, verify=session.verify)
    response=str(req)
except:
    response = 'Failed'
    quit
