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


def SheetNSXManagerInfo(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    Dict_NSXManager = {}     # Dict NSXManager initialization
    NSX_Config['NSXManager'] = Dict_NSXManager
 
    SessionNSX = ConnectNSX(auth_list)
    ########### SECTION FOR REPORTING ON NSX-T MANAGER CLUSTER ###########
    nsxclstr_url = '/api/v1/cluster/status'
    nsxclstr_json = GetAPI(SessionNSX[0],nsxclstr_url, auth_list)
    # Check online and offline nodes
    if 'online_nodes' in nsxclstr_json['mgmt_cluster_status']:
        online_nodes = str(len(nsxclstr_json['mgmt_cluster_status']['online_nodes']))
    else:
        online_nodes = "0"
    if 'offline_nodes' in nsxclstr_json['mgmt_cluster_status']:
        offline_nodes = str(len(nsxclstr_json['mgmt_cluster_status']['offline_nodes']))
    else:
        offline_nodes = "0"
    
    NSX_Config['NSXManager']['Cluster_id'] = nsxclstr_json['cluster_id']
    NSX_Config['NSXManager']['Cluster_status'] = nsxclstr_json['mgmt_cluster_status']['status']
    NSX_Config['NSXManager']['Cluster_ctrl_status'] = nsxclstr_json['control_cluster_status']['status']
    NSX_Config['NSXManager']['Cluster_overall_status'] = nsxclstr_json['detailed_cluster_status']['overall_status']
    NSX_Config['NSXManager']['Cluster_online_nodes'] = online_nodes
    NSX_Config['NSXManager']['Cluster_offline_nodes'] = offline_nodes
    # Summary Table
    XLS_Lines = [['NSX-T Cluster ID', nsxclstr_json['cluster_id']], ['NSX-T Cluster Status', nsxclstr_json['mgmt_cluster_status']['status']], ['NSX-T Control Cluster Status', nsxclstr_json['control_cluster_status']['status']] , ['Overall NSX-T Cluster Status', nsxclstr_json['detailed_cluster_status']['overall_status']], ['Number of online nodes', online_nodes], ['Number of offline nodes', offline_nodes]]
    idx_second_sheet = len(XLS_Lines) + 2
    # Write in Excel
    for line in XLS_Lines:
    	TN_WS.append(line)
    
    # Format 1st Sheet
    for i in range(1, len(XLS_Lines) + 1):
        TN_WS.cell(row=i, column=1).fill = PatternFill('solid', start_color='004F81BD', end_color='004F81BD') #Blue
        TN_WS.cell(row=i, column=1).font = Font(b=True, color="00FFFFFF") #White

    ConditionnalFormat(TN_WS, 'B2:B4', 'STABLE')
    ConditionnalFormat(TN_WS, 'B5:B5', '3')
    ConditionnalFormat(TN_WS, 'B6:B6', '0')

    # Create second sheet
    TN_WS[idx_second_sheet]
    XLS_Lines = []
    TN_HEADER_ROW = ('Group ID', 'Group Type', 'Group Status','Member FQDN', 'Member IP address', 'Member UUID', 'Member Status')
    for group in nsxclstr_json['detailed_cluster_status']['groups']:
        for member in group['members']:
            XLS_Lines.append([group['group_id'],group['group_type'], group['group_status'], member['member_fqdn'], member['member_ip'], member['member_uuid'], member['member_status']])

    startCell = "A" + str(idx_second_sheet + 1)
    FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA", "TableStyleLight9", False, startCell)
    ConditionnalFormat(TN_WS, 'G10:G' + str(len(XLS_Lines) + 1), 'UP')
    ConditionnalFormat(TN_WS, 'C10:C' + str(len(XLS_Lines) + 1), 'STABLE')
