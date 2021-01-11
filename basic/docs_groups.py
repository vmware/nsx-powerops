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
from com.vmware.nsx_policy.infra.domains_client import Groups
from com.vmware.nsx_policy.infra.domains.groups.members_client import IpAddresses  
from com.vmware.nsx_policy.infra.domains.groups.members_client import SegmentPorts 
from com.vmware.nsx_policy.infra.domains.groups.members_client import Segments  
from com.vmware.nsx_policy.infra.domains.groups.members_client import VirtualMachines  
from com.vmware.nsx_policy.model_client import PolicyGroupIPMembersListResult
from vmware.vapi.security.user_password import \
    create_user_password_security_context

# Output directory for Excel Workbook
os.chdir(dest)

# Setup excel workbook and worksheets 
groups_wkbk = Workbook()  
sheet1 = groups_wkbk.add_sheet('Groups', cell_overwrite_ok=True)

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
columnC.width = 256 * 30
columnD = sheet1.col(3)
columnD.width = 256 * 30
columnE = sheet1.col(4)
columnE.width = 256 * 30
columnF = sheet1.col(5)
columnF.width = 256 * 30
columnG = sheet1.col(5)
columnG.width = 256 * 30
columnH = sheet1.col(5)
columnH.width = 256 * 30
columnI = sheet1.col(8)
columnI.width = 256 * 50

#Excel Column Headings
sheet1.write(0, 0, 'GROUP NAME', style_db_center)
sheet1.write(0, 1, 'TAGS', style_db_center)
sheet1.write(0, 2, 'SCOPE', style_db_center)
sheet1.write(0, 3, 'CRITERIA TYPE', style_db_center)
sheet1.write(0, 4, 'CRITERIA', style_db_center)
sheet1.write(0, 5, 'IP ADDRESSES', style_db_center)
sheet1.write(0, 6, 'VIRTUAL MACHINES', style_db_center)
sheet1.write(0, 7, 'SEGMENTS', style_db_center)
sheet1.write(0, 8, 'SEGMENT PORTS', style_db_center)


def GetCriteria(SESSION, DictExpression):
    ListReturn = []
    TypeCriteriaList = []
    criteria = ""
    # Dictionary mapping API/REST ressource Type to Type of criteria
    Dict_MAP_Criteria ={
        'IPAddressExpression': 'IP Address',
        'Condition' : 'Membership Criteria',
        'MACAddressExpression': 'MAC Address',
        'ConjunctionOperator': 'conjunction_operator',
        'NestedExpression': 'Nested',
        'PathExpression': 'Members',
        'ExternalIDExpression': 'ExternalIDExpression',
        'IdentityGroupExpression': 'AD Group'
    }
    # Group with operator
    if DictExpression['resource_type'] == 'ConjunctionOperator': 
        criteria = criteria + DictExpression['conjunction_operator']+ "\n"
        TypeCriteriaList.append(DictExpression['conjunction_operator'])
    else:
        TypeCriteriaList.append(Dict_MAP_Criteria[DictExpression['resource_type']])
    # Missing Group with AD -  expression ExternalIDExpression and IdentityGroupExpression
    # Path Expression Group
    if DictExpression['resource_type'] == 'PathExpression':
        for path in DictExpression['paths']:
            Group = requests.get('https://' + auth_list[0] + "/policy/api/v1" + path, auth=(auth_list[1], auth_list[2]), verify=SESSION.verify).json()
            criteria = criteria + Group['resource_type'] + ': ' + Group['display_name'] + '\n'
    # Nested Group - recursive function
    if DictExpression['resource_type'] == 'NestedExpression':
        for expression in DictExpression['expressions']:
            criteria = criteria + GetCriteria(SESSION, expression)[0]
    # Mac address Group
    if DictExpression['resource_type'] == 'MACAddressExpression': criteria = criteria + 'MAC: ' + ','.join(DictExpression['mac_addresses'])
    # IP address Group
    if DictExpression['resource_type'] == 'IPAddressExpression': criteria = criteria + 'IP: ' + ','.join(DictExpression['ip_addresses'])
    # Conditionnal Group - Membership
    if DictExpression['resource_type'] == 'Condition':
        criteria = DictExpression['member_type'] + ' with ' + DictExpression['key'].lower() + ' ' + DictExpression['operator'].lower()
        ListTAG = DictExpression['value'].split('|')
        if ListTAG[1] == '': criteria = criteria + ' NoTag scope: ' + ListTAG[0] + '\n'
        elif ListTAG[0] == '': criteria = criteria + ' ' + ListTAG[1] + '\n'
        else: criteria = criteria + ' ' + ListTAG[1] + ' scope ' + ListTAG[0]

    ListReturn = [criteria, TypeCriteriaList]
    return ListReturn

def main():
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("NS Groups.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating NSX-T Groups output....')
    print('    Please be patient...')
    print('')

    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0])
    stub_config = StubConfigurationFactory.new_std_configuration(connector)
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)
    domain_id = 'default'
    # Connection for get Groups criteria - REST/API
    Groups_list_url = '/policy/api/v1/infra/domains/' + domain_id + '/groups'
    Groups_list_json = requests.get('https://' + auth_list[0] + str(Groups_list_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
        
    group_list = []
    group_svc = Groups(stub_config)
    group_list = group_svc.list(domain_id)
    x = len(group_list.results)
    start_row = 1
    for i in range(0,x):
        # Extract Group ID for each group
        grp_id = group_list.results[i].id
        sheet1.write(start_row, 0, group_list.results[i].display_name)
        # Extract Tags for each group if exist
        # Bypass system groups for LB
        if 'NLB.PoolLB' in grp_id or 'NLB.VIP' in grp_id: 
            pass
        elif group_list.results[i].tags:
            result = group_list.results[i].tags
            x = len(result)
            tag_list = []
            scope_list = []
            for i in range(0,x):
                tag_list.append(result[i].tag)
                scope_list.append(result[i].scope)
            sheet1.write(start_row, 1, ', '.join(tag_list), style_alignleft)    # Tags
            sheet1.write(start_row, 2, ', '.join(scope_list), style_alignleft)  # Scope
        
        # Criteria
        if Groups_list_json['result_count'] != 0:
            for gp in Groups_list_json['results']:
                if gp['id'] == grp_id:
                    for nbcriteria in gp['expression']:
                        criteria = GetCriteria(session, nbcriteria)
                            
                    sheet1.write(start_row, 3, '\n'.join(criteria[1]), style_alignleft) # Type of Criteria
                    sheet1.write(start_row, 4, criteria[0], style_alignleft) # Criteria Membership

        # Bypass system groups for LB
        if 'NLB.PoolLB' in grp_id or 'NLB.VIP' in grp_id:  
            pass
        else:     
            # Create IP Address List for each group
            iplist = []
            ipsvc = IpAddresses(stub_config)
            iplist = ipsvc.list(domain_id, grp_id)
            iprc = len(iplist.results)
            iplist1 = []
            for i in range(0,iprc):
                iplist1.append(iplist.results[i])
            sheet1.write(start_row, 5, ', '.join(iplist1), style_alignleft) # IP
            
            # Create Virtual Machine List for each group
            vmlist = []
            vmsvc = VirtualMachines(stub_config)
            vmlist = vmsvc.list(domain_id, grp_id)
            vmrc = vmlist.result_count
            vmlist1 = []
            for i in range(0,vmrc):
                vmlist1.append(vmlist.results[i].display_name)
            sheet1.write(start_row, 6, ', '.join(vmlist1), style_alignleft) # VMs

            # Create Segment List for each group
            sgmntlist = []
            sgmntsvc = Segments(stub_config)
            sgmntlist = sgmntsvc.list(domain_id, grp_id)
            sgmntrc = sgmntlist.result_count
            sgmntlist1 = []
            for i in range(0,sgmntrc):
                sgmntlist1.append(sgmntlist.results[i].display_name)
            sheet1.write(start_row, 7, ', '.join(sgmntlist1), style_alignleft) # Segments

            # Create Segment Port/vNIC List for each group
            sgmntprtlist = []
            sgmntprtsvc = SegmentPorts(stub_config)
            sgmntprtlist = sgmntprtsvc.list(domain_id, grp_id)
            sgmntprtrc = sgmntprtlist.result_count
            sgmntprtlist1 = []
            for i in range(0,sgmntprtrc):
                sgmntprtlist1.append(sgmntprtlist.results[i].display_name)
            sheet1.write(start_row, 8, ', '.join(sgmntprtlist1), style_alignleft) # Segments Ports

        start_row +=1
    
    groups_wkbk.save('NS Groups.xls')

if __name__ == "__main__":
    main()
