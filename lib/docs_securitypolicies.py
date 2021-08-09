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
from lib.excel import FillSheet, FillSheetCSV, Workbook, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, ConnectNSX, os, GetOutputFormat


def SheetSecPol(auth_list, WORKBOOK,TN_WS, NSX_Config = {}):
    NSX_Config['Policies'] = []
    Dict_Policies = {}
    # connection to NSX
    SessionNSX = ConnectNSX(auth_list)
    policies_json = GetAPI(SessionNSX[0],'/policy/api/v1/infra/domains/default/security-policies', auth_list)
    # Header of Excel and initialization of lines
    XLS_Lines = []
    TN_HEADER_ROW = ('Security Policy ID', 'Security Policy Name', 'NSX Policy Path','Sequence Number', 'Category', 'is Stateful')
    
    if isinstance(policies_json, dict) and 'results' in policies_json and policies_json['result_count'] > 0: 
        for policy in policies_json["results"]:
            Dict_Policies['id'] = policy['id']
            Dict_Policies['name'] =  policy['display_name']
            Dict_Policies['path'] = policy['path']
            Dict_Policies['sequence_number'] = policy['sequence_number']
            Dict_Policies['category'] = policy['category']
            Dict_Policies['stateful'] = policy['stateful']
            NSX_Config['Policies'].append(Dict_Policies)
            XLS_Lines.append([policy['id'], policy['display_name'], policy['path'], policy['sequence_number'], policy['category'], policy['stateful']])
    else:
        XLS_Lines.append(['No results', "", "", "", "", ""])
    
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

