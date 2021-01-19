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
import xlwt
import pathlib
from lib.system import style, GetAPI, ConnectNSX, os
import lib.menu

from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

def CreateXLST0RoutingTable(auth_list):
    t0_routing_wkbk = xlwt.Workbook()
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    XLS_File = lib.menu.XLS_Dest + os.path.sep + "Tier-0_Routing.xls"
    fname = pathlib.Path(XLS_File)
    if fname.exists():
        print(str(fname) + style.RED + '\n==> File already exists. Not attempting to overwite' + style.NORMAL + "\n")
        return

    print('\nGenerating Tier-0 Routing Tables: ' + style.ORANGE + XLS_File + style.NORMAL + '\n')
    SheetT0RoutingTable(auth_list,t0_routing_wkbk)
    t0_routing_wkbk.save(XLS_File)


def SheetT0RoutingTable(auth_list,t0_routing_wkbk):
    # Setup excel workbook and worksheets   
    style_db_center = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                    'font: colour white, bold True; align: horiz center, wrap True')
    style_alignleft = xlwt.easyxf('font: colour black, bold True; align: horiz left, wrap True')

    SessionNSX = ConnectNSX(auth_list)
    ########### GET Edge Clusters  ###########
    edge_list_url = '/api/v1/search/query?query=resource_type:Edgenode'
    edge_list_json = GetAPI(SessionNSX[0],edge_list_url, auth_list)
    ########### CREATE LIST OF TUPLES - EDGE-ID / EDGE NAME ###########
    edge_list = []
    for i in edge_list_json["results"]:
        edge_list.append(tuple((i['id'],i['display_name'])))
    ########### GET Tier-0 Gateways  ###########
    t0_url = '/policy/api/v1/infra/tier-0s'
    t0_json = GetAPI(SessionNSX[0],t0_url, auth_list)

    t0_id_list = []
    for i in t0_json["results"]:
        t0_id_list.append(i['id'])

    for i in t0_id_list:
        start_row_0 = 0
        start_row_1 = 1
        start_row_2 = 2
        start_row_3 = 3
        start_row_4 = 4
        start_row_5 = 5
        start_row_6 = 6
        start_row_7 = 7

        sheet = t0_routing_wkbk.add_sheet(str(i) + "_Table", cell_overwrite_ok=True)
        col_width_A = sheet.col(0)
        col_width_A.width = 256 * 30
        col_width_B = sheet.col(1)
        col_width_B.width = 256 * 150
        try:
            t0_routingtable_json = session.get('https://' + auth_list[0] + t0_url + '/' + str(i) + '/routing-table', auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
            for n in t0_routingtable_json["results"]:
                route_entries = n['route_entries']

                edge_string = str(n['edge_node'])
                split_edge_string = (edge_string.split("/"))
                split_string = str((split_edge_string[-1]))
                e_node = (split_string.split("'")[0])

                for entry in route_entries:
                    sheet.write(start_row_0, 0, 'Edge Node', style_db_center)
                    for edge in edge_list:
                        if e_node == edge[0]:
                            sheet.write(start_row_0, 1, edge[1], style_alignleft)                   
                    sheet.write(start_row_1, 0, 'Edge Node Path', style_db_center)
                    sheet.write(start_row_1, 1, n['edge_node'], style_alignleft)
                    sheet.write(start_row_2, 0, 'Route Type', style_db_center)
                    sheet.write(start_row_2, 1, entry['route_type'], style_alignleft)
                    sheet.write(start_row_3, 0, 'Network', style_db_center)
                    sheet.write(start_row_3, 1, entry['network'], style_alignleft)
                    sheet.write(start_row_4, 0, 'Admin Distance', style_db_center)
                    sheet.write(start_row_4, 1, entry['admin_distance'], style_alignleft)
                    sheet.write(start_row_5, 0, 'Next Hop', style_db_center)
                    sheet.write(start_row_5, 1, entry['next_hop'], style_alignleft)
                    sheet.write(start_row_6, 0, 'LR Component ID', style_db_center)
                    sheet.write(start_row_6, 1, entry['lr_component_id'], style_alignleft)
                    sheet.write(start_row_7, 0, 'LR Component Type', style_db_center)
                    sheet.write(start_row_7, 1, entry['lr_component_type'], style_alignleft)
                
                    start_row_0 += 9
                    start_row_1 += 9
                    start_row_2 += 9
                    start_row_3 += 9
                    start_row_4 += 9
                    start_row_5 += 9
                    start_row_6 += 9
                    start_row_7 += 9
        except:
            sheet.write(0, 0, 'NO ROUTING TABLE', style_db_center)    
