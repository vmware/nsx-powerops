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

from vmware.vapi.bindings.stub import StubConfiguration
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

# Output directory for Excel Workbook
os.chdir(dest)

# Setup excel workbook and worksheets 
ls_wkbk = Workbook()  
summary = ls_wkbk.add_sheet('NSX-T Summary', cell_overwrite_ok=True)

#Set Excel Styling
style_db_left = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                'font: colour white, bold True; align: horiz left, vert centre')
style_db_left1 = xlwt.easyxf('pattern: pattern solid, fore_colour pale_blue;'
                                'font: colour white, bold True; align: horiz left, vert centre')
style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left, wrap True')
style_green = xlwt.easyxf('font: colour green, bold True; align: horiz left, wrap True')
style_red = xlwt.easyxf('font: colour red, bold True; align: horiz left, wrap True')

def main():
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("NSX-T Managers.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating NSX-T Manager output....')
    print('')
    
    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0])
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)

    ########### SECTION FOR REPORTING ON NSX-T MANAGER CLUSTER ###########

    nsxclstr_url = '/api/v1/cluster/status'
    nsxclstr_json = session.get('https://' + auth_list[0] + str(nsxclstr_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    
    columnA = summary.col(0)
    columnA.width = 256 * 35
    columnB = summary.col(1)
    columnB.width = 256 * 65
    
    summary.write(0, 0, 'NSX-T Cluster ID', style_db_left)
    summary.write(1, 0, 'NSX-T Cluster Status', style_db_left)
    summary.write(2, 0, 'NSX-T Control Cluster Status', style_db_left)
    summary.write(3, 0, 'Overall NSX-T Cluster Status', style_db_left)
    summary.write(4, 0, 'Number of online nodes', style_db_left)
    summary.write(5, 0, 'Number of offline nodes', style_db_left)
    summary.write(0, 1, nsxclstr_json['cluster_id'], style_alignleft)
    
    # Management Cluster Status
    if nsxclstr_json['mgmt_cluster_status']['status'] == 'STABLE':
        summary.write(1, 1, nsxclstr_json['mgmt_cluster_status']['status'], style_green)
    else:
        summary.write(1, 1, nsxclstr_json['mgmt_cluster_status']['status'], style_red)
    
    # Control Cluster Status
    if nsxclstr_json['control_cluster_status']['status'] == 'STABLE':
        summary.write(2, 1, nsxclstr_json['control_cluster_status']['status'], style_green)
    else:
        summary.write(2, 1, nsxclstr_json['control_cluster_status']['status'], style_red)
    
    # Overalll Status
    if nsxclstr_json['detailed_cluster_status']['overall_status'] == 'STABLE':
        summary.write(3, 1, nsxclstr_json['detailed_cluster_status']['overall_status'], style_green)
    else:
        summary.write(3, 1, nsxclstr_json['detailed_cluster_status']['overall_status'], style_red)

    #Check to see if 'online nodes' is part of json output
    try:
        online_nodes = nsxclstr_json['mgmt_cluster_status']['online_nodes']
        no_online_nodes = len(online_nodes)
        summary.write(4, 1, no_online_nodes, style_green)
        online_node_list = []
        for i in range(0, no_online_nodes):
            online_node_list.append(online_nodes[i]['uuid'])
        #print(online_node_list)
    except:
        summary.write(4, 1, '0', style_red)
        no_online_nodes = 0

    #Check to see if 'offline nodes' is part of json output
    try:
        offline_nodes = nsxclstr_json['mgmt_cluster_status']['offline_nodes']
        no_offline_nodes = len(offline_nodes)
        summary.write(5, 1, no_offline_nodes, style_red)
        offline_node_list = []
        for i in range(0, no_offline_nodes):
            offline_node_list.append(offline_nodes[i]['uuid'])
        #print(offline_node_list)
    except:
        summary.write(5, 1, '0', style_green)  
        no_offline_nodes = 0

    nsx_managers = []
    nsxmgr_url = '/api/v1/cluster/' 
    nsxmgr_json = session.get('https://' + auth_list[0] + str(nsxmgr_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    nsxmgr_nodes = len(nsxmgr_json["nodes"])
    base = nsxmgr_json["nodes"]

    for i in range(0,len(base)):
        nsx_managers.append(base[i]['node_uuid'])
    
    total_manager_nodes = no_online_nodes + no_offline_nodes

    start_row_a = 7
    start_row_b = 8
    start_row_c = 9
    start_row_d = 10
    start_row_e = 11
    start_row_f = 12

    for n in range(total_manager_nodes):
        summary.write(start_row_a, 0, 'NSX-T Manager Appliance FQDN', style_db_left)
        summary.write(start_row_b, 0, 'NSX-T Manager Appliance Hostname', style_db_left)
        summary.write(start_row_c, 0, 'NSX-T Manager Appliance UUID', style_db_left)
        summary.write(start_row_d, 0, 'NSX-T Manager Appliance Node Version', style_db_left)
        summary.write(start_row_e, 0, 'NSX-T Manager Appliance Product Version', style_db_left)
        summary.write(start_row_f, 0, 'NSX-T Manager Appliance Status', style_db_left)
        
        uuid = (nsx_managers[n])
        mgr_node_url = '/api/v1/cluster/' + str(uuid) + '/node'
        mgr_node_json = session.get('https://' + auth_list[0] + str(mgr_node_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
        
        try:
            summary.write(start_row_a, 1, mgr_node_json['fully_qualified_domain_name'], style_alignleft)
        except:
            summary.write(start_row_a, 1, 'NO FQDN CONFIGURED', style_alignleft)
        try:
            summary.write(start_row_b, 1, mgr_node_json['hostname'], style_alignleft)
        except:
            summary.write(start_row_b, 1, 'NO HOSTNAME', style_alignleft)
        try:
            summary.write(start_row_c, 1, mgr_node_json['node_uuid'], style_alignleft)
        except:
            summary.write(start_row_c, 1, 'NO NODE UUID', style_alignleft)
        try:
            summary.write(start_row_d, 1, mgr_node_json['node_version'], style_alignleft)
        except:
            summary.write(start_row_d, 1, 'NO NODE VERSION', style_alignleft)
        try:
            summary.write(start_row_e, 1, mgr_node_json['product_version'], style_alignleft)
            summary.write(start_row_f, 1, 'ONLINE',style_green)
        except:
            summary.write(start_row_e, 1, 'NO PRODUCT VERSION', style_alignleft)
            summary.write(start_row_f, 1, 'OFFLINE',style_red)

        start_row_a += 7
        start_row_b += 7
        start_row_c += 7
        start_row_d += 7
        start_row_e += 7
        start_row_f += 7
    
    # NSX Manager Grouping Details
    groups = nsxclstr_json['detailed_cluster_status']['groups']
    
    group_start_row1 = start_row_f - 4
    group_start_row2 = group_start_row1 + 1
    group_start_row3 = group_start_row2 + 1

    for n in range(len(groups)):
        summary.write(group_start_row1, 0, 'Group ID', style_db_left)
        summary.write(group_start_row2, 0, 'Group Type', style_db_left)
        summary.write(group_start_row3, 0, 'Group Status', style_db_left)
        
        summary.write(group_start_row1, 1, groups[n]['group_id'], style_alignleft)
        summary.write(group_start_row2, 1, groups[n]['group_type'], style_alignleft)
        if groups[n]['group_status'] == 'STABLE':
            summary.write(group_start_row3, 1, groups[n]['group_status'], style_green)
        else:
            summary.write(group_start_row3, 1, groups[n]['group_status'], style_red)

        mem_row_a = group_start_row3 + 1
        mem_row_b = mem_row_a + 1
        mem_row_c = mem_row_b + 1
        mem_row_d = mem_row_c + 1

        group_members = groups[n]['members']
        for m in range(len(group_members)):
            summary.write(mem_row_a, 0, 'Member FQDN', style_db_left1)
            summary.write(mem_row_b, 0, 'Member IP address', style_db_left1)
            summary.write(mem_row_c, 0, 'Member UUID', style_db_left1)
            summary.write(mem_row_d, 0, 'Member Status', style_db_left1)
            summary.write(mem_row_a, 1, group_members[m]['member_fqdn'])
            summary.write(mem_row_b, 1, group_members[m]['member_ip'])
            summary.write(mem_row_c, 1, group_members[m]['member_uuid'])

            if group_members[m]['member_status'] == 'UP':
                summary.write(mem_row_d, 1, group_members[m]['member_status'],style_green)
            else:
                summary.write(mem_row_d, 1, group_members[m]['member_status'],style_red)

            mem_row_a +=4
            mem_row_b +=4
            mem_row_c +=4
            mem_row_d +=4

        group_start_row1 = mem_row_d - 2
        group_start_row2 = group_start_row1 + 1
        group_start_row3 = group_start_row2 + 1

    ########### SECTION FOR REPORTING ON INDIVIDUAL MANAGER APPLIANCES ###########

    i = 1
    y = 0

    while i <= nsxmgr_nodes:
        sheet = ls_wkbk.add_sheet('NSX Manager Appliance ' + str(i), cell_overwrite_ok=True)
        columnA = sheet.col(0)
        columnA.width = 256 * 30
        columnB = sheet.col(1)
        columnB.width = 256 * 80

        sheet.write(0, 0, 'FQDN', style_db_left)
        sheet.write(1, 0, 'Node ID', style_db_left)
        sheet.write(0, 1, base[y]['fqdn'])
        sheet.write(1, 1, base[y]['node_uuid'])

        entities = len(base[y]['entities'])
        
        row3 = 3
        row4 = 4
        row5 = 5
        
        for n in range(entities):
            sheet.write(row3, 0, 'Entity Type', style_db_left)
            sheet.write(row4, 0, 'IP Address', style_db_left)
            sheet.write(row5, 0, 'Port', style_db_left)

            sheet.write(row3, 1, base[y]['entities'][n]['entity_type'], style_alignleft)
            sheet.write(row4, 1, base[y]['entities'][n]['ip_address'], style_alignleft)
            sheet.write(row5, 1, base[y]['entities'][n]['port'], style_alignleft)

            row3 += 4
            row4 += 4
            row5 += 4

        next_row = row4 - 1
        next_row2 = next_row + 1
        next_row3 = next_row2 + 1
               
        certificates = len(base[y]['certificates'])
        for n in range(certificates):
            sheet.write(next_row, 0, 'Certificate Type', style_db_left)
            sheet.write(next_row2, 0, 'Thumbprint', style_db_left)
            sheet.write(next_row3, 0, 'Certificate', style_db_left)

            sheet.write(next_row, 1, base[y]['certificates'][n]['entity_type'], style_alignleft)
            sheet.write(next_row2, 1, base[y]['certificates'][n]['certificate_sha256_thumbprint'], style_alignleft)
            sheet.write(next_row3, 1, base[y]['certificates'][n]['certificate'], style_alignleft)
            
            next_row += 4
            next_row2 += 4
            next_row3 += 4
        
        y += 1
        i += 1
    
    ls_wkbk.save('NSX-T Managers.xls')

if __name__ == "__main__":
    main()
