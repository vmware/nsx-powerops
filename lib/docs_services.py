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
from lib.excel import FillSheet, Workbook, FillSheetCSV
from lib.system import style, GetAPI, ConnectNSX, os, GetCSV


def SheetNSXServices(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    NSX_Config['Services'] = []
    Dict_Services = {}
    # Connection to NSX
    SessionNSX = ConnectNSX(auth_list)
    services_url = '/policy/api/v1/infra/services'
    services_json = GetAPI(SessionNSX[0],services_url, auth_list)

    XLS_Lines = []
    TN_HEADER_ROW = ('Services Name', 'Services Entries', 'Service Type', 'Port # / Additionnal Properties', 'Tags', 'Scope')
    if services_json['result_count'] > 0:
        for SR in services_json['results']:
            TAGS = ""
            SCOPE = ""
            if 'tags' in SR:
                tag_list = []
                scope_list = []
                for tag in SR['tags']:
                    tag_list.append(tag['tag'])
                    scope_list.append(tag['scope'])

                TAGS = ", ".join(tag_list)
                SCOPE = ", ".join(scope_list)

            List_SR = []
            List_Proto = []
            List_Ports = []
            for svc in SR['service_entries']:
                List_SR.append(svc['display_name'])
                if 'l4_protocol' in svc: 
                    List_Proto.append(svc['l4_protocol'])
                    Ports = ", ".join(svc['destination_ports'])
                    List_Ports.append(Ports)
                elif 'protocol' in svc:
                    List_Proto.append(svc['protocol'])
                    if "icmp_type" in svc :
                        List_Ports.append(str(svc['icmp_type']))
                elif "alg" in svc:
                    List_Proto.append(svc['alg'])
                    Ports = ", ".join(svc['destination_ports'])
                    List_Ports.append(Ports)
                elif "protocol_number" in svc:
                    List_Proto.append(svc['protocol_number'])
                elif "ether_type" in svc:
                    List_Proto.append(svc['ether_type'])
                else:
                    List_Proto.append('IGMP')

            Proto = "\n".join(List_Proto)
            svc_ports = "\n".join(List_Ports)
            Dict_Services['name'] = SR['display_name']
            Dict_Services['tags'] = TAGS
            Dict_Services['scope'] = SCOPE
            Dict_Services['ports'] = List_Ports
            Dict_Services['protocols'] = List_Proto
            Dict_Services['services_entries'] = List_SR
            NSX_Config['Services'].append(Dict_Services)
            # Create Line
            XLS_Lines.append([SR['display_name'], "\n".join(List_SR), Proto, svc_ports, TAGS, SCOPE])

    else:
        XLS_Lines.append(['No results', "", "", "", "", ""])

    if GetCSV():
        CSV = WORKBOOK
        FillSheetCSV(CSV,TN_HEADER_ROW,XLS_Lines)
    else:
        FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
