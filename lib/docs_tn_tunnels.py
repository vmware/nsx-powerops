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
import xlwt, pathlib
from lib.system import style, GetAPI, ConnectNSX, os
import lib.menu
from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

def CreateXLSTunnels(auth_list):
    # Setup excel workbook and worksheets
    tunnel_wkbk = xlwt.Workbook()  
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    XLS_File = lib.menu.XLS_Dest + os.path.sep + "Transport_Node_Tunnels.xls"
    fname = pathlib.Path(XLS_File)
    if fname.exists():
        print(str(fname) + style.RED + '\n==> File already exists. Not attempting to overwite' + style.NORMAL + "\n")
        return

    print('\nGenerating Transport Node Tunnel Output: ' + style.ORANGE + XLS_File + style.NORMAL)
    print('')
    SheetTunnels(auth_list,tunnel_wkbk)    
    tunnel_wkbk.save(XLS_File)


def SheetTunnels(auth_list,tunnel_wkbk):
    #Set Excel Styling
    style_db_left = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                    'font: colour white, bold True; align: horiz left, vert centre')
    style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left, wrap True')
    style_bold = xlwt.easyxf('font: colour black, bold True; align: horiz left, wrap True')
    style_green = xlwt.easyxf('font: colour green, bold True; align: horiz left, wrap True')
    style_red = xlwt.easyxf('font: colour red, bold True; align: horiz left, wrap True')

    SessionNSX = ConnectNSX(auth_list)
    transport_node_url = '/api/v1/transport-nodes'
    transport_node_json = GetAPI(SessionNSX[0],transport_node_url, auth_list)

    transport_nodes = (transport_node_json['results'])
    tnode_dict = {}
    # Create a tab for each transport node
    for n in range(len(transport_nodes)):
        # Excel sheet title can't exceeded 31 caracters
        if len(transport_nodes[n]['display_name']) > 26: TitleSheet = transport_nodes[n]['display_name'][0:26]
        else: TitleSheet = transport_nodes[n]['display_name'] 

        tnode_dict.update({transport_nodes[n]['node_id']:transport_nodes[n]['display_name']})
        sheet = tunnel_wkbk.add_sheet('TEP_' + TitleSheet, cell_overwrite_ok=True)
        
        #Setup Column widths
        columnA = sheet.col(0)
        columnA.width = 256 * 35
        columnB = sheet.col(1)
        columnB.width = 256 * 40
    
        for uuid in tnode_dict.items():
            tunnel_url = '/api/v1/transport-nodes/' + str(uuid[0]) + '/tunnels'
            tunnel_json = GetAPI(SessionNSX[0],tunnel_url, auth_list)
        
        if tunnel_json["result_count"] == 0:
            sheet.write(0,0, transport_nodes[n]['display_name'] +  ' has 0 tunnels',style_bold)
        else:
            x = (len(tunnel_json['tunnels']))
            sheet.write(0,0, transport_nodes[n]['display_name'] + ' has ' + str(x) + ' tunnels',style_bold)
            row_a = 2
            row_b = 3
            row_c = 4
            row_d = 5
            row_e = 6
            row_f = 7
            row_g = 8
            row_h = 9

            for n in range(x):
                sheet.write(row_a, 0, 'Tunnel Name: ', style_db_left)
                sheet.write(row_a, 1, tunnel_json['tunnels'][n]['name'], style_alignleft)
                sheet.write(row_b, 0, 'Tunnel Status: ', style_db_left)
                if tunnel_json['tunnels'][n]['status'] == 'UP':
                    sheet.write(row_b, 1, tunnel_json['tunnels'][n]['status'], style_green)
                else:
                    sheet.write(row_b, 1, tunnel_json['tunnels'][n]['status'], style_red)
                sheet.write(row_c, 0, 'Egress Interface: ', style_db_left)
                sheet.write(row_c, 1, tunnel_json['tunnels'][n]['egress_interface'], style_alignleft)
                sheet.write(row_d, 0, 'Local Tunnel IP: ', style_db_left)
                sheet.write(row_d, 1, tunnel_json['tunnels'][n]['local_ip'], style_alignleft)
                sheet.write(row_e, 0, 'Remote Tunnel IP: ', style_db_left)
                sheet.write(row_e, 1, tunnel_json['tunnels'][n]['remote_ip'], style_alignleft)
                sheet.write(row_f, 0, 'Remote Node ID: ', style_db_left)
                if 'remote_node_id' in  tunnel_json['tunnels'][n]: sheet.write(row_f, 1, tunnel_json['tunnels'][n]['remote_node_id'], style_alignleft)
                sheet.write(row_g, 0, 'Remote Node: ', style_db_left)
                if 'remote_node_display_name' in  tunnel_json['tunnels'][n]: sheet.write(row_g, 1, tunnel_json['tunnels'][n]['remote_node_display_name'], style_alignleft)
                sheet.write(row_h, 0, 'Tunnel Encapsulation: ', style_db_left)
                sheet.write(row_h, 1, tunnel_json['tunnels'][n]['encap'], style_alignleft)
                
                row_a += 9
                row_b += 9
                row_c += 9
                row_d += 9
                row_e += 9
                row_f += 9
                row_g += 9
                row_h += 9
