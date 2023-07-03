#!/usr/local/bin/python3
# coding: utf-8
#############################################################################################################################################################################################
#                                                                                                                                                                                           #
# NSX-T Power Operations                                                                                                                                                                    #
#                                                                                                                                                                                           #
# Copyright 2020 VMware, Inc.  All rights reserved                                                                                                                                          #
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
from lib.excel import FillSheet, Workbook, ConditionnalFormat, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, os, GetOutputFormat
 
def SheetMonitoring(SessionNSX,WORKBOOK,TN_WS,NSX_Config = {}):
    NSX_Config['Nodes'] = []
    TN_HEADER_ROW = ('Name', 'Node Type', 'Type', 'MGT IP', 'Form Factor','SSH Status', 'SSH on boot', 'SNMP Status', 'SNMP on boot', 'SNMP Version','SNMP Servers', 'Syslog Status', 'Syslog on boot', 'Syslog Servers', 'NTP Servers', 'DNS Servers')
    XLS_Lines = []
 
    # Get Edge nodes monitoring config
    transport_node_json = GetAPI(SessionNSX,'/api/v1/transport-nodes')
    # Check if Transport Node present
    if isinstance(transport_node_json, dict) and 'results' in transport_node_json and transport_node_json['result_count'] > 0:
        for node in transport_node_json['results']:
            if node['resource_type'] == 'TransportNode' and node['node_deployment_info']['resource_type'] == 'EdgeNode':
                Node = {
                    'ID': node['id'],
                    'NAME': node['display_name'],
                    'Node_Type': node['node_deployment_info']['resource_type'],
                    'Type': node['node_deployment_info']['deployment_type'],
                    'FormFactor': '',
                    'SNMP_Boot': False,
                    'SNMP_Status': "Disabled",
                    'SNMP_Version': '',
                    'SNMP_Servers': [],
                    'Syslog_Status': 'Disabled',
                    'Syslog_Boot': False,
                    'Syslog_Servers': [],
                    'DNS': [],
                    'NTP': []
                }
                if 'node_settings' in node['node_deployment_info']:
                    if 'ntp_servers' in node['node_deployment_info']['node_settings']:
                        Node['NTP'] = node['node_deployment_info']['node_settings']['ntp_servers']
                    if 'dns_servers' in  node['node_deployment_info']['node_settings']:
                        Node['DNS'] = node['node_deployment_info']['node_settings']['dns_servers']
                    if 'deployment_config' in node['node_deployment_info']:
                        Node['FormFactor'] = node['node_deployment_info']['deployment_config']['form_factor']
                        Node['IP'] = node['node_deployment_info']['deployment_config']['vm_deployment_config']['management_port_subnets'][0]['ip_addresses'][0]
                    else:
                        Node['FormFactor'] = 'Physical'
                        Node['Type'] = 'Physical'
                        Node['IP'] = node['node_deployment_info']['ip_addresses'][0]
 
                # Get SSH informations
                ssh_json = GetAPI(SessionNSX,'/api/v1/transport-nodes/' + Node['ID'] + '/node/services/ssh')
                sshstatus_json = GetAPI(SessionNSX,'/api/v1/transport-nodes/' + Node['ID'] + '/node/services/ssh/status')
                Node['SSH_Boot'] = ssh_json['service_properties']['start_on_boot']
                Node['SSH_Status'] = sshstatus_json['runtime_state'].upper()

                # Get SNMP Informations
                snmp_json = GetAPI(SessionNSX,'/api/v1/transport-nodes/' + Node['ID'] + '/node/services/snmp')
                snmpstatus_json = GetAPI(SessionNSX,'/api/v1/transport-nodes/' + Node['ID'] + '/node/services/snmp/status')
                if type(snmpstatus_json) is dict and 'runtime_state' in snmpstatus_json:
                    Node['SNMP_Status'] = snmpstatus_json['runtime_state'].upper()
                if type(snmp_json) is dict and "service_properties" in snmp_json:
                    Node['SNMP_Boot'] = snmp_json['service_properties']['start_on_boot']
                    if snmp_json['service_properties']['v2_configured']:
                        Node['SNMP_Version'] = 'v2'
                        for snmp_server in snmp_json['service_properties']['v2_targets']:
                            Node['SNMP_Servers'].append(snmp_server['server'])
                    if snmp_json['service_properties']['v3_configured']:
                        Node['SNMP_Version'] = 'v3'
                        for snmp_server in snmp_json['service_properties']['v3_targets']:
                            Node['SNMP_Servers'].append(snmp_server['server'])
 

                # Get Syslog Informations
                syslog_json = GetAPI(SessionNSX,'/api/v1/transport-nodes/' + Node['ID'] + '/node/services/syslog')
                syslogstatus_json = GetAPI(SessionNSX,'/api/v1/transport-nodes/' + Node['ID'] + '/node/services/syslog/status')
                if type(syslogstatus_json) is dict and 'runtime_state' in syslogstatus_json:
                    Node['Syslog_Status'] = syslogstatus_json['runtime_state'].upper()
                if type(syslog_json) is dict and "service_properties" in syslog_json:
                    Node['Syslog_Boot'] = snmp_json['service_properties']['start_on_boot']
 
                XLS_Lines.append([
                    Node['NAME'], 
                    Node['Node_Type'], 
                    Node['Type'], 
                    Node['IP'], 
                    Node['FormFactor'], 
                    Node['SSH_Status'], 
                    Node['SSH_Boot'], 
                    Node['SNMP_Status'], 
                    Node['SNMP_Boot'], 
                    Node['SNMP_Version'], 
                    ', '.join(Node['SNMP_Servers']), 
                    Node['Syslog_Status'], 
                    Node['Syslog_Boot'], 
                    ', '.join(Node['Syslog_Servers']), 
                    ', '.join(Node['NTP']), 
                    ', '.join(Node['DNS'])
                ])
 
    else:
        XLS_Lines.append(["no Transport Nodes", "", "", "", "", "", "", "", "", "", "","","","",""])
 

    # Get NSX Managers monitoring config
    ManagerInfos = GetAPI(SessionNSX,'/api/v1/cluster/status')
    Manager_SNMP_Config = GetAPI(SessionNSX,'/api/v1/node/services/snmp')
    Manager_SNMP_Status = GetAPI(SessionNSX,'/api/v1/node/services/snmp/status')
    Manager_Syslog_Config = GetAPI(SessionNSX,'/api/v1/node/services/syslog')
    Manager_Syslog_Status = GetAPI(SessionNSX,'/api/v1/node/services/syslog/status')
    Manager_Syslog_Servers = GetAPI(SessionNSX,'/api/v1/node/services/syslog/exporters')
    Manager_NTP_Config = GetAPI(SessionNSX,'/api/v1/node/services/ntp')
    Manager_SSH_Config = GetAPI(SessionNSX,'/api/v1/node/services/ssh')
    Manager_SSH_Status = GetAPI(SessionNSX,'/api/v1/node/services/ssh/status')
    Manager_DNS_Servers = GetAPI(SessionNSX,'/api/v1/node/network/name-servers')
 
    for member in ManagerInfos['detailed_cluster_status']['groups'][0]['members']:
        SNMP_Version = ''
        SNMP_Servers = []
        Syslog_Servers = []
        Syslog_Boot = ''
        SSH_Boot = Manager_SSH_Config['service_properties']['start_on_boot']
        for syslog in Manager_Syslog_Servers['results']:
            Syslog_Servers.append(syslog['server'])
        if 'service_properties' in Manager_Syslog_Config:
            Syslog_Boot = Manager_Syslog_Config['service_properties']['start_on_boot']
            Syslog_Servers = Manager_Syslog_Config['service_properties']['start_on_boot']
        if Manager_SNMP_Config['service_properties']['v2_configured']:
            SNMP_Servers = Manager_SNMP_Config['service_properties']['v2_targets']
            SNMP_Version = 'v2'
        if Manager_SNMP_Config['service_properties']['v3_configured']:
            SNMP_Servers = Manager_SNMP_Config['service_properties']['v3_targets']
            SNMP_Version = 'v3'
        XLS_Lines.append([
            member['member_fqdn'], 
            'Manager', 
            'Virtual', 
            member['member_ip'], 
            'n/a', 
            Manager_SSH_Status['runtime_state'].upper(),
            SSH_Boot,
            Manager_SNMP_Status['runtime_state'].upper(), 
            Manager_SNMP_Config['service_properties']['start_on_boot'], 
            SNMP_Version, 
            ', '.join(SNMP_Servers), 
            Manager_Syslog_Status['runtime_state'].upper(), 
            Syslog_Boot, 
            ', '.join(Syslog_Servers), 
            ', '.join(Manager_NTP_Config['service_properties']['servers']), 
            ', '.join(Manager_DNS_Servers['name_servers'])
        ])

    # Create output file
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
            ConditionnalFormat(TN_WS, 'F2:F' + str(len(XLS_Lines) + 1), 'RUNNING')
            ConditionnalFormat(TN_WS, 'H2:H' + str(len(XLS_Lines) + 1), 'RUNNING')
            ConditionnalFormat(TN_WS, 'L2:L' + str(len(XLS_Lines) + 1), 'RUNNING')

