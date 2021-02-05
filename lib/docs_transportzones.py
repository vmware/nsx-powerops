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
from lib.excel import FillSheet, Workbook
from lib.system import style, GetAPI, ConnectNSX, os
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx_client import TransportZones
from com.vmware.nsx.model_client import TransportZone


def SheetTZ(auth_list,WORKBOOK,TN_WS, NSX_Config ={} ):
    NSX_Config['TZ'] = []
    Dict_TZ = {}
    # Connect NSX
    SessionNSX = ConnectNSX(auth_list)
    stub_config = StubConfigurationFactory.new_std_configuration(SessionNSX[1])
    
    XLS_Lines = []
    TN_HEADER_ROW = ('Name', 'Description', 'ID', 'Ressource Type', 'Host Switch ID', 'Hos Switch Mode', 'Host Switch Name', 'Host Switch is Default', 'is Nested NSX', 'Transport Type', 'Uplink Teaming Policy Name')

    tz_list = TransportZones(stub_config).list()
    for TZ in tz_list.results:
        tz = TZ.convert_to(TransportZone)
        if tz.uplink_teaming_policy_names is not None:
            TZ_Teaming = "\n".join(tz.uplink_teaming_policy_names)
        else:
            TZ_Teaming = ""
        Dict_TZ['name'] = tz.display_name
        Dict_TZ['description'] = tz.description
        Dict_TZ['id'] = tz.id
        Dict_TZ['resource_type'] = tz.resource_type
        Dict_TZ['host_swithc_id'] = tz.host_switch_id
        Dict_TZ['host_switch_mode'] = tz.host_switch_mode
        Dict_TZ['host_switch_name'] = tz.host_switch_name
        Dict_TZ['is_default'] = tz.is_default
        Dict_TZ['nested'] = tz.nested_nsx
        Dict_TZ['type'] = tz.transport_type
        Dict_TZ['teaming'] = tz.uplink_teaming_policy_names
        NSX_Config['TZ'].append(Dict_TZ)
        # Create line
        XLS_Lines.append([tz.display_name, tz.description, tz.id, tz.resource_type, tz.host_switch_id, tz.host_switch_mode, tz.host_switch_name, tz.is_default, tz.nested_nsx, tz.transport_type, TZ_Teaming])

    FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
        