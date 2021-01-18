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
from lib.system import *

########### SECTION FOR REPORTING ON NSX-T MANAGER CLUSTER ###########
def GetHealthNSXCluster(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsxclstr_json = GetAPI(SessionNSX[0],'/api/v1/cluster/status', auth_list)
    
    print("\n========================================================================================================")
    print('\nNSX-T Cluster Status:         ',nsxclstr_json['mgmt_cluster_status']['status'])
    print('NSX-T Control Cluster Status: ',nsxclstr_json['control_cluster_status']['status'])
    print('NSX-T Overall Cluster Status: ',nsxclstr_json['detailed_cluster_status']['overall_status'])
    print('')
    online_nodes = len(nsxclstr_json['mgmt_cluster_status']['online_nodes'])

    groups = nsxclstr_json['detailed_cluster_status']['groups']
    nsxmgr_json = GetAPI(SessionNSX[0],'/api/v1/cluster', auth_list)
    base = nsxmgr_json["nodes"]

    for n in range(online_nodes):
        print('')
        print('NSX-T Manager Appliance: ',base[n]['fqdn'])
        print('')
        for n in range(len(groups)):
            print('Group Type:   ',groups[n]['group_type'])
            print('Group Status: ',groups[n]['group_status'])
            print('')
    print("========================================================================================================")


########### SECTION FOR REPORTING ON NSX-T Transport Node Status ###########
def GetTNStatus(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    hostnode_json = GetAPI(SessionNSX[0],'/api/v1/search/query?query=resource_type:Hostnode', auth_list)

    hostnodes = (hostnode_json["result_count"])
    
    print("\n========================================================================================================")
    for n in range(hostnodes):
        print('')
        print('Host Node: ',hostnode_json["results"][n]["display_name"])
        print('LCP Connectivity Status: ',hostnode_json["results"][n]["status"]["lcp_connectivity_status"])
        print('MPA Connectivity Status: ',hostnode_json["results"][n]["status"]["mpa_connectivity_status"])
        print('MPA Connectivity Status Details: ',hostnode_json["results"][n]["status"]["mpa_connectivity_status_details"])
        print('Host Node Deployment Status: ',hostnode_json["results"][n]["status"]["host_node_deployment_status"])
        try:
            print('NSX Controller IP: ',hostnode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["control_node_ip"])
            print('NSX Controller Status: ',hostnode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["status"])
            print('')
        except:
            print('NSX Controller IP: UNKNOWN')
            print('NSX Controller Status: UNKNOWN')
            print('')
    print("========================================================================================================")


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

    print("\n========================================================================================================")
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
    print("========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T Compute Manager Detail ###########
def GetComputeDetail(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    cmp_mgr_json = GetAPI(SessionNSX[0],'/api/v1/fabric/compute-managers', auth_list)
    cmp_managers = cmp_mgr_json["result_count"]

    print("\n========================================================================================================")
    print('')
    print('Number of Compute Managers: ',cmp_managers)

    for i in range(cmp_mgr_json["result_count"]):
        print('')
        print('Compute Manager ID:     ',cmp_mgr_json["results"][i]["id"])
        print('Compute Manager Server: ',cmp_mgr_json["results"][i]["server"])
        print('Compute Manager Origin: ',cmp_mgr_json["results"][i]["origin_type"])     
        print('Compute Manager Build:  ',cmp_mgr_json["results"][i]["origin_properties"][0].get("value"))
        print('')
    print("========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T Edge Cluster Detail ###########
def GetEdgeCLDetail(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    edgecluster_json = GetAPI(SessionNSX[0],'/api/v1/edge-clusters', auth_list)
    edgeclusters = (edgecluster_json["result_count"])
    
    print("\n========================================================================================================")
    for n in range(edgeclusters):
        print('')
        print('Edge Cluster: ',edgecluster_json["results"][n]["display_name"])
        print('Resource Type: ',edgecluster_json["results"][n]["resource_type"])
        print('Deployment Type: ',edgecluster_json["results"][n]["deployment_type"])
        print('Member Node Type: ',edgecluster_json["results"][n]["member_node_type"])
        print('')
    print("========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T Edge Cluster Status ###########
def GetEdgeStatus(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    edgenode_json = GetAPI(SessionNSX[0],'/api/v1/search/query?query=resource_type:Edgenode', auth_list)
    edgenodes = (edgenode_json["result_count"])
    
    print("\n========================================================================================================")
    for n in range(edgenodes):
        print('')
        print('Edge Node: ',edgenode_json["results"][n]["display_name"])
        print('LCP Connectivity Status: ',edgenode_json["results"][n]["status"]["lcp_connectivity_status"])
        print('MPA Connectivity Status: ',edgenode_json["results"][n]["status"]["mpa_connectivity_status"])
        print('MPA Connectivity Status Details: ',edgenode_json["results"][n]["status"]["mpa_connectivity_status_details"])
        print('Host Node Deployment Status: ',edgenode_json["results"][n]["status"]["host_node_deployment_status"])
        try:
            print('NSX Controller IP: ',edgenode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["control_node_ip"])
            print('NSX Controller Status: ',edgenode_json["results"][n]["status"]["lcp_connectivity_status_details"][0]["status"])
            print('')
        except:
            print('NSX Controller IP: UNKNOWN')
            print('NSX Controller Status: UNKNOWN')
    print("\n========================================================================================================")


########### SECTION FOR REPORTING ON NSX-T MANAGER CAPACITY NETWORKING ###########
def GetNetworkUsage(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsx_net_cap_json = GetAPI(SessionNSX[0],'/api/v1/capacity/usage?category=networking', auth_list)
    print("\n========================================================================================================")
    print('')
    print('----------------------------------- NSX NETWORKING CAPACITY ---------------------------------')
    print('|  Name                                                | Current  | Max Supported | Usage % |')
    print('---------------------------------------------------------------------------------------------')

    data = nsx_net_cap_json['capacity_usage']
    cap_net = len(data)
    for n in range(cap_net):
        print('{:<60s}{:>4d}{:>12d}{:>15.1f}'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
    print('---------------------------------------------------------------------------------------------')
    print('')
    print("========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T MANAGER CAPACITY NETWORKING ###########
def GetSecurityUsage(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsx_sec_cap_json = GetAPI(SessionNSX[0],'/api/v1/capacity/usage?category=security', auth_list)
    print("\n========================================================================================================")
    print('')
    print('------------------------------------ NSX SECURITY CAPACITY -----------------------------------')
    print('|  Name                                                 | Current  | Max Supported | Usage % |')
    print('----------------------------------------------------------------------------------------------')

    data = nsx_sec_cap_json['capacity_usage']
    cap_sec = len(data)
    for n in range(cap_sec):
        print('{:<60s}{:>4d}{:>12d}{:>15.1f}'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
    print('----------------------------------------------------------------------------------------------')
    print('')
    print("========================================================================================================")

########### SECTION FOR REPORTING ON NSX-T MANAGER CAPACITY NETWORKING ###########
def GetInventoryUsage(auth_list):
    SessionNSX = ConnectNSX(auth_list)
    nsx_inv_cap_json = GetAPI(SessionNSX[0],'/api/v1/capacity/usage?category=inventory', auth_list)
    print("\n========================================================================================================")
    print('')
    print('------------------------------------ NSX INVENTORY CAPACITY -----------------------------------')
    print('|  Name                                                 | Current  | Max Supported | Usage %  |')
    print('-----------------------------------------------------------------------------------------------')

    data = nsx_inv_cap_json['capacity_usage']
    cap_inv = len(data)
    for n in range(cap_inv):
        print('{:<60s}{:>4d}{:>12d}{:>15.1f}'.format(data[n]['display_name'],data[n]['current_usage_count'],data[n]['max_supported_count'],data[n]['current_usage_percentage']))
    print('-----------------------------------------------------------------------------------------------')
    print('')
    print("========================================================================================================")
