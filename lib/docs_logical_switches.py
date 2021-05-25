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
from lib.excel import FillSheet, Workbook, ConditionnalFormat, FillSheetCSV
from lib.system import style, GetAPI, ConnectNSX, os, GetCSV
from vmware.vapi.lib import connect
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx_client import TransportZones
from com.vmware.nsx.model_client import TransportZone
from com.vmware.nsx_client import LogicalSwitches
from com.vmware.nsx.model_client import LogicalSwitch
from vmware.vapi.security.user_password import \
        create_user_password_security_context


def SheetSegments(auth_list,WORKBOOK,TN_WS,NSX_Config = {}):
    NSX_Config['Segments'] = []
    Dict_LS = {}
    # NSX Connection
    SessionNSX = ConnectNSX(auth_list)
    stub_config = StubConfigurationFactory.new_std_configuration(SessionNSX[1])
    ls_svc = LogicalSwitches(stub_config)
    ls_list = ls_svc.list()
    nb = len(ls_list.results)
    tz_svc = TransportZones(stub_config)
    tz_list = tz_svc.list()

    XLS_Lines = []
    TN_HEADER_ROW = ('Segments', 'VNI', 'VLAN', 'Transport Zone Name', 'Transport Zone Type', 'Replication Mode', 'Admin State')

    if ls_list.result_count > 0:
        while True:
            for segment in ls_list.results:
                TZ_NAME = ""
                TZ_Type = ""
                for tz in tz_list.results:
                    if segment.transport_zone_id == tz.id:
                        TZ_NAME = tz.display_name
                        TZ_Type = tz.transport_type

                Dict_LS['segment_name'] = segment.display_name
                Dict_LS['vni'] = segment.vni
                Dict_LS['vlan'] = segment.vlan
                Dict_LS['tz_name'] = TZ_NAME
                Dict_LS['tz_type'] = TZ_Type
                Dict_LS['replication_mode'] = segment.replication_mode
                Dict_LS['status'] = segment.admin_state
                NSX_Config['Segments'].append(Dict_LS)
                XLS_Lines.append([segment.display_name, segment.vni, segment.vlan, TZ_NAME, TZ_Type, segment.replication_mode,segment.admin_state])

            if ls_list.cursor is None:
                break
            else:
                print(" --> more than " + str(nb) + " results for " + style.RED + "Segments" + style.NORMAL + " - please wait")
                ls_list = LogicalSwitches(stub_config).list(cursor =ls_list.cursor )
                nb = len(ls_list.results) + nb


    else:
        XLS_Lines.append(["no Segments", "", "", "", "", "",""])

    if GetCSV():
        CSV = WORKBOOK
        FillSheetCSV(CSV,TN_HEADER_ROW,XLS_Lines)
    else:
        FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
    ConditionnalFormat(TN_WS, 'G2:G' + str(len(XLS_Lines) + 1), 'UP')
