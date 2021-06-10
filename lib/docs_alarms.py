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
from lib.system import style, GetAPI, ConnectNSX, os, datetime, GetOutputFormat
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx_client import Alarms


def SheetAlarms(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    Dict_Alarm = {}     # Dict alarm initialization
    NSX_Config['Alarms'] = []
    # Connect NSX
    SessionNSX = ConnectNSX(auth_list)
    TN_json = GetAPI(SessionNSX[0],'/api/v1/transport-nodes', auth_list)
    Edge_json = GetAPI(SessionNSX[0],'/api/v1/cluster/nodes', auth_list)
    stub_config = StubConfigurationFactory.new_std_configuration(SessionNSX[1])
    node_dict = {}
    # Construct Dicts of Edge Node and Transport Node for Name from ID
    if TN_json['result_count'] > 0:
        for TN in TN_json['results']:
            node_dict.update({TN["id"]:TN["display_name"]})
    if Edge_json['result_count'] > 0:
        for EDGE in Edge_json['results']:
            node_dict.update({EDGE["id"]:EDGE["display_name"]})

    # Alarms extract
    alarms_svc = Alarms(stub_config)
    alarms_list = alarms_svc.list()
    NodeName = ""
    XLS_Lines = []
    TN_HEADER_ROW = ('Feature', 'Event Type', 'Reporting Node', 'Node Ressource Type', 'Entity Name', 'Severity', 'Last Reported Time', 'Status', 'Description', 'Recommended Action')
    if alarms_list.result_count > 0:
        for alarm in alarms_list.results:
            # Get Name of Node from ID
            for key, value in node_dict.items():
                if key == alarm.entity_id: NodeName = value

            # Transform date and time of alarms
            dtt = datetime.datetime.fromtimestamp(float(alarm.last_reported_time/1000)).strftime('%Y-%m-%d %H:%M:%S')
            # Create line
            XLS_Lines.append([alarm.feature_name,alarm.event_type, NodeName, alarm.node_resource_type,  alarm.entity_id,alarm.severity, dtt, alarm.status, alarm.description, alarm.recommended_action])
            # Fill alarm Dict
            Dict_Alarm['feature_name'] = alarm.feature_name
            Dict_Alarm['event_type'] = alarm.event_type
            Dict_Alarm['node_name'] = NodeName
            Dict_Alarm['node_resource_type'] = alarm.node_resource_type
            Dict_Alarm['entity_id'] = alarm.entity_id
            Dict_Alarm['severity'] = alarm.severity
            Dict_Alarm['time'] = dtt
            Dict_Alarm['status'] = alarm.status
            Dict_Alarm['description'] = alarm.description
            Dict_Alarm['recommended_action'] = alarm.recommended_action
            NSX_Config['Alarms'].append(Dict_Alarm)
    else:
        XLS_Lines.append(['No results', "", "", "", "", "", "", "", "", ""])
    
    # Create sheet
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
        ConditionnalFormat(TN_WS, 'F', 'CRITICAL', True, 'RED')
        ConditionnalFormat(TN_WS, 'F', 'HIGH', True, 'ORANGE')
        ConditionnalFormat(TN_WS, 'H', 'RESOLVED', True, 'GREEN')
