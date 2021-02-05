#!/usr/bin/python3
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
import pathlib, lib.menu
from lib.excel import FillSheet, Workbook
from lib.system import style, GetAPI, ConnectNSX, os


def SheetT1ForwardingTable(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    NSX_Config['T1ForwardingTable'] = []
    Dict_T1 = {}
    # Connect NSX
    SessionNSX = ConnectNSX(auth_list)
    ########### GET Edge Clusters  ###########
    #edge_list_url = '/api/v1/search/query?query=resource_type:Edgenode'
    #edge_list_json = GetAPI(SessionNSX[0],edge_list_url, auth_list)
    ########### GET Tier-1 Gateways  ###########
    t1_url = '/policy/api/v1/infra/tier-1s'
    t1_json = GetAPI(SessionNSX[0],t1_url, auth_list)
    ########### CREATE LIST OF TUPLES - EDGE-ID / EDGE NAME ###########
    #edge_list = []
    #if edge_list_json["result_count"] > 0:
    #    for edge in edge_list_json["results"]:
    #        edge_list.append(tuple((edge['id'],edge['display_name'])))

    t1_id_list = []
    XLS_Lines = []
    TN_HEADER_ROW = ('T1 Router','Edge Node Path', 'Edge ID', 'HA Status','Route Type', 'Network', 'Admin Distance', 'Next Hop', 'LR Component ID', 'LR Component Type')

    if t1_json["result_count"] > 0:
        for T1 in t1_json["results"]:
            t1_id_list.append(T1['display_name'])

        for T1 in t1_id_list:
            forwardingURL = t1_url + '/' + str(T1) + '/forwarding-table'
            # Get T1 State
            t1_state_json = GetAPI(SessionNSX[0],t1_url + '/' + str(T1) + '/state', auth_list)
            nb_routes = 0
            if isinstance(t1_state_json, dict) and 'tier1_status' in t1_state_json:
                if 'per_node_status' in t1_state_json['tier1_status']:
                    for node in t1_state_json['tier1_status']['per_node_status']:
                        if node['high_availability_status'] != 'STANDBY':
                            EdgeID = node['transport_node_id']
                            HAStatus = node['high_availability_status']
                            forwardingURL = t1_url + '/' + str(T1) + '/forwarding-table?edge_id=' + EdgeID

            # Get T1 forwardoing table
            t1_routingtable_json = GetAPI(SessionNSX[0],forwardingURL, auth_list)
            if isinstance(t1_routingtable_json, dict) and 'results' in t1_routingtable_json and t1_routingtable_json['result_count'] > 0:
                for n in t1_routingtable_json["results"]:
                    # Get routes
                    nb_routes = len(n['route_entries'])
                    for entry in n['route_entries']:
                        Dict_T1['edge_name'] = n['edge_node']
                        Dict_T1['edge_id'] = EdgeID
                        Dict_T1['ha'] = HAStatus
                        Dict_T1['T0_name'] = T1
                        Dict_T1['route_type'] = entry['route_type']
                        Dict_T1['network'] = entry['network']
                        Dict_T1['ad'] = entry['admin_distance']
                        Dict_T1['next_hop'] = entry['next_hop']
                        Dict_T1['lr_id']= entry['lr_component_id']
                        Dict_T1['lr_type'] = entry['lr_component_type']
                        NSX_Config['T1ForwardingTable'].append(Dict_T1)
                        XLS_Lines.append([T1, n['edge_node'], EdgeID,HAStatus,entry['route_type'], entry['network'],entry['admin_distance'], entry['next_hop'],entry['lr_component_id'],entry['lr_component_type']])
            elif not t1_routingtable_json:
                XLS_Lines.append([T1,"No Forwarding table found","","","","","","","",""])
            else:
                XLS_Lines.append([T1,"T1 not deployed on Edge Cluster. DR Only","","","","","","","",""])
            
            print(" --> Get forwarding tables of " + style.ORANGE + T1 + style.NORMAL + " Router: " + style.ORANGE + str(nb_routes) + style.NORMAL + " route(s)")

    else:
        XLS_Lines.append(["No Forwarding table found","","","","","","","","",""])

    FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
        