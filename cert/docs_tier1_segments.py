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

from _createdir import dest
from _cert import Crt, Key, headers, nsx_mgr
from xlwt import Workbook

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Output directory for Excel Workbook
os.chdir(dest)

# Setup excel workbook and worksheets 
t1_segments_wkbk = Workbook()  
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
sheet1.write(0, 0, 'Tier1 Segment ID', style_db_center)
sheet1.write(0, 1, 'Segment Gateway', style_db_center)
sheet1.write(0, 2, 'Segment Network', style_db_center)
sheet1.write(0, 3, 'Connected to Tier1', style_db_center)

def main():
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("Tier-1 Segments.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating Tier-1 Segment output....')
    print('')

    session = requests.session()
    session.verify = False
    session.cert = (Crt, Key)

    ########### GET Logical Routers  ###########
    t1_url = '/policy/api/v1/infra/tier-1s'
    t1_json = requests.get(nsx_mgr + str(t1_url), headers=headers, cert=session.cert, verify=session.verify).json()

    t1_path_list = []
    for i in t1_json["results"]:
        t1_path_list.append(i['path'])

    t1_segment_list = []
    for i in t1_path_list:
        t1_segment_url = '/policy/api/v1/search?query=resource_type:Segment&&dsl=segment where connectivity path=' + str(i) + '' 
        t1_segment_list.append(t1_segment_url)

    start_row = 1
    for i in t1_segment_list:
        t1_segment_json = requests.get(nsx_mgr + str(i), headers=headers, cert=session.cert, verify=session.verify).json()
        for n in t1_segment_json["results"]:
            sheet1.write(start_row, 0, n['id'])
            sheet1.write(start_row, 1, n['subnets'][0]['gateway_address'])
            sheet1.write(start_row, 2, n['subnets'][0]['network'])
            
            path_string = str(n['connectivity_path'])
            split_path_string = (path_string.split("/"))
            split_string = str((split_path_string[-1]))
            t1_connectivity = (split_string.split("'")[0])
            
            sheet1.write(start_row, 3, t1_connectivity)
            start_row += 1
    
    t1_segments_wkbk.save('Tier-1 Segments.xls')
    
if __name__ == "__main__":
    main()