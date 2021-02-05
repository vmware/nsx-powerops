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
from lib.excel import FillSheet, Workbook
from lib.system import style, GetAPI, ConnectNSX, os
from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context


def SheetRouterSum(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    if 'LR' not in NSX_Config:
        NSX_Config['LR'] = []
    Dict_LR = {}

    SessionNSX = ConnectNSX(auth_list)
   ########### GET Logical Routers  ###########
    lr_list_url = '/api/v1/logical-routers'
    lr_list_json = GetAPI(SessionNSX[0],lr_list_url, auth_list)
    ########### GET Edge Clusters  ###########
    edge_list_url = '/api/v1/edge-clusters'
    edge_list_json = GetAPI(SessionNSX[0],edge_list_url, auth_list)
    ########### CREATE LIST OF TUPLES - EDGE-ID / EDGE NAME ###########
    edge_list = []
    if edge_list_json['result_count'] > 0:
        for i in edge_list_json["results"]:
            edge_list.append(tuple((i['id'],i['display_name'])))

    XLS_Lines = []
    TN_HEADER_ROW = ('Logical Router Name', 'Logical Router ID', 'Edge Cluster Name', 'Edge Custer ID', 'Logical Router Type', 'High Availability Mode', 'Enable Standby Relocation', 'Failover Mode')
    if lr_list_json['result_count'] > 0:
        for LR in lr_list_json['results']:
            HA = ""
            RELOC = ""
            FAILOVER = ""
            LRType = ""
            EdgeClusterName = ""
            LRID = ""
            if 'edge_cluster_id' in LR:
                LRID = LR['edge_cluster_id']
                # Get Edge Cluster Name
                for ec in edge_list:
                        if LR['edge_cluster_id'] == ec[0]:
                            EdgeClusterName = ec[1]

            if 'router_type' in LR:
                LRType = LR['router_type']
            if 'high_availability_mode' in LR:
                HA = LR['high_availability_mode']
            if 'allocation_profile' in LR:
                RELOC = LR['allocation_profile']['enable_standby_relocation']
            if 'failover_mode' in LR:
                FAILOVER = LR['failover_mode']
            Dict_LR['name'] = LR['display_name']
            Dict_LR['id'] = LR['id']
            Dict_LR['edge_cluster_name'] = EdgeClusterName
            Dict_LR['edge_cluster_id'] = LRID
            Dict_LR['router_type'] = LRType
            Dict_LR['failover_mode'] = FAILOVER
            Dict_LR['ha_mode'] = HA
            Dict_LR['relocation'] = RELOC
            NSX_Config['LR'].append(Dict_LR)
            XLS_Lines.append([LR['display_name'], LR['id'],EdgeClusterName, LRID, LRType, HA, RELOC, FAILOVER])

    else:
        XLS_Lines.append(['No results', "", "", "", "", "", "", ""])

    FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
