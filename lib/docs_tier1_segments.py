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


def SheetT1Segments(auth_list,WORKBOOK,TN_WS,NSX_Config = {}):
    NSX_Config['T1Segments'] = []
    Dict_Segments = {}
    # Connect to NSX
    SessionNSX = ConnectNSX(auth_list)
    t1_url = '/policy/api/v1/infra/tier-1s'
    t1_json = GetAPI(SessionNSX[0],t1_url, auth_list)

    XLS_Lines = []
    TN_HEADER_ROW = ('Tier1 Segment Name', 'Tier1 Segment ID', 'Segment Gateway', 'Segment Network', 'Tier1 Router Name', 'Tier1 Router ID')
    
    if isinstance(t1_json, dict) and 'results' in t1_json and t1_json['result_count'] > 0: 
        for i in t1_json["results"]:
            t1_segment_url = '/policy/api/v1/search?query=resource_type:Segment&&dsl=segment where connectivity path=' + str(i['path']) + ''
            t1_segment_json = GetAPI(SessionNSX[0],t1_segment_url, auth_list)

            for n in t1_segment_json["results"]:
                Dict_Segments['id'] = n['id']
                Dict_Segments['name'] = n['display_name']
                Dict_Segments['gw'] = n['subnets'][0]['gateway_address']
                Dict_Segments['subnet'] = n['subnets'][0]['network']
                Dict_Segments['router'] = i['display_name']
                Dict_Segments['path'] = str(n['connectivity_path']).split("/")[3]
                NSX_Config['T1Segments'].append(Dict_Segments)
                XLS_Lines.append([n['display_name'], n['id'], n['subnets'][0]['gateway_address'], n['subnets'][0]['network'], i['display_name'], str(n['connectivity_path']).split("/")[3]])

    else:
        XLS_Lines.append(["no result", "", "", "", "", ""])
    
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
