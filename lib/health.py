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
from lib.system import style, GetAPI, ConnectNSX, os, YAML_CFG_FILE

########### SECTION FOR REPORTING ON NSX-T MANAGER CLUSTER ###########
def GetHealthNSXCluster(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsxclstr_json = GetAPI(SessionNSX[0],'/api/v1/cluster/status', auth_list)
    
    print("\n========================================================================================================")
    if nsxclstr_json['mgmt_cluster_status']['status'] == 'STABLE': print('NSX-T Cluster Status:\t\t' + style.GREEN +  nsxclstr_json['mgmt_cluster_status']['status'] + style.NORMAL)
    else: print('NSX-T Cluster Status:\t\t' + style.RED + nsxclstr_json['mgmt_cluster_status']['status'] + style.NORMAL)
    if nsxclstr_json['control_cluster_status']['status'] == 'STABLE': print('NSX-T Control Cluster Status:\t' + style.GREEN + nsxclstr_json['control_cluster_status']['status'] + style.NORMAL)
    if nsxclstr_json['detailed_cluster_status']['overall_status'] == 'STABLE': print('NSX-T Overall Cluster:\t\t' +style.GREEN + nsxclstr_json['detailed_cluster_status']['overall_status'] + style. NORMAL)
    else: print('NSX-T Overall Cluster:\t\t' +style.RED + nsxclstr_json['detailed_cluster_status']['overall_status'] + style. NORMAL)
    online_nodes = len(nsxclstr_json['mgmt_cluster_status']['online_nodes'])

    groups = nsxclstr_json['detailed_cluster_status']['groups']
    nsxmgr_json = GetAPI(SessionNSX[0],'/api/v1/cluster', auth_list)
    base = nsxmgr_json["nodes"]

    for n in range(online_nodes):
        print('\nNSX-T Manager Appliance: ' + style.ORANGE + base[n]['fqdn'] + style.NORMAL)
        for n in range(len(groups)):
            print('\nGroup Type:\t' + groups[n]['group_type'].strip())
            if groups[n]['group_status'] == 'STABLE': print('Group Status:\t' + style.GREEN + groups[n]['group_status'] + style.NORMAL)
            else: print('Group Status:\t\t' + style.RED + groups[n]['group_status'] + style.NORMAL)
    print("========================================================================================================")


########### SECTION FOR REPORTING ON NSX-T Transport Node Status ###########
def GetTNStatus(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    hostnode_json = GetAPI(SessionNSX[0],'/api/v1/search/query?query=resource_type:Hostnode', auth_list)

    hostnodes = (hostnode_json["result_count"])
    
    print("\n========================================================================================================")
    for n in range(hostnodes):
        print('')
        print('Host Node: ' + style.ORANGE +hostnode_json["results"][n]["display_name"] + style.NORMAL)
        if hostnode_json["results"][n]["status"]["lcp_connectivity_status"] == 'UP': print('LCP Connectivity Status: ' + style.GREEN + hostnode_json["results"][n]["status"]["lcp_connectivity_status"]+ style.NORMAL)
        else: print('LCP Connectivity Status: ' + style.RED + hostnode_json["results"][n]["status"]["lcp_connectivity_status"]+ style.NORMAL)
        if hostnode_json["results"][n]["status"]["mpa_connectivity_status"] == 'UP': print('MPA Connectivity Status: ' + style.GREEN + hostnode_json["results"][n]["status"]["mpa_connectivity_status"]+ style.NORMAL)
        else: print('MPA Connectivity Status: ' + style.RED + hostnode_json["results"][n]["status"]["mpa_connectivity_status"]+ style.NORMAL) 
        print('MPA Connectivity Status Details: ' + style.ORANGE + hostnode_json["results"][n]["status"]["mpa_connectivity_status_details"]+ style.NORMAL)
        if 'INSTALL_SUCCESSFUL' in hostnode_json["results"][n]["status"]["host_node_deployment_status"]: print('Host Node Deployment Status: ' + style.GREEN + hostnode_json["results"][n]["status"]["host_node_deployment_status"]+ style.NORMAL)
        else: print('Host Node Deployment Status: ' + style.RED + hostnode_json["results"][n]["status"]["host_node_deployment_status"] + style.NORMAL)
        try:
            print('NSX Controller IP: ' + style.ORANGE + hostnode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["control_node_ip"] + style.NORMAL)
            print('NSX Controller Status: ' + style.GREEN + hostnode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["status"] + style.NORMAL)
            print('')
        except:
            print('NSX Controller IP: ' + style.RED + 'UNKNOWN'+ style.NORMAL)
            print('NSX Controller Status: ' + style.RED + 'UNKNOWN'+ style.NORMAL)
            print('')
    print("========================================================================================================")


########### SECTION FOR REPORTING ON NSX-T Transport Nodes Tunnels ###########
def GetTNTunnels(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    transport_node_json = GetAPI(SessionNSX[0],'/api/v1/transport-nodes', auth_list)
    transport_nodes = (transport_node_json['results'])
    tnode_dict = {}
    
    for n in range(len(transport_nodes)):
        tnode_dict.update({transport_nodes[n]['node_id']:transport_nodes[n]['display_name']})
        
    for uuid in tnode_dict.items():
        try:
            tunnel_url = '/api/v1/transport-nodes/' + str(uuid[0]) + '/tunnels'
            tunnel_json = GetAPI(SessionNSX[0],tunnel_url, auth_list)
            print('\nTransport Node: ' + style.ORANGE + uuid[1] + style.NORMAL)
            print('')
            x = (len(tunnel_json['tunnels']))
            
            if x > 0:
                for n  in range(x):
                    print('Tunnel name: ',tunnel_json['tunnels'][n]['name'])
                    if tunnel_json['tunnels'][n]['status'] == 'UP': print('Tunnel Status: ' + style.GREEN + tunnel_json['tunnels'][n]['status'] + style.NORMAL)
                    else: print('Tunnel Status: ' + style.RED + tunnel_json['tunnels'][n]['status'] + style.NORMAL)
                    print('Egress Interface: ',tunnel_json['tunnels'][n]['egress_interface'])
                    print('Local Tunnel IP: ',tunnel_json['tunnels'][n]['local_ip'])
                    print('Remote Tunnel IP: ',tunnel_json['tunnels'][n]['remote_ip'])
                    print('Remote Node ID: ',tunnel_json['tunnels'][n]['remote_node_id'])
                    print('Remote Node: ',tunnel_json['tunnels'][n]['remote_node_display_name'])
                    print('Tunnel Encapsulation: ',tunnel_json['tunnels'][n]['encap'])
                    print('')
            else:
                print(style.RED + '**** No tunnels exist for this transport node ****' + style.NORMAL)
        except:
            print(style.RED + '**** No tunnels exist for this transport node ****\n' + style.NORMAL)


def GetNSXSummary(auth_list):
    SessionNSX = ConnectNSX(auth_list)

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
    
    deployed_json = GetAPI(SessionNSX[0],deployed_mgmt_nodes_url, auth_list)
    deployed = len(deployed_json["nodes"])
    online_nodes_json = GetAPI(SessionNSX[0],online_mgmt_nodes_url, auth_list)
    online_nodes = len(online_nodes_json['mgmt_cluster_status']['online_nodes'])
    edge_clstr_json = GetAPI(SessionNSX[0],edge_clstr_url, auth_list)
    edge_tn_json = GetAPI(SessionNSX[0],edge_tn_url, auth_list)
    host_tn_json = GetAPI(SessionNSX[0],host_tn_url, auth_list)
    t0_gateway_json = GetAPI(SessionNSX[0],t0_gateway_url, auth_list)
    t1_gateway_json = GetAPI(SessionNSX[0],t1_gateway_url, auth_list)
    segment_json = GetAPI(SessionNSX[0],segment_url, auth_list)
    groups_json = GetAPI(SessionNSX[0],groups_url, auth_list)
    ctx_profiles_json = GetAPI(SessionNSX[0],ctx_profiles_url, auth_list)
    services_json = GetAPI(SessionNSX[0],services_url, auth_list)
    #YAML_DICT = ReadYAMLCfgFile(YAML_CFG_FILE)
    YAML_DICT = GetYAMLDict()

    #Display Summary Output
    print('\nNSX Manager Summary for: https://' + style.ORANGE + YAML_DICT['NSX_MGR_IP'] + style.NORMAL)
    print('\nDeployed NSX Manager Nodes:\t' + style.ORANGE +  str(deployed) + style.NORMAL)
    print('Online NSX Manager Nodes:\t' + style.ORANGE + str(online_nodes) + style.NORMAL)
    print('\nEdge Clusters:\t\t' + style.ORANGE + str(edge_clstr_json["result_count"]) + style.NORMAL)
    print('Edge Transport Nodes:\t' + style.ORANGE + str(edge_tn_json["result_count"]) + style.NORMAL)
    print('Host Transport Nodes:\t' + style.ORANGE + str(host_tn_json["result_count"]) + style.NORMAL)
    print('\nT0 Gateways:\t' + style.ORANGE + str(t0_gateway_json["result_count"]) + style.NORMAL)
    print('T1 Gateways:\t' + style.ORANGE + str(t1_gateway_json["result_count"]) + style.NORMAL)
    print('Segments:\t' + style.ORANGE + str(segment_json["result_count"]) + style.NORMAL)
    print('\nNS Groups:\t\t' + style.ORANGE + str(groups_json["result_count"]) + style.NORMAL)  
    print('Context Profiles:\t' + style.ORANGE + str(ctx_profiles_json["result_count"]) + style.NORMAL)  
    print('Services:\t\t' + style.ORANGE + str(services_json["result_count"]) + style.NORMAL)  

########### SECTION FOR REPORTING ON NSX-T Logical Router Summary ###########
def GetLRSum(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    lr_list_json = GetAPI(SessionNSX[0],'/api/v1/logical-routers', auth_list)
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

    print("\n========================================================================================================\n")
    print('Tier0 Logical Routers:\t' + style.ORANGE + str(tier0s) + style.NORMAL)
    print('Tier0 VRFs:\t\t' + style.ORANGE + str(tier0vrfs) + style.NORMAL)
    print('Tier1 Logical Routers:\t' + style.ORANGE + str(tier1s) + style.NORMAL)
    print('\nTotal Number of Logical Routers: ' + style.ORANGE + str(total_lrs) + style.NORMAL + "\n")
    
    for i in lr_list_json["results"]:
        print('\nName:\t\t' + style.ORANGE + i['display_name'] + style.NORMAL)
        print('Router Type:\t' + style.ORANGE + i['router_type'] + style.NORMAL)
        print('HA Mode:\t' + style.ORANGE + i['high_availability_mode'] + style.NORMAL)
    
    print("\n========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T Compute Manager Detail ###########
def GetComputeDetail(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    cmp_mgr_json = GetAPI(SessionNSX[0],'/api/v1/fabric/compute-managers', auth_list)
    cmp_managers = cmp_mgr_json["result_count"]

    print("\n========================================================================================================")
    print('\nNumber of Compute Managers: ' + style.ORANGE + str(cmp_managers) + style.NORMAL)

    for i in range(cmp_mgr_json["result_count"]):
        print('\nCompute Manager ID:\t' +style.ORANGE + cmp_mgr_json["results"][i]["id"]+ style.NORMAL)
        print('Compute Manager Server:\t' +style.ORANGE + cmp_mgr_json["results"][i]["server"]+ style.NORMAL)
        print('Compute Manager Origin:\t' +style.ORANGE + cmp_mgr_json["results"][i]["origin_type"]+ style.NORMAL)
        print('Compute Manager Build:\t' +style.ORANGE + cmp_mgr_json["results"][i]["origin_properties"][0].get("value")+ style.NORMAL)
    print("\n========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T Edge Cluster Detail ###########
def GetEdgeCLDetail(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    edgecluster_json = GetAPI(SessionNSX[0],'/api/v1/edge-clusters', auth_list)
    edgeclusters = (edgecluster_json["result_count"])
    
    print("\n========================================================================================================")
    for n in range(edgeclusters):
        print('')
        print('Edge Cluster: ' + style.ORANGE + edgecluster_json["results"][n]["display_name"] + style.NORMAL)
        print('Resource Type: ' + style.ORANGE + edgecluster_json["results"][n]["resource_type"] + style.NORMAL)
        print('Deployment Type: ' + style.ORANGE + edgecluster_json["results"][n]["deployment_type"] + style.NORMAL)
        print('Member Node Type: ' + style.ORANGE + edgecluster_json["results"][n]["member_node_type"] + style.NORMAL)
        print('')
    print("========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T Edge Cluster Status ###########
def GetEdgeStatus(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    edgenode_json = GetAPI(SessionNSX[0],'/api/v1/search/query?query=resource_type:Edgenode', auth_list)
    edgenodes = (edgenode_json["result_count"])
    
    print("\n========================================================================================================\n")
    for n in range(edgenodes):
        print('Edge Node: ' + style.ORANGE +edgenode_json["results"][n]["display_name"] + style.NORMAL)
        if edgenode_json["results"][n]["status"]["lcp_connectivity_status"] == 'UP': print('LCP Connectivity Status: ' + style.GREEN + edgenode_json["results"][n]["status"]["lcp_connectivity_status"]+ style.NORMAL)
        else: print('LCP Connectivity Status: ' + style.RED + edgenode_json["results"][n]["status"]["lcp_connectivity_status"]+ style.NORMAL)
        if edgenode_json["results"][n]["status"]["mpa_connectivity_status"] == 'UP': print('MPA Connectivity Status: ' + style.GREEN + edgenode_json["results"][n]["status"]["mpa_connectivity_status"]+ style.NORMAL)
        else: print('MPA Connectivity Status: ' + style.RED + edgenode_json["results"][n]["status"]["mpa_connectivity_status"]+ style.NORMAL) 
        print('MPA Connectivity Status Details: ' + style.ORANGE + edgenode_json["results"][n]["status"]["mpa_connectivity_status_details"]+ style.NORMAL)
        if 'READY' in edgenode_json["results"][n]["status"]["host_node_deployment_status"]: print('Edge Node Deployment Status: ' + style.GREEN + edgenode_json["results"][n]["status"]["host_node_deployment_status"]+ style.NORMAL)
        else: print('Edge Node Deployment Status: ' + style.RED + edgenode_json["results"][n]["status"]["host_node_deployment_status"] + style.NORMAL)
        try:
            print('NSX Controller IP: ' + style.GREEN + edgenode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["control_node_ip"] + style.NORMAL)
            print('NSX Controller Status: ' + style.GREEN + edgenode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["status"] + style.NORMAL)
            print('')
        except:
            print('NSX Controller IP: ' + style.RED + 'UNKNOWN'+ style.NORMAL)
            print('NSX Controller Status: ' + style.RED + 'UNKNOWN'+ style.NORMAL)
    print("\n========================================================================================================")


########### SECTION FOR REPORTING ON NSX-T MANAGER CAPACITY NETWORKING ###########
def GetNetworkUsage(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsx_net_cap_json = GetAPI(SessionNSX[0],'/api/v1/capacity/usage?category=networking', auth_list)
    print("\n========================================================================================================")
    print('\n----------------------------------- NSX NETWORKING CAPACITY ---------------------------------')
    print('|  Name                                                | Current  | Max Supported | Usage % |')
    print('---------------------------------------------------------------------------------------------')

    data = nsx_net_cap_json['capacity_usage']
    cap_net = len(data)
    for n in range(cap_net):
        if data[n]['current_usage_percentage'] > 70: print('{:<60s}{:>4d}{:>12d}\x1b[0;31;40m{:>15.1f}\x1b[0m'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
        else: print('{:<60s}{:>4d}{:>12d}{:>15.1f}'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
    print('---------------------------------------------------------------------------------------------')
    print("\n========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T MANAGER CAPACITY NETWORKING ###########
def GetSecurityUsage(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsx_sec_cap_json = GetAPI(SessionNSX[0],'/api/v1/capacity/usage?category=security', auth_list)
    print("\n========================================================================================================")
    print('\n------------------------------------ NSX SECURITY CAPACITY -----------------------------------')
    print('|  Name                                                 | Current  | Max Supported | Usage % |')
    print('----------------------------------------------------------------------------------------------')

    data = nsx_sec_cap_json['capacity_usage']
    cap_sec = len(data)
    for n in range(cap_sec):
        if data[n]['current_usage_percentage'] > 70: print('{:<60s}{:>4d}{:>12d}\x1b[0;31;40m{:>15.1f}\x1b[0m'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
        else: print('{:<60s}{:>4d}{:>12d}{:>15.1f}'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
    print('----------------------------------------------------------------------------------------------')
    print('')
    print("========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T MANAGER CAPACITY NETWORKING ###########
def GetInventoryUsage(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsx_inv_cap_json = GetAPI(SessionNSX[0],'/api/v1/capacity/usage?category=inventory', auth_list)
    print("\n========================================================================================================")
    print('\n------------------------------------ NSX INVENTORY CAPACITY -----------------------------------')
    print('|  Name                                                 | Current  | Max Supported | Usage %  |')
    print('-----------------------------------------------------------------------------------------------')

    data = nsx_inv_cap_json['capacity_usage']
    cap_inv = len(data)
    for n in range(cap_inv):
        if data[n]['current_usage_percentage'] > 70: print('{:<60s}{:>4d}{:>12d}\x1b[0;31;40m{:>15.1f}\x1b[0m'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
        else: print('{:<60s}{:>4d}{:>12d}{:>15.1f}'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
    print('-----------------------------------------------------------------------------------------------')
    print("\n========================================================================================================")

########### SECTION FOR REPORTING ON BGP Sessions ###########
def GetBGPSessions(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    t0_url = '/policy/api/v1/infra/tier-0s'
    t0_json = GetAPI(SessionNSX[0],t0_url, auth_list)

    print("\n========================================================================================================")
    print('\n----------------------------------- NSX BGP Sessions ---------------------------------------------')
    print('| Source IP address | Neighbor IP Address  | Remote AS | In Prefixes | Out Prefixes | Status')
    print('--------------------------------------------------------------------------------------------------')
    tab = []
    if isinstance(t0_json, dict) and 'results' in t0_json and t0_json['result_count'] > 0: 
        for t0 in t0_json["results"]:
            t0_localeservice_url = "/policy/api/v1/infra/tier-0s/" + t0['display_name'] + "/locale-services/"
            t0_localeservices_json = GetAPI(SessionNSX[0],t0_localeservice_url, auth_list)
            for t0_localeservice in t0_localeservices_json['results']:
                bgpstatus_url = "/policy/api/v1/infra/tier-0s/" + t0['display_name'] + "/locale-services/" + t0_localeservice['id'] + "/bgp/neighbors/status"
                bgpstatus_json = GetAPI(SessionNSX[0],bgpstatus_url, auth_list)
                # BGP Sessions treatment
                if isinstance(bgpstatus_json, dict) and 'results' in bgpstatus_json:
                    for session in bgpstatus_json['results']:
                        tab.append([session['source_address'],session['neighbor_address'],session['remote_as_number'],session['total_in_prefix_count'], session['total_out_prefix_count'], session['connection_state']])
                else:
                    tab.append(['no BGP sessions'])
            
    else:
        tab.append(['no BGP sessions'])

    for i in tab:
        if len(i) > 1:
            print('{:<20s} {:<23s} {:<11s} {:^11d} {:^17d}\x1b[0;31;40m{:<13s}\x1b[0m'.format(i[0],i[1],i[2],i[3], i[4], i[5]))

    print('--------------------------------------------------------------------------------------------------')
    print("\n========================================================================================================")
