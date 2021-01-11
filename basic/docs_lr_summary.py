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
lr_wkbk = Workbook()  
lr_summary = lr_wkbk.add_sheet('Logical Router Summary', cell_overwrite_ok=True)
tier0_lr = lr_wkbk.add_sheet('Tier0 Logical Routers', cell_overwrite_ok=True)
tier0_vrf_lr = lr_wkbk.add_sheet('Tier0 VRF Logical Routers', cell_overwrite_ok=True)
tier1_lr = lr_wkbk.add_sheet('Tier1 Logical Routers', cell_overwrite_ok=True)

style_db_left = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                'font: colour white, bold True; align: horiz left, vert centre')
style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left, wrap True')

sum_columnA = lr_summary.col(0)
sum_columnA.width = 256 * 35
sum_columnB = lr_summary.col(1)
sum_columnB.width = 256 * 15

t0_columnA = tier0_lr.col(0)
t0_columnA.width = 256 * 30
t0_columnB = tier0_lr.col(1)
t0_columnB.width = 256 * 50

t0vrf_columnA = tier0_vrf_lr.col(0)
t0vrf_columnA.width = 256 * 30
t0vrf_columnB = tier0_vrf_lr.col(1)
t0vrf_columnB.width = 256 * 50

t1_columnA = tier1_lr.col(0)
t1_columnA.width = 256 * 30
t1_columnB = tier1_lr.col(1)
t1_columnB.width = 256 * 50

def main():
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("Logical Router Summary.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating Logical Router output....')
    print('')

    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0] )
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)

    ########### GET Logical Routers  ###########
    lr_list_url = '/api/v1/logical-routers'
    lr_list_json = session.get('https://' + auth_list[0] + str(lr_list_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()

    ########### GET Edge Clusters  ###########
    edge_list_url = '/api/v1/edge-clusters'
    edge_list_json = session.get('https://' + auth_list[0] + str(edge_list_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()

    ########### CREATE LIST OF TUPLES - EDGE-ID / EDGE NAME ###########
    edge_list = []
    for i in edge_list_json["results"]:
        edge_list.append(tuple((i['id'],i['display_name'])))
    
    total_lrs = lr_list_json["result_count"]
    
    tier0s = 0
    tier0vrfs = 0
    tier1s = 0

    tier0slist = []
    tier0vrflist = []
    tier1slist = []

    for i in lr_list_json["results"]:
        if i['router_type'] == 'TIER0': 
            tier0s +=1
            tier0slist.append(i)
        elif i['router_type'] == 'VRF': 
            tier0vrfs +=1
            tier0vrflist.append(i)
        elif i['router_type'] == 'TIER1':
            tier1s +=1
            tier1slist.append(i)
    
    lr_summary.write(0,0, 'Total Logical Routers', style_db_left)
    lr_summary.write(0,1, total_lrs, style_alignleft)
    lr_summary.write(1,0, 'Tier0 Logical Routers:', style_db_left)
    lr_summary.write(1,1, tier0s, style_alignleft)
    lr_summary.write(2,0, 'Tier0 VRF Logical Routers:', style_db_left)
    lr_summary.write(2,1, tier0vrfs, style_alignleft)
    lr_summary.write(3,0, 'Tier1 Logical Routers:', style_db_left)
    lr_summary.write(3,1, tier1s, style_alignleft)

    start_row = 0
    for i in tier0slist:
        tier0_lr.write(start_row,0, 'Logical Router Name', style_db_left)
        tier0_lr.write(start_row,1,i['display_name'],style_alignleft)
        start_row += 1
        tier0_lr.write(start_row,0, 'Logical Router ID', style_db_left)
        tier0_lr.write(start_row,1,i['id'],style_alignleft)
        start_row += 1
        tier0_lr.write(start_row,0, 'Edge Cluster Name', style_db_left)
        for ec in edge_list:
            if i['edge_cluster_id'] == ec[0]:
                tier0_lr.write(start_row,1,ec[1],style_alignleft)
        start_row += 1
        tier0_lr.write(start_row,0, 'Edge Cluster ID', style_db_left)
        tier0_lr.write(start_row,1,i['edge_cluster_id'],style_alignleft)
        start_row += 1
        tier0_lr.write(start_row,0, 'Logical Router Type', style_db_left)
        tier0_lr.write(start_row,1,i['router_type'],style_alignleft)
        start_row += 1
        tier0_lr.write(start_row,0, 'High Availability Mode', style_db_left)
        tier0_lr.write(start_row,1,i['high_availability_mode'],style_alignleft)
        start_row += 1
        tier0_lr.write(start_row,0, 'Enable Standby Relocation', style_db_left)
        for n in i['allocation_profile']:
            tier0_lr.write(start_row,1,i['allocation_profile'][n],style_alignleft)
                                      
        start_row += 2
    
    start_row = 0
    for i in tier0vrflist:
        tier0_vrf_lr.write(start_row,0, 'Logical Router Name', style_db_left)
        tier0_vrf_lr.write(start_row,1,i['display_name'],style_alignleft)
        start_row += 1
        tier0_vrf_lr.write(start_row,0, 'Logical Router ID', style_db_left)
        tier0_vrf_lr.write(start_row,1,i['id'],style_alignleft)
        start_row += 1
        tier0_vrf_lr.write(start_row,0, 'Edge Cluster Name', style_db_left)
        for ec in edge_list:
            if i['edge_cluster_id'] == ec[0]:
                tier0_vrf_lr.write(start_row,1,ec[1],style_alignleft)
        start_row += 1
        tier0_vrf_lr.write(start_row,0, 'Edge Cluster ID', style_db_left)
        tier0_vrf_lr.write(start_row,1,i['edge_cluster_id'],style_alignleft)
        start_row += 1
        tier0_vrf_lr.write(start_row,0, 'Logical Router Type', style_db_left)
        tier0_vrf_lr.write(start_row,1,i['router_type'],style_alignleft)
        start_row += 1
        tier0_vrf_lr.write(start_row,0, 'High Availability Mode', style_db_left)
        tier0_vrf_lr.write(start_row,1,i['high_availability_mode'],style_alignleft)
        start_row += 1
        tier0_vrf_lr.write(start_row,0, 'Enable Standby Relocation', style_db_left)
        for n in i['allocation_profile']:
            tier0_vrf_lr.write(start_row,1,i['allocation_profile'][n],style_alignleft)
        start_row += 1
        tier0_vrf_lr.write(start_row,0, 'Failover Mode', style_db_left)
        tier0_vrf_lr.write(start_row,1,i['failover_mode'],style_alignleft)
                                      
        start_row += 2
    
    start_row = 0
    for i in tier1slist:
        tier1_lr.write(start_row,0, 'Logical Router Name', style_db_left)
        tier1_lr.write(start_row,1,i['display_name'],style_alignleft)
        start_row += 1

        tier1_lr.write(start_row,0, 'Logical Router ID', style_db_left)
        tier1_lr.write(start_row,1,i['id'],style_alignleft)
        start_row += 1

        tier1_lr.write(start_row,0, 'Edge Cluster Name', style_db_left)
        try:
            for ec in edge_list:
                if i['edge_cluster_id'] == ec[0]:
                    tier1_lr.write(start_row,1,ec[1],style_alignleft)
        except:
            tier1_lr.write(start_row,1,'No Edge Cluster Assignment',style_alignleft)
        start_row += 1

        tier1_lr.write(start_row,0, 'Edge Cluster ID', style_db_left)
        try:
            tier1_lr.write(start_row,1,i['edge_cluster_id'],style_alignleft)
        except:
            tier1_lr.write(start_row,1,'No Edge Cluster Assignment',style_alignleft)
        start_row += 1

        tier1_lr.write(start_row,0, 'Logical Router Type', style_db_left)
        tier1_lr.write(start_row,1,i['router_type'],style_alignleft)
        start_row += 1

        tier1_lr.write(start_row,0, 'High Availability Mode', style_db_left)
        tier1_lr.write(start_row,1,i['high_availability_mode'],style_alignleft)
        start_row += 1

        tier1_lr.write(start_row,0, 'Enable Standby Relocation', style_db_left)
        tier1_lr.write(start_row,1,i['allocation_profile']['enable_standby_relocation'],style_alignleft)
        start_row += 1

        tier1_lr.write(start_row,0, 'Failover Mode', style_db_left)
        tier1_lr.write(start_row,1,i['failover_mode'],style_alignleft)
                                      
        start_row += 2

    lr_wkbk.save('Logical Router Summary.xls')
    
if __name__ == "__main__":
    main()
