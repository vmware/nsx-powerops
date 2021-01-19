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
from lib.system import *
import lib.menu

from vmware.vapi.bindings.stub import StubConfiguration
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

def CreateXLSSecPol(auth_list):
    # Setup excel workbook and worksheets 
    secpol_wkbk = xlwt.Workbook()  
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    XLS_File = lib.menu.XLS_Dest + os.path.sep + "Security_Policies.xls"
    fname = pathlib.Path(XLS_File)

    if fname.exists():
        print(str(fname) + style.RED + '\n==> File already exists. Not attempting to overwite' + style.NORMAL + "\n")
        return

    print('\nGenerating Security Policy output: ' + style.ORANGE + XLS_File + style.NORMAL + '\n')
    SheetSecPol(auth_list,secpol_wkbk)
    secpol_wkbk.save(XLS_File)

def SheetSecPol(auth_list, secpol_wkbk):
    sheet1 = secpol_wkbk.add_sheet('Security Policies', cell_overwrite_ok=True)

    #Set Excel Styling
    style_db_center = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                    'font: colour white, bold True; align: horiz center')
    style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left, wrap True')

    #Setup Column widths
    columnA = sheet1.col(0)
    columnA.width = 256 * 30
    columnB = sheet1.col(1)
    columnB.width = 256 * 30
    columnC = sheet1.col(2)
    columnC.width = 256 * 60
    columnD = sheet1.col(3)
    columnD.width = 256 * 20
    columnE = sheet1.col(4)
    columnE.width = 256 * 30
    columnF = sheet1.col(5)
    columnF.width = 256 * 20

    #Excel Column Headings
    sheet1.write(0, 0, 'SECURITY POLICY ID', style_db_center)
    sheet1.write(0, 1, 'SECURITY POLICY NAME', style_db_center)
    sheet1.write(0, 2, 'NSX POLICY PATH', style_db_center)
    sheet1.write(0, 3, 'SEQUENCE NUMBER', style_db_center)
    sheet1.write(0, 4, 'CATEGORY', style_db_center)
    sheet1.write(0, 5, 'IS STATEFUL', style_db_center)

    SessionNSX = ConnectNSX(auth_list)
    policies_url = '/policy/api/v1/infra/domains/default/security-policies'
    policies_json = GetAPI(SessionNSX[0],policies_url, auth_list)
    stub_config = StubConfigurationFactory.new_std_configuration(SessionNSX[1])

    x = len(policies_json["results"])
    start_row = 1
    for i in range(0,x):
        sheet1.write(start_row, 0, policies_json["results"][i]["id"], style_alignleft)
        sheet1.write(start_row, 1, policies_json["results"][i]["display_name"], style_alignleft)
        sheet1.write(start_row, 2, policies_json["results"][i]["path"], style_alignleft)
        sheet1.write(start_row, 3, policies_json["results"][i]["sequence_number"], style_alignleft)      
        sheet1.write(start_row, 4, policies_json["results"][i]["category"], style_alignleft)
        sheet1.write(start_row, 5, policies_json["results"][i]["stateful"], style_alignleft)
        start_row +=1
