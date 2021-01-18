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

import requests
import urllib3
import xlwt
import os
import pathlib
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

from lib.system import *
import lib.menu
from xlwt import Workbook

from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

def CreateXLST1Segments(auth_list):
    # Setup excel workbook and worksheets 
    t1_segments_wkbk = Workbook()  
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    XLS_File = lib.menu.XLS_Dest + os.path.sep + "Tier-1_Segments.xls"
    fname = pathlib.Path(XLS_File)
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating Tier-1 Segment output: %s' % XLS_File)
    print('')
    SheetT1Segments(auth_list,t1_segments_wkbk)
    t1_segments_wkbk.save(XLS_File)


def SheetT1Segments(auth_list,t1_segments_wkbk):
    sheet1 = t1_segments_wkbk.add_sheet('Tier1 Segments', cell_overwrite_ok=True)
    style_db_center = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                    'font: colour white, bold True; align: horiz center')
    style_alignleft = xlwt.easyxf('font: colour black, bold True; align: horiz left, wrap True')

    #Setup Column widths
    columnA = sheet1.col(0)
    columnA.width = 256 * 50
    columnB = sheet1.col(1)
    columnB.width = 256 * 20
    columnC = sheet1.col(2)
    columnC.width = 256 * 20
    columnD = sheet1.col(3)
    columnD.width = 256 * 50

    #Excel Column Headings
    sheet1.write(0, 0, 'Tier1 Segment Name', style_db_center)
    sheet1.write(0, 1, 'Tier1 Segment ID', style_db_center)
    sheet1.write(0, 2, 'Segment Gateway', style_db_center)
    sheet1.write(0, 3, 'Segment Network', style_db_center)
    sheet1.write(0, 4, 'Connected to Tier1 Name', style_db_center)
    sheet1.write(0, 5, 'Connected to Tier1 ID', style_db_center)

    SessionNSX = ConnectNSX(auth_list)
    t1_url = '/policy/api/v1/infra/tier-1s'
    t1_json = GetAPI(SessionNSX[0],t1_url, auth_list)

    start_row = 1
    for i in t1_json["results"]:
        t1_segment_url = '/policy/api/v1/search?query=resource_type:Segment&&dsl=segment where connectivity path=' + str(i['path']) + ''
        t1_segment_json = GetAPI(SessionNSX[0],t1_segment_url, auth_list)

        for n in t1_segment_json["results"]:
            sheet1.write(start_row, 0, n['display_name'])
            sheet1.write(start_row, 1, n['id'])
            sheet1.write(start_row, 2, n['subnets'][0]['gateway_address'])
            sheet1.write(start_row, 3, n['subnets'][0]['network'])
            sheet1.write(start_row, 4, i['display_name'])
            sheet1.write(start_row, 5, str(n['connectivity_path']).split("/")[3])

            start_row += 1
