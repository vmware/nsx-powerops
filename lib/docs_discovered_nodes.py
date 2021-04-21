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
from lib.excel import FillSheet, Workbook, ConditionnalFormat
from lib.system import style, GetAPI, ConnectNSX, os, datetime
from vmware.vapi.bindings.stub import StubConfiguration
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx.fabric_client import DiscoveredNodes


def SheetFabDiscoveredNodes(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):

    SessionNSX = ConnectNSX(auth_list)
    stub_config = StubConfigurationFactory.new_std_configuration(SessionNSX[1])
    disc_node_list = DiscoveredNodes(stub_config).list()
    
    Dict_DiscoveredNodes = {}     # Dict Discovered nodes initialization
    NSX_Config['DiscoveredNodes'] = []
    # Construct Line
    XLS_Lines = []
    if disc_node_list.result_count > 0:
        TN_HEADER_ROW = ('Display name', 'OS Type', 'OS Version', 'Node Type', 'Hostname', 'Full Name', 'Management IP', 'Domain name', 'DNS', 'UUID', 'Powerstate', 'In Maintenance Mode', 'Build', 'Vendor', 'Model', 'Serial Number', 'Connection State', 'Licensed Product Name', 'Licensed Product Version', 'Mgmt Server IP', 'Lockdown Mode', 'DAS Host State')
        for node in disc_node_list.results:
            Dict_Properties = {}
            # Loop in properties
            for propertie in node.origin_properties:
                if propertie.key == 'hostName': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'fullName': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'managementIp': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'domainName': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'dnsConfigAddress': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'uuid': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'powerState': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'inMaintenanceMode': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'build': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'vendor': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'model': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'serialNumber': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'connectionState': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'licenseProductName': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'licenseProductVersion': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'managementServerIp': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'lockdownMode': Dict_Properties[propertie.key] = propertie.value
                if propertie.key == 'dasHostState': Dict_Properties[propertie.key] = propertie.value
                            
            # Fill Discovered Nodes Dict
            Dict_DiscoveredNodes['node_name'] = node.display_name
            Dict_DiscoveredNodes['event_type'] = node.os_type
            Dict_DiscoveredNodes['node_name'] = node.os_version
            Dict_DiscoveredNodes['node_resource_type'] = node.node_type
            Dict_DiscoveredNodes['hostName'] = Dict_Properties['hostName']
            Dict_DiscoveredNodes['fullName'] = Dict_Properties['fullName']
            Dict_DiscoveredNodes['managementIp'] = Dict_Properties['managementIp']
            try:
                Dict_DiscoveredNodes['domainName'] = Dict_Properties['domainName']
            except:
                Dict_Properties['domainName'] = 'No Domain Name'
            Dict_DiscoveredNodes['dnsConfigAddress'] = Dict_Properties['dnsConfigAddress']
            Dict_DiscoveredNodes['uuid'] = Dict_Properties['uuid']
            Dict_DiscoveredNodes['powerState'] = Dict_Properties['powerState']
            Dict_DiscoveredNodes['inMaintenanceMode'] = Dict_Properties['inMaintenanceMode']
            Dict_DiscoveredNodes['build'] = Dict_Properties['build']
            Dict_DiscoveredNodes['vendor'] = Dict_Properties['vendor']
            Dict_DiscoveredNodes['model'] = Dict_Properties['model']
            Dict_DiscoveredNodes['serialNumber'] = Dict_Properties['serialNumber']
            Dict_DiscoveredNodes['connectionState'] = Dict_Properties['connectionState']
            Dict_DiscoveredNodes['licenseProductName'] = Dict_Properties['licenseProductName']
            Dict_DiscoveredNodes['licenseProductVersion'] = Dict_Properties['licenseProductVersion']
            Dict_DiscoveredNodes['managementServerIp'] = Dict_Properties['managementServerIp']
            Dict_DiscoveredNodes['lockdownMode'] = Dict_Properties['lockdownMode']
            Dict_DiscoveredNodes['dasHostState'] = Dict_Properties['dasHostState']
            NSX_Config['DiscoveredNodes'].append(Dict_DiscoveredNodes)

            # write one line for a node
            XLS_Lines.append([node.display_name,node.os_type, node.os_version, node.node_type,Dict_Properties['hostName'], Dict_Properties['fullName'], Dict_Properties['managementIp'], Dict_Properties['domainName'], Dict_Properties['dnsConfigAddress'], Dict_Properties['uuid'], Dict_Properties['powerState'], Dict_Properties['inMaintenanceMode'], Dict_Properties['build'], Dict_Properties['vendor'], Dict_Properties['model'], Dict_Properties['serialNumber'], Dict_Properties['connectionState'], Dict_Properties['licenseProductName'], Dict_Properties['licenseProductVersion'], Dict_Properties['managementServerIp'], Dict_Properties['lockdownMode'], Dict_Properties['dasHostState']])
    else:
        XLS_Lines = ('No result', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '')

    FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
    ConditionnalFormat(TN_WS, 'K2:K' + str(len(XLS_Lines) + 1), 'poweredOn')
    ConditionnalFormat(TN_WS, 'L2:L' + str(len(XLS_Lines) + 1), 'false')
    ConditionnalFormat(TN_WS, 'Q2:Q' + str(len(XLS_Lines) + 1), 'connected')
