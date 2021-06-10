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
import pathlib, pprint
from lib.excel import FillSheet, Workbook, ConditionnalFormat, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, ConnectNSX, os, datetime, GetOutputFormat
import lib.menu


def SheetTunnels(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    NSX_Config['Tunnels'] = []
    # Connect to NSX
    SessionNSX = ConnectNSX(auth_list)
    transport_node_url = '/api/v1/transport-nodes'
    transport_node_json = GetAPI(SessionNSX[0],transport_node_url, auth_list)
    XLS_Lines = []
    TN_HEADER_ROW = ('Transport Node', 'Tunnel Name', 'Tunnel Status', 'Egress Interface', 'Local Tunnel IP', 'Remote Tunnel IP', 'Remote Node ID', 'Remote Node Name', 'Encap')
    # Check if Transport Node present
    if isinstance(transport_node_json, dict) and 'results' in transport_node_json and transport_node_json['result_count'] > 0: 
        for node in transport_node_json['results']:
            tunnel_url = '/api/v1/transport-nodes/' + node['id'] + '/tunnels'
            tunnel_json = GetAPI(SessionNSX[0],tunnel_url, auth_list)
            if tunnel_json["result_count"] > 0:
                Dict_NodesTunnels = {}
                Dict_NodesTunnels['node_name'] = node['display_name']
                Dict_NodesTunnels['tunnels'] = []
                Dict_Tunnels = {}
                for tunnel in tunnel_json["tunnels"]:
                    Dict_Tunnels['name'] = tunnel['name']
                    Dict_Tunnels['status'] = tunnel['status']
                    Dict_Tunnels['Egress_int'] = tunnel['egress_interface']
                    Dict_Tunnels['local_ip'] = tunnel['local_ip']
                    Dict_Tunnels['remote_ip'] = tunnel['remote_ip']
                    Dict_Tunnels['remote_node_id'] = tunnel['remote_node_id']
                    Dict_Tunnels['remote_node_display_name'] = tunnel['remote_node_display_name']
                    Dict_Tunnels['encap'] = tunnel['encap']
                    Dict_NodesTunnels['tunnels'].append(Dict_Tunnels)
                    # Create line
                    XLS_Lines.append([node['display_name'], tunnel['name'], tunnel['status'], tunnel['egress_interface'], tunnel['local_ip'], tunnel['remote_ip'], tunnel['remote_node_id'], tunnel['remote_node_display_name'], tunnel['encap']])
    
                NSX_Config['Tunnels'].append(Dict_NodesTunnels)
    else:
        XLS_Lines.append(["no Transport Nodes", "", "", "", "", "", "", "", ""])
    
    if GetOutputFormat() == 'CSV':
        CSV = WORKBOOK
        FillSheetCSV(CSV,TN_HEADER_ROW,XLS_Lines)
    elif GetOutputFormat() == 'JSON':
        JSON = WORKBOOK
        FillSheetJSON(JSON, NSX_Config)
    elif GetOutputFormat() == 'YAML':
        YAML = WORKBOOK
        FillSheetYAML(YAML, NSX_Config)
    else:
        FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
        ConditionnalFormat(TN_WS, 'C2:C' + str(len(XLS_Lines) + 1), 'UP')
