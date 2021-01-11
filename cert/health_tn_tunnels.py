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

    transport_node_url = '/api/v1/transport-nodes'
    transport_node_json = requests.get(nsx_mgr + str(transport_node_url), headers=headers, cert=(Crt, Key), verify=session.verify).json()
    transport_nodes = (transport_node_json['results'])
    tnode_dict = {}
    
    for n in range(len(transport_nodes)):
        tnode_dict.update({transport_nodes[n]['node_id']:transport_nodes[n]['display_name']})
        
    for uuid in tnode_dict.items():
        try:
            tunnel_url = '/api/v1/transport-nodes/' + str(uuid[0]) + '/tunnels'
            tunnel_json = requests.get(nsx_mgr + str(tunnel_url), headers=headers, cert=(Crt, Key), verify=session.verify).json()
            print('')
            print('Transport Node: ',uuid[1])
            print('')
            x = (len(tunnel_json['tunnels']))
            
            if x > 0:
                for n  in range(x):
                    print('Tunnel name: ',tunnel_json['tunnels'][n]['name'])
                    print('Tunnel Status: ',tunnel_json['tunnels'][n]['status'])
                    print('Egress Interface: ',tunnel_json['tunnels'][n]['egress_interface'])
                    print('Local Tunnel IP: ',tunnel_json['tunnels'][n]['local_ip'])
                    print('Remote Tunnel IP: ',tunnel_json['tunnels'][n]['remote_ip'])
                    print('Remote Node ID: ',tunnel_json['tunnels'][n]['remote_node_id'])
                    print('Remote Node: ',tunnel_json['tunnels'][n]['remote_node_display_name'])
                    print('Tunnel Encapsulation: ',tunnel_json['tunnels'][n]['encap'])
                    print('')
            else:
                print('**** No tunnels exist for this transport node ****')
        except:
            print('**** No tunnels exist for this transport node ****')
            print('')

if __name__ == "__main__":
    main()
