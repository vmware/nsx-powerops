#!/usr/local/bin/python3
# coding: utf-8
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

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from _nsxauth import auth_list

from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

def main():
    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0])
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)

    transport_node_url = '/api/v1/transport-nodes'
    transport_node_json = session.get('https://' + auth_list[0] + str(transport_node_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    transport_nodes = (transport_node_json['results'])
    tnode_dict = {}
    
    for n in range(len(transport_nodes)):
        tnode_dict.update({transport_nodes[n]['node_id']:transport_nodes[n]['display_name']})
        
    for uuid in tnode_dict.items():
        try:
            tunnel_url = '/api/v1/transport-nodes/' + str(uuid[0]) + '/tunnels'
            tunnel_json = session.get('https://' + auth_list[0] + str(tunnel_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
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
