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
from lib.excel import FillSheet, Workbook, ConditionnalFormat, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, ConnectNSX, os, GetOutputFormat


def SheetRouterPorts(auth_list,WORKBOOK,TN_WS,NSX_Config = {}):
    if 'LRPorts' not in NSX_Config:
        NSX_Config['LRPorts'] = []
    Dict_Ports = {}

    SessionNSX = ConnectNSX(auth_list)
    ########### GET LogicalPortDownLink  ###########
    LRports_Down_url = '/api/v1/search/query?query=resource_type:LogicalRouterDownLinkPort'
    LRports_Down_json = GetAPI(SessionNSX[0],LRports_Down_url, auth_list)
    ########### GET Logical Routers  ###########
    lr_ports_url = '/api/v1/search/query?query=resource_type:LogicalPort'
    lr_ports_json = GetAPI(SessionNSX[0],lr_ports_url, auth_list)
    ########### GET Logical Routers  ###########
    lr_list_url = '/api/v1/logical-routers'
    lr_list_json = GetAPI(SessionNSX[0],lr_list_url, auth_list)
    ########### CREATE LIST OF TUPLES - EDGE-ID / EDGE NAME ###########
    lswitch_list = []
    XLS_Lines = []
    TN_HEADER_ROW = ('LR Port Name', 'ID', 'Attachment Type', 'Logical Router Name', 'Attachment ID', 'Logical Switch ID', 'Logical Switch','Create User', 'Admin State', 'Status')
    ########### GET Logical-Switches  ###########
    lswitch_url = '/api/v1/logical-switches'
    lswitch_json = GetAPI(SessionNSX[0],lswitch_url, auth_list)

    for i in lswitch_json["results"]:
        lswitch_list.append(tuple((i['id'],i['display_name'])))

    if lr_ports_json['result_count'] > 0:
        for port in lr_ports_json["results"]:
            # Check is attachment key is in Dict
            if 'attachment' in port: 
                Attachement_type = port['attachment']['attachment_type']
                Attachement_ID= port['attachment']['id']
            else:
                Attachement_type = 'No Attachment'
                Attachement_ID = 'No Attachment'
            # Get the name of LS
            LS_Name = ""
            LR_Name = ""
            for ls in lswitch_list:
                if port['logical_switch_id'] == ls[0]:
                    LS_Name = ls[1]
                    # Get Router Name
                    for lr in LRports_Down_json['results']:
                        if 'linked_logical_switch_port_id' in lr:
                            if port['id'] == lr['linked_logical_switch_port_id']['target_id']:
                                for router in lr_list_json['results']:
                                    if lr['logical_router_id'] == router['id']: LR_Name = router['display_name']

            Dict_Ports['name'] = port['display_name']
            Dict_Ports['state'] =  port['admin_state']
            Dict_Ports['create_user'] = port['_create_user']
            Dict_Ports['router'] = LR_Name
            Dict_Ports['id'] = port['id']
            Dict_Ports['att_type'] = Attachement_type
            Dict_Ports['att_id'] = Attachement_ID
            Dict_Ports['LS_id'] = port['logical_switch_id']
            Dict_Ports['LS_name'] = LS_Name
            Dict_Ports['status'] = port['status']['status']
            NSX_Config['LRPorts'].append(Dict_Ports)
            XLS_Lines.append([port['display_name'], port['id'],Attachement_type,LR_Name, Attachement_ID, port['logical_switch_id'],LS_Name,port['_create_user'],port['admin_state'], port['status']['status']])
    else:
        XLS_Lines.append(['No results', "", "", "", "", "", "", "", ""])
        
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
        if len(XLS_Lines) > 0:
            ConditionnalFormat(TN_WS, 'J2:J' + str(len(XLS_Lines) + 1), 'UP')
            ConditionnalFormat(TN_WS, 'I2:I' + str(len(XLS_Lines) + 1), 'UP')
