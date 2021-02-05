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
from lib.excel import FillSheet, Workbook, PatternFill, Font,  ConditionnalFormat
from lib.system import style, GetAPI, ConnectNSX, os

def GetEntity(json, tab):
    if 'entities' in json: 
        for entity in json['entities']:
            tab.append([entity['entity'], str(entity['count']), str(entity['alarm_count']), entity['status']])

    return tab

def SheetSummary(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    # Connection to NSX
    SessionNSX = ConnectNSX(auth_list)
    system_url = '/api/v1/ui-controller/system-aggregate-status'
    inventory_url = '/api/v1/ui-controller/inventory-aggregate-status'
    security_url = '/api/v1/ui-controller/security-aggregate-status'
    network_url = '/api/v1/ui-controller/networking-aggregate-status'
    fabric_url = '/api/v1/ui-controller/fabric-aggregate-status'
    inventory_json = GetAPI(SessionNSX[0],inventory_url, auth_list)
    security_json = GetAPI(SessionNSX[0],security_url, auth_list)
    network_json = GetAPI(SessionNSX[0],network_url, auth_list)
    fabric_json = GetAPI(SessionNSX[0],fabric_url, auth_list)
    system_json = GetAPI(SessionNSX[0],system_url, auth_list)

    XLS_Lines = []
    TN_HEADER_ROW = (' ', 'Number', 'Alarms', 'Status')
    XLS_Lines = GetEntity(system_json, XLS_Lines)
    XLS_Lines = GetEntity(fabric_json, XLS_Lines)
    XLS_Lines = GetEntity(inventory_json, XLS_Lines)
    XLS_Lines = GetEntity(network_json, XLS_Lines)
    XLS_Lines = GetEntity(security_json, XLS_Lines)

    a1 = TN_WS['A1']
    a1.font = Font(name='Arial', size=16, bold=True)
    a1.value = "Summary"
    TN_WS[3]
    FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA", "TableStyleLight9", True, start_cell = 'A4')
    ConditionnalFormat(TN_WS, 'D5:D' + str(len(XLS_Lines) + 4), 'UP', False, 'GREEN')
    ConditionnalFormat(TN_WS, 'D5:D' + str(len(XLS_Lines) + 4), 'NONE', False, 'ORANGE')
    ConditionnalFormat(TN_WS, 'D5:D' + str(len(XLS_Lines) + 4), 'UP')
