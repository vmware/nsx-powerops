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
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx_client import TransportZones
from com.vmware.nsx.model_client import TransportZone
from vmware.vapi.security.user_password import \
        create_user_password_security_context

# Output directory for Excel Workbook
os.chdir(dest)

# Setup excel workbook and worksheets 
ls_wkbk = Workbook()  
sheet1 = ls_wkbk.add_sheet('Transport Zones', cell_overwrite_ok=True)

#Set Excel Styling
style_db_center = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                'font: colour white, bold True; align: horiz center')
style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left')

#Setup Column widths
columnA = sheet1.col(0)
columnA.width = 256 * 30
columnB = sheet1.col(1)
columnB.width = 256 * 40
columnC = sheet1.col(2)
columnC.width = 256 * 40
columnD = sheet1.col(3)
columnD.width = 256 * 20
columnE = sheet1.col(4)
columnE.width = 256 * 40
columnF = sheet1.col(5)
columnF.width = 256 * 22
columnG = sheet1.col(6)
columnG.width = 256 * 25
columnH = sheet1.col(7)
columnH.width = 256 * 25
columnI = sheet1.col(8)
columnI.width = 256 * 20
columnJ = sheet1.col(9)
columnJ.width = 256 * 25
columnJ = sheet1.col(10)
columnJ.width = 256 * 25

#Excel Column Headings
sheet1.write(0, 0, 'NAME', style_db_center)
sheet1.write(0, 1, 'DESCRIPTION', style_db_center)
sheet1.write(0, 2, 'ID', style_db_center)
sheet1.write(0, 3, 'RESOURCE TYPE', style_db_center)
sheet1.write(0, 4, 'HOST SWITCH ID', style_db_center)
sheet1.write(0, 5, 'HOST SWITCH MODE', style_db_center)
sheet1.write(0, 6, 'HOST SWITCH NAME', style_db_center)
sheet1.write(0, 7, 'HOST SWITCH IS DEFAULT', style_db_center)
sheet1.write(0, 8, 'IS NESTED NSX', style_db_center)
sheet1.write(0, 9, 'TRANSPORT TYPE', style_db_center)
sheet1.write(0, 10, 'UPLINK TEAMING POLICY NAME', style_db_center)

#Main Function
def main():
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("Transport Zones.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating NSX-T Transport Zone output....')
    print('')

    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0])
    stub_config = StubConfigurationFactory.new_std_configuration(connector)
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)
    
    tz_list = []
    tz_svc = TransportZones(stub_config)
    tz_list = tz_svc.list()
    r = tz_list.results
    start_row = 1
    for i in r:
        tz = i.convert_to(TransportZone)
        sheet1.write(start_row, 0, tz.display_name)
        sheet1.write(start_row, 1, tz.description)
        sheet1.write(start_row, 2, tz.id)
        sheet1.write(start_row, 3, tz.resource_type)
        sheet1.write(start_row, 4, tz.host_switch_id)
        sheet1.write(start_row, 5, tz.host_switch_mode)
        sheet1.write(start_row, 6, tz.host_switch_name)
        sheet1.write(start_row, 7, tz.is_default)
        sheet1.write(start_row, 8, tz.nested_nsx)
        sheet1.write(start_row, 9, tz.transport_type)
        sheet1.write(start_row, 10,tz.uplink_teaming_policy_names)
        start_row += 1
    
    ls_wkbk.save('Transport Zones.xls')
    
if __name__ == "__main__":
    main()
