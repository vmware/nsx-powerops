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

from _createdir import dest
from _nsxauth import auth_list
from xlwt import Workbook

from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

# Output directory for Excel Workbook
os.chdir(dest)

# Setup excel workbook and worksheets 
lr_ports_wkbk = Workbook()  
lr_ports = lr_ports_wkbk.add_sheet('Logical Router Ports', cell_overwrite_ok=True)

style_db_left = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                'font: colour white, bold True; align: horiz left, vert centre')
style_db_centre = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                'font: colour white, bold True; align: horiz centre, vert centre')
style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left, wrap True')

columnA = lr_ports.col(0)
columnA.width = 256 * 55
columnB = lr_ports.col(1)
columnB.width = 256 * 15
columnC = lr_ports.col(2)
columnC.width = 256 * 20
columnD = lr_ports.col(3)
columnD.width = 256 * 40
columnE = lr_ports.col(4)
columnE.width = 256 * 20
columnF = lr_ports.col(5)
columnF.width = 256 * 40
columnG = lr_ports.col(6)
columnG.width = 256 * 40
columnH = lr_ports.col(7)
columnH.width = 256 * 40
columnI = lr_ports.col(8)
columnI.width = 256 * 15

def main():
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("Logical Router Ports.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating Logical Router Port output....')
    print('')

    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0] )
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)

    ########### GET Logical Routers  ###########
    lr_ports_url = '/api/v1/search/query?query=resource_type:LogicalPort'
    lr_ports_json = session.get('https://' + auth_list[0] + str(lr_ports_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()

    ########### GET Logical-Switches  ###########
    lswitch_url = '/api/v1/logical-switches'
    lswitch_json = session.get('https://' + auth_list[0] + str(lswitch_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()

    ########### CREATE LIST OF TUPLES - EDGE-ID / EDGE NAME ###########
    lswitch_list = []
    for i in lswitch_json["results"]:
        lswitch_list.append(tuple((i['id'],i['display_name'])))
    
    total_lr_ports = lr_ports_json["result_count"]

    lr_ports.write(0,0, 'Total Logical Router Ports',style_db_left)
    lr_ports.write(0,1,total_lr_ports,style_alignleft)
    
    lr_ports.write(2,0, 'LR Port Name',style_db_centre)
    lr_ports.write(2,1, 'Admin State',style_db_centre)
    lr_ports.write(2,2, 'Create User',style_db_centre)
    lr_ports.write(2,3, 'ID',style_db_centre)
    lr_ports.write(2,4, 'Attachment Type',style_db_centre)
    lr_ports.write(2,5, 'Attachment ID',style_db_centre)
    lr_ports.write(2,6, 'Logical Switch ID',style_db_centre)
    lr_ports.write(2,7, 'Logical Switch',style_db_centre)
    lr_ports.write(2,8, 'Status',style_db_centre)

    start_row = 3
    for i in lr_ports_json["results"]:
        lr_ports.write(start_row,0, i['display_name']) 
        lr_ports.write(start_row,1, i['admin_state']) 
        lr_ports.write(start_row,2, i['_create_user']) 
        lr_ports.write(start_row,3, i['id']) 
        try:
            lr_ports.write(start_row,4,list(i['attachment'].values())[0])
        except:
            lr_ports.write(start_row,4,'No Attachment')
        try:
            lr_ports.write(start_row,5,list(i['attachment'].values())[1])
        except:
            lr_ports.write(start_row,5,'No Attachment')
        lr_ports.write(start_row,6, i['logical_switch_id'])

        for ls in lswitch_list:
            if i['logical_switch_id'] == ls[0]:
                lr_ports.write(start_row,7,ls[1])
               
        lr_ports.write(start_row,8, i['status']['status']) 
                        
        start_row += 1

    lr_ports_wkbk.save('Logical Router Ports.xls')
    
if __name__ == "__main__":
    main()
