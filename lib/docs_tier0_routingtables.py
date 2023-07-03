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
from lib.excel import FillSheet, Workbook, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, os, GetOutputFormat


def SheetT0RoutingTable(SessionNSX,WORKBOOK,TN_WS, NSX_Config ={} ):
    NSX_Config['T0RoutingTable'] = []
    Dict_T0 = {}
    TN_HEADER_ROW = ('T0','Edge Node Path','Route Type', 'Network', 'Admin Distance', 'Next Hop', 'LR Component ID', 'LR Component Type')
    XLS_Lines = []

    ########### GET Tier-0 Gateways  ###########
    t0_url = '/policy/api/v1/infra/tier-0s'
    t0_json = GetAPI(SessionNSX,t0_url)
    if int(t0_json['result_count']) > 0:
        t0_id_list = []
        for i in t0_json["results"]:
            t0_id_list.append(i['display_name'])

        for T0 in t0_id_list:
            nb_routes = 0
            t0_routingtable_json = GetAPI(SessionNSX,t0_url + '/' + str(T0) + '/routing-table')
            if isinstance(t0_routingtable_json, dict) and 'results' in t0_routingtable_json and t0_routingtable_json['result_count'] > 0: 
                for n in t0_routingtable_json["results"]:
                    nb_routes = len(n["route_entries"])
                    # get routes
                    for entry in n['route_entries']:
                        Dict_T0['edge'] = n['edge_node']
                        Dict_T0['T0_name'] = T0
                        Dict_T0['route_type'] = entry['route_type']
                        Dict_T0['network'] = entry['network']
                        Dict_T0['ad'] = entry['admin_distance']
                        Dict_T0['next_hop'] = entry['next_hop']
                        Dict_T0['lr_id']= entry['lr_component_id']
                        Dict_T0['lr_type'] = entry['lr_component_type']
                        NSX_Config['T0RoutingTable'].append(Dict_T0)
                        XLS_Lines.append([T0, n['edge_node'], entry['route_type'], entry['network'],entry['admin_distance'], entry['next_hop'],entry['lr_component_id'],entry['lr_component_type']])
            
            elif not t0_routingtable_json:
                XLS_Lines.append([T0,"No Routing table found","","","","","",""])        
            else:
                XLS_Lines.append([T0," T1 not deployed on Edge Cluster. DR Only","","","","","",""])
            
            print(" --> Get forwarding tables of " + style.ORANGE + T0 + style.NORMAL + " Router: " + style.ORANGE + str(nb_routes) + style.NORMAL + " route(s)")
    else:
        XLS_Lines.append(["No T0 router","","","","","","",""])        


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
