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
dfw_wkbk = Workbook()  
sheet1 = dfw_wkbk.add_sheet('NSX-T Services', cell_overwrite_ok=True)
style_wrap = xlwt.easyxf('align: wrap True')
style_db_center = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                'font: colour white, bold True; align: horiz center')

#Setup Column widths
columnA = sheet1.col(0)
columnA.width = 256 * 60
columnB = sheet1.col(1)
columnB.width = 256 * 60
columnC = sheet1.col(2)
columnC.width = 256 * 20
columnD = sheet1.col(3)
columnD.width = 256 * 65
columnE = sheet1.col(4)
columnE.width = 256 * 30
columnF = sheet1.col(5)
columnF.width = 256 * 20

style_wrap = xlwt.easyxf('alignment: wrap True')

def main():   
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("NSX-T Services.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating NSX-T Services output....')
    print('')

    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0])
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)

    services_url = '/policy/api/v1/infra/services'
    services_json = session.get('https://' + auth_list[0] + str(services_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()

    service_count = (services_json["result_count"])

    sheet1.write(0, 0, 'Service Name', style_db_center)
    sheet1.write(0, 1, 'Service Entries', style_db_center)
    sheet1.write(0, 2, 'Service Type', style_db_center)
    sheet1.write(0, 3, 'Port # / Additional Properties', style_db_center)
    sheet1.write(0, 4, 'Tags', style_db_center)
    sheet1.write(0, 5, 'Scope', style_db_center)

    start_row = 1

    for i in range(1,service_count):
        sheet1.write(start_row, 0, (services_json["results"][i]["display_name"]))
        svc_entries = (services_json["results"][i]["service_entries"])
        if "tags" in services_json["results"][i]:
                tag_length = (len(services_json["results"][i]["tags"]))
                tag_list = []
                scope_list = []
                for t in range(0,tag_length):
                    tag_list.append(services_json["results"][i]["tags"][t]["tag"])
                    scope_list.append(services_json["results"][i]["tags"][t]["scope"])
                sheet1.write(start_row, 4, ', '.join(tag_list))
                sheet1.write(start_row, 5, ', '.join(scope_list), style_wrap)
        for se in range(0,len(svc_entries)):
            sheet1.write(start_row, 1, (services_json["results"][i]["service_entries"][se]["id"]))
            if "l4_protocol" in services_json["results"][i]["service_entries"][se]:
                sheet1.write(start_row, 2, (services_json["results"][i]["service_entries"][se]["l4_protocol"]))
                d_ports = ",  "
                s = (services_json["results"][i]["service_entries"][se]["destination_ports"])
                sheet1.write(start_row, 3, (d_ports.join(s)))
            elif "protocol" in services_json["results"][i]["service_entries"][se]:
                prot = (services_json["results"][i]["service_entries"][se])
                sheet1.write(start_row, 2, (prot["protocol"]))
                if "icmp_type" in prot and "icmp_code" in prot:
                    i_type = str(prot["icmp_type"])
                    i_code = str(prot["icmp_code"])
                    sheet1.write(start_row, 3, ('ICMP TYPE: '+i_type, '    ','ICMP CODE: '+i_code))
            elif "alg" in services_json["results"][i]["service_entries"][se]:
                sheet1.write(start_row, 2, (services_json["results"][i]["service_entries"][se]["alg"]))
                sheet1.write(start_row, 3, (services_json["results"][i]["service_entries"][se]["destination_ports"]))
            elif "protocol_number" in services_json["results"][i]["service_entries"][se]:
                pn = str(services_json["results"][i]["service_entries"][se]["protocol_number"])
                sheet1.write(start_row, 2, ('Protocol Number: ',(pn)))
            elif "ether_type" in services_json["results"][i]["service_entries"][se]:
                e_type = str(services_json["results"][i]["service_entries"][se]["ether_type"])
                sheet1.write(start_row, 2, ('Ether Type: ',(e_type)))
            else:
                sheet1.write(start_row, 2, ('IGMP'))
            start_row+=1

    dfw_wkbk.save('NSX-T Services.xls') 

if __name__ == "__main__":
    main()

