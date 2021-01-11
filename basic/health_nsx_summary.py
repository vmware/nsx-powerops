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
import ssl

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

    t0_gateway_url = '/policy/api/v1/infra/tier-0s'
    t1_gateway_url = '/policy/api/v1/infra/tier-1s'
    segment_url = '/policy/api/v1/infra/segments'
    groups_url = '/policy/api/v1/infra/domains/default/groups'
    ctx_profiles_url = '/policy/api/v1/infra/context-profiles'
    services_url = '/policy/api/v1/infra/services'
    deployed_mgmt_nodes_url = '/api/v1/cluster'
    online_mgmt_nodes_url = '/api/v1/cluster/status'
    edge_clstr_url = '/api/v1/edge-clusters'
    edge_tn_url = '/api/v1/search/query?query=resource_type:Edgenode'
    host_tn_url = '/api/v1/search/query?query=resource_type:Hostnode'
    
    # vpn_services = 
    # nat_rules_url = 
    # lb_url = 
    # dfw_policies_url = 
    # gw_policies_url = 
    # endpoint_policies_url = 
    # ni_ew_policy_url = 
    # ni_ns_policy_url = 
    # vms_url = 
    # phy_svrs = 
    # tzones_url = 
    # hosts_url = 

    deployed_json = session.get('https://' + auth_list[0] + str(deployed_mgmt_nodes_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    deployed = len(deployed_json["nodes"])
    online_nodes_json = requests.get('https://' + auth_list[0] + str(online_mgmt_nodes_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    online_nodes = len(online_nodes_json['mgmt_cluster_status']['online_nodes'])
    edge_clstr_json = requests.get('https://' + auth_list[0] + str(edge_clstr_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    edge_clusters = (edge_clstr_json["result_count"])
    edge_tn_json = requests.get('https://' + auth_list[0] + str(edge_tn_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    edge_tnodes = (edge_tn_json["result_count"])
    host_tn_json = requests.get('https://' + auth_list[0] + str(host_tn_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    host_tnodes = (host_tn_json["result_count"])
    t0_gateway_json = requests.get('https://' + auth_list[0] + str(t0_gateway_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    t0_gateways = (t0_gateway_json["result_count"])
    t1_gateway_json = requests.get('https://' + auth_list[0] + str(t1_gateway_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    t1_gateways = (t1_gateway_json["result_count"])
    segment_json = requests.get('https://' + auth_list[0] + str(segment_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    segments = (segment_json["result_count"])
    groups_json = requests.get('https://' + auth_list[0] + str(groups_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    groups = (groups_json["result_count"])
    ctx_profiles_json = requests.get('https://' + auth_list[0] + str(ctx_profiles_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    ctx_profiles = (ctx_profiles_json["result_count"])
    services_json = requests.get('https://' + auth_list[0] + str(services_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    services = (services_json["result_count"])
    

    #Display Summary Output
    print('')
    print('NSX Manager Summary for: https://',auth_list[0])
    print('')
    print('Deployed NSX Manager Nodes:', deployed)
    print('Online NSX Manager Nodes: ', online_nodes)
    print('')
    print('Edge Clusters: ',edge_clusters)
    print('Edge Transport Nodes: ',edge_tnodes)
    print('Host Transport Nodes: ',host_tnodes)
    print('')
    print('T0 Gateways:      ',t0_gateways)
    print('T1 Gateways:      ',t1_gateways)
    print('Segments:         ',segments)
    print('')  
    print('NS Groups:        ',groups)  
    print('Context Profiles: ',ctx_profiles)  
    print('Services:         ',services)  

if __name__ == "__main__":
    main()
