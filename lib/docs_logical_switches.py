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
import pathlib, lib.menu,  pprint
from lib.excel import FillSheet, Workbook, ConditionnalFormat, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, ConnectNSX, os, GetOutputFormat

def SheetSegments(auth_list,WORKBOOK,TN_WS,NSX_Config = {}):
    NSX_Config['Segments'] = []
    Dict_LS = {}

    # Connect to NSX
    SessionNSX = ConnectNSX(auth_list)
    segments_url = '/api/v1/logical-switches'
    segments_json = GetAPI(SessionNSX[0],segments_url, auth_list)
    tz_url = '/policy/api/v1/infra/sites/default/enforcement-points/default/transport-zones'
    tz_json = GetAPI(SessionNSX[0],tz_url, auth_list)
    
    XLS_Lines = []
    TN_HEADER_ROW = ('Segments', 'VNI', 'VLAN', 'Transport Zone Name', 'Transport Zone Type', 'Replication Mode', 'Admin State')

     # Check if Segements present
    if isinstance(segments_json, dict) and 'results' in segments_json and segments_json['result_count'] > 0: 
        for segment in segments_json['results']:
            TZ_NAME = ""
            TZ_Type = ""
            Dict_LS['vni'] = ''
            Dict_LS['vlan'] = ''
            for tz in tz_json['results']:
                if segment['transport_zone_id'] == tz['id']:
                    TZ_NAME = tz['display_name']
                    TZ_Type = tz['tz_type']
                    break
            Dict_LS['segment_name'] = segment['display_name']
            if 'vni' in segment: Dict_LS['vni'] = segment['vni']
            if 'vlan' in segment: Dict_LS['vlan'] = segment['vlan']
            Dict_LS['tz_name'] = TZ_NAME
            Dict_LS['tz_type'] = TZ_Type
            repmode = segment.get('replication_mode')
            if repmode == None:
                Dict_LS['replication_mode'] = 'None'
            else: 
                Dict_LS['replication_mode'] = segment['replication_mode']

            Dict_LS['status'] = segment['admin_state']
            NSX_Config['Segments'].append(Dict_LS)
            XLS_Lines.append([Dict_LS['segment_name'], Dict_LS['vni'], Dict_LS['vlan'], TZ_NAME, TZ_Type, Dict_LS['replication_mode'],segment['admin_state']])
    else:
        XLS_Lines.append(["no Segments", "", "", "", "", "",""])

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
        ConditionnalFormat(TN_WS, 'G2:G' + str(len(XLS_Lines) + 1), 'UP')
