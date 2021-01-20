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
from lib.system import style, GetAPI, ConnectNSX, os, datetime
import lib.menu

from vmware.vapi.lib import connect
from vmware.vapi.bindings.stub import VapiInterface
from vmware.vapi.bindings.stub import StubConfiguration
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx_client import Alarms
from vmware.vapi.security.user_password import \
    create_user_password_security_context

def CreateXLSAlarms(auth_list):
    # Setup excel workbook and worksheets 
    ls_wkbk = xlwt.Workbook()  
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    XLS_File = lib.menu.XLS_Dest + os.path.sep + "Alarms.xls"
    fname = pathlib.Path(XLS_File)
    if fname.exists():
        print(str(fname) + style.RED + '\n==> File already exists. Not attempting to overwite' + style.NORMAL + "\n")
        return
        
    print('\nGenerating NSX-T Alarms output: ' + style.ORANGE + XLS_File + style.NORMAL + '\n')
    SheetAlarms(auth_list,ls_wkbk)
    ls_wkbk.save(XLS_File)

def SheetAlarms(auth_list,ls_wkbk):
    sheet1 = ls_wkbk.add_sheet('NSX Alarms', cell_overwrite_ok=True)
    #Set Excel Styling
    style_db_center = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                    'font: colour white, bold True; align: horiz center')
    style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left, wrap True')

    #Setup Column widths
    columnA = sheet1.col(0)
    columnA.width = 256 * 20
    columnB = sheet1.col(1)
    columnB.width = 256 * 40
    columnC = sheet1.col(2)
    columnC.width = 256 * 30
    columnD = sheet1.col(3)
    columnD.width = 256 * 20
    columnE = sheet1.col(4)
    columnE.width = 256 * 30
    columnF = sheet1.col(5)
    columnF.width = 256 * 15
    columnG = sheet1.col(6)
    columnG.width = 256 * 20
    columnH = sheet1.col(7)
    columnH.width = 256 * 20
    columnI = sheet1.col(8)
    columnI.width = 256 * 30
    columnJ = sheet1.col(9)
    columnJ.width = 256 * 60

    #Excel Column Headings
    sheet1.write(0, 0, 'Feature', style_db_center)
    sheet1.write(0, 1, 'Event Type', style_db_center)
    sheet1.write(0, 2, 'Reporting Node', style_db_center)
    sheet1.write(0, 3, 'Node Resource Type', style_db_center)
    sheet1.write(0, 4, 'Entity Name', style_db_center)
    sheet1.write(0, 5, 'Severity', style_db_center)
    sheet1.write(0, 6, 'Last Reported Time', style_db_center)
    sheet1.write(0, 7, 'Status', style_db_center)
    sheet1.write(0, 8, 'Description', style_db_center)
    sheet1.write(0, 9, 'Recommended Action', style_db_center)
    
    SessionNSX = ConnectNSX(auth_list)
    tn_json = GetAPI(SessionNSX[0],'/api/v1/transport-nodes', auth_list)
    stub_config = StubConfigurationFactory.new_std_configuration(SessionNSX[1])
    t_nodes = len(tn_json["results"])
    mgr_json = GetAPI(SessionNSX[0],'/api/v1/cluster/nodes', auth_list)
    mgr_nodes = len(mgr_json["results"])

    node_dict = {}
    
    for res in range(0,t_nodes):
        node = tn_json["results"][res]
        node_dict.update({node["node_id"]:node["display_name"]})
    
    for res in range(0,mgr_nodes):
        node = mgr_json["results"][res]
        node_dict.update({node["id"]:node["display_name"]})
    
    alarms_list = []
    alarms_svc = Alarms(stub_config)
    alarms_list = alarms_svc.list()
    x = (len(alarms_list.results))
    y = alarms_list.results
    start_row = 1
    
    for i in range(x):
        sheet1.write(start_row, 0, y[i].feature_name, style_alignleft)
        sheet1.write(start_row, 1, y[i].event_type, style_alignleft)

        for key, value in node_dict.items():
            if key == y[i].node_id:
                sheet1.write(start_row, 2, value, style_alignleft)
            # else:
            #     print(y[i].node_id)

        sheet1.write(start_row, 3, y[i].node_resource_type, style_alignleft)
        sheet1.write(start_row, 4, y[i].entity_id, style_alignleft)
        sheet1.write(start_row, 5, y[i].severity, style_alignleft)

        lrt = y[i].last_reported_time
        dtt = datetime.datetime.fromtimestamp(float(lrt/1000)).strftime('%Y-%m-%d %H:%M:%S')
        
        sheet1.write(start_row, 6, dtt, style_alignleft)
        sheet1.write(start_row, 7, y[i].status, style_alignleft)
        sheet1.write(start_row, 8, y[i].description, style_alignleft)
        sheet1.write(start_row, 9, y[i].recommended_action, style_alignleft)

        start_row +=1
    