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
import pathlib, lib.menu
from lib.excel import FillSheet, Workbook, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, ConnectNSX, os, GetOutputFormat



def SheetTZ(auth_list,WORKBOOK,TN_WS, NSX_Config ={} ):
    SessionNSX = ConnectNSX(auth_list)
    node_url = '/api/v1/node'
    node_result = GetAPI(SessionNSX[0],node_url, auth_list)
    node_version = node_result["product_version"]
    node_v = node_version[0:3]
    if '3.2' in  node_v:
       print(node_v)
       NSX_Config['TZ'] = []
       # Connect NSX
       SessionNSX = ConnectNSX(auth_list)
       transport_zone_url = '/api/v1/transport-zones'
       transport_zone_json = GetAPI(SessionNSX[0],transport_zone_url, auth_list)
       XLS_Lines = []
       TN_HEADER_ROW = ('Name', 'ID', 'Ressource Type', 'Host Switch ID', 'Host Switch Mode', 'Host Switch Name', 'Host Switch is Default', 'is Nested NSX', 'Transport Type')
       if isinstance(transport_zone_json, dict) and 'results' in transport_zone_json and transport_zone_json['result_count'] > 0:
           for TZ in transport_zone_json['results']:
               Dict_TZ = {}
               Dict_TZ['name'] = TZ['display_name']
               Dict_TZ['id'] = TZ['id']
               Dict_TZ['resource_type'] = TZ['resource_type']
               # Dict_TZ['host_swithc_id'] = TZ['host_switch_id']
               # Dict_TZ['host_switch_mode'] = TZ['host_switch_mode']
               # Dict_TZ['host_switch_name'] = TZ['host_switch_name']
               Dict_TZ['is_default'] = TZ['is_default']
               Dict_TZ['nested'] = TZ['nested_nsx']
               Dict_TZ['type'] = TZ['transport_type']
               NSX_Config['TZ'].append(Dict_TZ)
               # Create line
               XLS_Lines.append([TZ['display_name'], TZ['id'], TZ['resource_type'], 'Not present in 3.2 API Call', 'Not present in 3.2 API Call', 'Not present in 3.2 API Call', TZ['is_default'], TZ['nested_nsx'], TZ['transport_type']])
       else:
           XLS_Lines.append(['no Transport Zones', '', '', '', '', '', '', '', ''])

    else:
       NSX_Config['TZ'] = []
       # Connect NSX
       SessionNSX = ConnectNSX(auth_list)
       transport_zone_url = '/api/v1/transport-zones'
       transport_zone_json = GetAPI(SessionNSX[0],transport_zone_url, auth_list)
       # if node_version 
       XLS_Lines = []
       TN_HEADER_ROW = ('Name', 'ID', 'Ressource Type', 'Host Switch ID', 'Host Switch Mode', 'Host Switch Name', 'Host Switch is Default', 'is Nested NSX', 'Transport Type')
       if isinstance(transport_zone_json, dict) and 'results' in transport_zone_json and transport_zone_json['result_count'] > 0: 
          for TZ in transport_zone_json['results']:
            Dict_TZ = {}
            Dict_TZ['name'] = TZ['display_name']
            Dict_TZ['id'] = TZ['id']
            Dict_TZ['resource_type'] = TZ['resource_type']
            Dict_TZ['host_swithc_id'] = TZ['host_switch_id']
            Dict_TZ['host_switch_mode'] = TZ['host_switch_mode']
            Dict_TZ['host_switch_name'] = TZ['host_switch_name']
            Dict_TZ['is_default'] = TZ['is_default']
            Dict_TZ['nested'] = TZ['nested_nsx']
            Dict_TZ['type'] = TZ['transport_type']
            NSX_Config['TZ'].append(Dict_TZ)
            # Create line
            XLS_Lines.append([TZ['display_name'], TZ['id'], TZ['resource_type'], TZ['host_switch_id'], TZ['host_switch_mode'], TZ['host_switch_name'], TZ['is_default'], TZ['nested_nsx'], TZ['transport_type']])
       else:
          XLS_Lines.append(['no Transport Zones', '', '', '', '', '', '', '', ''])

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
        
