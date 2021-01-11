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
from com.vmware.nsx_policy.infra.domains.security_policies_client import Rules
from vmware.vapi.security.user_password import \
        create_user_password_security_context

# Output directory for Excel Workbook
os.chdir(dest)

# Setup excel workbook and worksheets 
groups_wkbk = Workbook()  
ethernet = groups_wkbk.add_sheet('Ethernet', cell_overwrite_ok=True)
emergency = groups_wkbk.add_sheet('Emergency', cell_overwrite_ok=True)
infrastructure = groups_wkbk.add_sheet('Infrastructure', cell_overwrite_ok=True)
environment = groups_wkbk.add_sheet('Environment', cell_overwrite_ok=True)
application = groups_wkbk.add_sheet('Application', cell_overwrite_ok=True)

# #Set Excel Styling
style_db_center = xlwt.easyxf('pattern: pattern solid, fore_colour blue_grey;'
                                'font: colour white, bold True; align: horiz center')
style_alignleft = xlwt.easyxf('font: colour black, bold False; align: horiz left, wrap True')
style_sec_pol = xlwt.easyxf('font: colour black, bold True; align: horiz left, wrap True')
style_green = xlwt.easyxf('font: colour green, bold True; align: horiz left, wrap True')
style_red = xlwt.easyxf('font: colour red, bold True; align: horiz left, wrap True')

#Setup Ethernet Column widths
EthA = ethernet.col(0)
EthA.width = 256 * 30
EthB = ethernet.col(1)
EthB.width = 256 * 45
EthC = ethernet.col(2)
EthC.width = 256 * 45
EthD = ethernet.col(3)
EthD.width = 256 * 30
EthE = ethernet.col(4)
EthE.width = 256 * 30
EthF = ethernet.col(5)
EthF.width = 256 * 30
EthG = ethernet.col(6)
EthG.width = 256 * 20
EthH = ethernet.col(7)
EthH.width = 256 * 15
EthI = ethernet.col(8)
EthI.width = 256 * 15
EthJ = ethernet.col(9)
EthJ.width = 256 * 15
EthK = ethernet.col(10)
EthK.width = 256 * 15
EthL = ethernet.col(11)
EthL.width = 256 * 15

#Setup Emergency Column widths
EmA = emergency.col(0)
EmA.width = 256 * 30
EmB = emergency.col(1)
EmB.width = 256 * 45
EmC = emergency.col(2)
EmC.width = 256 * 45
EmD = emergency.col(3)
EmD.width = 256 * 30
EmE = emergency.col(4)
EmE.width = 256 * 30
EmF = emergency.col(5)
EmF.width = 256 * 30
EmG = emergency.col(6)
EmG.width = 256 * 20
EmH = emergency.col(7)
EmH.width = 256 * 15
EmI = emergency.col(8)
EmI.width = 256 * 15
EmJ = emergency.col(9)
EmJ.width = 256 * 15
EmK = emergency.col(10)
EmK.width = 256 * 15
EmL = emergency.col(11)
EmL.width = 256 * 15

#Setup Infrastructure Column widths
InfA = infrastructure.col(0)
InfA.width = 256 * 30
InfB = infrastructure.col(1)
InfB.width = 256 * 45
InfC = infrastructure.col(2)
InfC.width = 256 * 45
InfD = infrastructure.col(3)
InfD.width = 256 * 30
InfE = infrastructure.col(4)
InfE.width = 256 * 30
InfF = infrastructure.col(5)
InfF.width = 256 * 30
InfG = infrastructure.col(6)
InfG.width = 256 * 20
InfH = infrastructure.col(7)
InfH.width = 256 * 15
InfI = infrastructure.col(8)
InfI.width = 256 * 15
InfJ = infrastructure.col(9)
InfJ.width = 256 * 15
InfK = infrastructure.col(10)
InfK.width = 256 * 15
InfL = infrastructure.col(11)
InfL.width = 256 * 15

#Setup Environment Column widths
EnvA = environment.col(0)
EnvA.width = 256 * 30
EnvB = environment.col(1)
EnvB.width = 256 * 45
EnvC = environment.col(2)
EnvC.width = 256 * 45
EnvD = environment.col(3)
EnvD.width = 256 * 30
EnvE = environment.col(4)
EnvE.width = 256 * 30
EnvF = environment.col(5)
EnvF.width = 256 * 30
EnvG = environment.col(6)
EnvG.width = 256 * 20
EnvH = environment.col(7)
EnvH.width = 256 * 15
EnvI = environment.col(8)
EnvI.width = 256 * 15
EnvJ = environment.col(9)
EnvJ.width = 256 * 15
EnvK = environment.col(10)
EnvK.width = 256 * 15
EnvL = environment.col(11)
EnvL.width = 256 * 15

#Setup Application Column widths
AppA = application.col(0)
AppA.width = 256 * 30
AppB = application.col(1)
AppB.width = 256 * 45
AppC = application.col(2)
AppC.width = 256 * 45
AppD = application.col(3)
AppD.width = 256 * 30
AppE = application.col(4)
AppE.width = 256 * 30
AppF = application.col(5)
AppF.width = 256 * 30
AppG = application.col(6)
AppG.width = 256 * 20
AppH = application.col(7)
AppH.width = 256 * 15
AppI = application.col(8)
AppI.width = 256 * 15
AppJ = application.col(9)
AppJ.width = 256 * 15
AppK = application.col(10)
AppK.width = 256 * 15
AppL = application.col(11)
AppL.width = 256 * 15

#Ethernet Column Headings
ethernet.write(0, 0, 'SECURITY POLICY', style_db_center)
ethernet.write(0, 1, 'RULE NAME', style_db_center)
ethernet.write(0, 2, 'SOURCE', style_db_center)
ethernet.write(0, 3, 'DESTINATION', style_db_center)
ethernet.write(0, 4, 'SERVICES', style_db_center)
ethernet.write(0, 5, 'PROFILES', style_db_center)
ethernet.write(0, 6, 'APPLIED TO', style_db_center)
ethernet.write(0, 7, 'ACTION', style_db_center)
ethernet.write(0, 8, 'DIRECTION', style_db_center)
ethernet.write(0, 9, 'DISABLED', style_db_center)
ethernet.write(0, 10, 'IP PROTOCOL', style_db_center)
ethernet.write(0, 11, 'LOGGED', style_db_center)

#Emergency Column Headings
emergency.write(0, 0, 'SECURITY POLICY', style_db_center)
emergency.write(0, 1, 'RULE NAME', style_db_center)
emergency.write(0, 2, 'SOURCE', style_db_center)
emergency.write(0, 3, 'DESTINATION', style_db_center)
emergency.write(0, 4, 'SERVICES', style_db_center)
emergency.write(0, 5, 'PROFILES', style_db_center)
emergency.write(0, 6, 'APPLIED TO', style_db_center)
emergency.write(0, 7, 'ACTION', style_db_center)
emergency.write(0, 8, 'DIRECTION', style_db_center)
emergency.write(0, 9, 'DISABLED', style_db_center)
emergency.write(0, 10, 'IP PROTOCOL', style_db_center)
emergency.write(0, 11, 'LOGGED', style_db_center)

#Infrastructure Column Headings
infrastructure.write(0, 0, 'SECURITY POLICY', style_db_center)
infrastructure.write(0, 1, 'RULE NAME', style_db_center)
infrastructure.write(0, 2, 'SOURCE', style_db_center)
infrastructure.write(0, 3, 'DESTINATION', style_db_center)
infrastructure.write(0, 4, 'SERVICES', style_db_center)
infrastructure.write(0, 5, 'PROFILES', style_db_center)
infrastructure.write(0, 6, 'APPLIED TO', style_db_center)
infrastructure.write(0, 7, 'ACTION', style_db_center)
infrastructure.write(0, 8, 'DIRECTION', style_db_center)
infrastructure.write(0, 9, 'DISABLED', style_db_center)
infrastructure.write(0, 10, 'IP PROTOCOL', style_db_center)
infrastructure.write(0, 11, 'LOGGED', style_db_center)

#Environment Column Headings
environment.write(0, 0, 'SECURITY POLICY', style_db_center)
environment.write(0, 1, 'RULE NAME', style_db_center)
environment.write(0, 2, 'SOURCE', style_db_center)
environment.write(0, 3, 'DESTINATION', style_db_center)
environment.write(0, 4, 'SERVICES', style_db_center)
environment.write(0, 5, 'PROFILES', style_db_center)
environment.write(0, 6, 'APPLIED TO', style_db_center)
environment.write(0, 7, 'ACTION', style_db_center)
environment.write(0, 8, 'DIRECTION', style_db_center)
environment.write(0, 9, 'DISABLED', style_db_center)
environment.write(0, 10, 'IP PROTOCOL', style_db_center)
environment.write(0, 11, 'LOGGED', style_db_center)

#Application Column Headings
application.write(0, 0, 'SECURITY POLICY', style_db_center)
application.write(0, 1, 'RULE NAME', style_db_center)
application.write(0, 2, 'SOURCE', style_db_center)
application.write(0, 3, 'DESTINATION', style_db_center)
application.write(0, 4, 'SERVICES', style_db_center)
application.write(0, 5, 'PROFILES', style_db_center)
application.write(0, 6, 'APPLIED TO', style_db_center)
application.write(0, 7, 'ACTION', style_db_center)
application.write(0, 8, 'DIRECTION', style_db_center)
application.write(0, 9, 'DISABLED', style_db_center)
application.write(0, 10, 'IP PROTOCOL', style_db_center)
application.write(0, 11, 'LOGGED', style_db_center)

def main():
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    fname = pathlib.Path("Distributed Firewall.xls")
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating NSX-T Distributed Firewall output....')
    print('')

    session = requests.session()
    session.verify = False
    connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + auth_list[0])
    stub_config = StubConfigurationFactory.new_std_configuration(connector)
    security_context = create_user_password_security_context(auth_list[1], auth_list[2])
    connector.set_security_context(security_context)

    policies_url = '/policy/api/v1/infra/domains/default/security-policies'
    policies_json = session.get('https://' + auth_list[0] + str(policies_url), auth=(auth_list[1], auth_list[2]), verify=session.verify).json()
    results = len(policies_json["results"])

    security_policy_list = [] 
    for i in range(0,results):
            security_policy_list.append((policies_json["results"][i]["category"], policies_json["results"][i]["id"]))

    all_policies = len(security_policy_list)

    ##########################################
    ####  ETHERNET POLICIES & RULES       ####
    ##########################################

    eth_policy_list = []
    for i in range(all_policies):
        if security_policy_list[i][0] == 'Ethernet':
            eth_policy_list.append((policies_json["results"][i]["category"], policies_json["results"][i]["id"], policies_json["results"][i]["display_name"], policies_json["results"][i]["scope"]))
    all_app_policies = len(eth_policy_list)

    start_row = 0
    for i in range(all_app_policies):
        start_row += 1
        ethernet.write(start_row, 0, 'Security Policy: ' +str(eth_policy_list[i][2]), style_sec_pol)

        applied_2_list = []
        for applied_2 in eth_policy_list[i][3]:
            applied_string = str(applied_2)
            split_string_applied = (applied_string.split("/"))
            split_string = str((split_string_applied[-1]))
            applied_2_out = (split_string.split("'")[0])
            applied_2_list.append(applied_2_out)
        
            joined = (', '.join(applied_2_list))
            joined_str = str(joined)
                
            if applied_2_list[0] == 'ANY':
                ethernet.write(start_row, 1, 'Applied To: DFW', style_red)
            else:
                ethernet.write(start_row, 1, 'Applied To: ' +joined_str, style_green)

        start_row += 1
        domain_id = 'default'
        rules_svc = Rules(stub_config)
        rules_list = rules_svc.list(domain_id, eth_policy_list[i][1])
        n = 1
        y = 0
        while n <= rules_list.result_count:
            ethernet.write(start_row, 0, eth_policy_list[i][2], style_sec_pol)
            ethernet.write(start_row, 1, rules_list.results[y].display_name)

            src_grp = str(rules_list.results[y].source_groups)
            src_grp_lst = (src_grp.split("/"))
            src_grp_str = str((src_grp_lst[-1]))
            src_output_grp = (src_grp_str.split("'")[0])
            if src_output_grp == '[':
                ethernet.write(start_row, 2, 'ANY')
            else:
                ethernet.write(start_row, 2, src_output_grp)
            
            dst_grp = str(rules_list.results[y].destination_groups)
            dst_grp_lst = (dst_grp.split("/"))
            dst_grp_str = str((dst_grp_lst[-1]))
            dst_output_grp = (dst_grp_str.split("'")[0])
            if dst_output_grp == '[':
                ethernet.write(start_row, 3, 'ANY')
            else:
                ethernet.write(start_row, 3, dst_output_grp)
            
            svc_grp = str(rules_list.results[y].services)
            svc_grp_lst = (svc_grp.split("/"))
            svc_grp_str = str((svc_grp_lst[-1]))
            svc_output_grp = (svc_grp_str.split("'")[0])
            if svc_output_grp == '[':
                ethernet.write(start_row, 4, 'ANY')
            else:
                ethernet.write(start_row, 4, svc_output_grp)

            ethernet.write(start_row, 5, rules_list.results[y].profiles)

            if rules_list.results[y].scope[0] == 'ANY':
                ethernet.write(start_row, 6, 'dFW')
            else:
                g = 0
                apl2_list = []
                for g in range(len(rules_list.results[y].scope)):
                    apl2_grp = str(rules_list.results[y].scope[g])
                    apl2_grp_lst = (apl2_grp.split("/"))
                    apl2_grp_str = str((apl2_grp_lst[-1]))
                    apl2_output_grp = (apl2_grp_str.split("'")[0])
                    apl2_list.append(apl2_output_grp)
                    g += 1
                joined = (', '.join(apl2_list))
                joined_str = str(joined)
                ethernet.write(start_row, 6, joined_str, style_alignleft)

            if rules_list.results[y].action == 'DROP':
                ethernet.write(start_row, 7, rules_list.results[y].action, style_red)
            elif rules_list.results[y].action == 'REJECT':
                ethernet.write(start_row, 7, rules_list.results[y].action, style_red)
            else:
                ethernet.write(start_row, 7, rules_list.results[y].action, style_green)

            ethernet.write(start_row, 8, rules_list.results[y].direction)
            ethernet.write(start_row, 9, rules_list.results[y].disabled)
            ethernet.write(start_row, 10, rules_list.results[y].ip_protocol)
            ethernet.write(start_row, 11, rules_list.results[y].logged)
            start_row += 1
            n += 1
            y += 1
    
    ##########################################
    ####  EMERGENCY POLICIES & RULES      ####
    ##########################################

    em_policy_list = []
    for i in range(all_policies):
        if security_policy_list[i][0] == 'Emergency':
            em_policy_list.append((policies_json["results"][i]["category"], policies_json["results"][i]["id"], policies_json["results"][i]["display_name"], policies_json["results"][i]["scope"]))
    all_app_policies = len(em_policy_list)

    start_row = 0
    for i in range(all_app_policies):
        start_row += 1
        emergency.write(start_row, 0, 'Security Policy: ' +str(em_policy_list[i][2]), style_sec_pol)

        applied_2_list = []
        for applied_2 in em_policy_list[i][3]:
            applied_string = str(applied_2)
            split_string_applied = (applied_string.split("/"))
            split_string = str((split_string_applied[-1]))
            applied_2_out = (split_string.split("'")[0])
            applied_2_list.append(applied_2_out)
        
            joined = (', '.join(applied_2_list))
            joined_str = str(joined)
                
            if applied_2_list[0] == 'ANY':
                emergency.write(start_row, 1, 'Applied To: DFW', style_red)
            else:
                emergency.write(start_row, 1, 'Applied To: ' +joined_str, style_green)

        start_row += 1
        domain_id = 'default'
        rules_svc = Rules(stub_config)
        rules_list = rules_svc.list(domain_id, em_policy_list[i][1])
        n = 1
        y = 0
        while n <= rules_list.result_count:
            emergency.write(start_row, 0, em_policy_list[i][2], style_sec_pol)
            emergency.write(start_row, 1, rules_list.results[y].display_name)

            src_grp = str(rules_list.results[y].source_groups)
            src_grp_lst = (src_grp.split("/"))
            src_grp_str = str((src_grp_lst[-1]))
            src_output_grp = (src_grp_str.split("'")[0])
            if src_output_grp == '[':
                emergency.write(start_row, 2, 'ANY')
            else:
                emergency.write(start_row, 2, src_output_grp)
            
            dst_grp = str(rules_list.results[y].destination_groups)
            dst_grp_lst = (dst_grp.split("/"))
            dst_grp_str = str((dst_grp_lst[-1]))
            dst_output_grp = (dst_grp_str.split("'")[0])
            if dst_output_grp == '[':
                emergency.write(start_row, 3, 'ANY')
            else:
                emergency.write(start_row, 3, dst_output_grp)
            
            svc_grp = str(rules_list.results[y].services)
            svc_grp_lst = (svc_grp.split("/"))
            svc_grp_str = str((svc_grp_lst[-1]))
            svc_output_grp = (svc_grp_str.split("'")[0])
            if svc_output_grp == '[':
                emergency.write(start_row, 4, 'ANY')
            else:
                emergency.write(start_row, 4, svc_output_grp)

            emergency.write(start_row, 5, rules_list.results[y].profiles)

            if rules_list.results[y].scope[0] == 'ANY':
                emergency.write(start_row, 6, 'dFW')
            else:
                g = 0
                apl2_list = []
                for g in range(len(rules_list.results[y].scope)):
                    apl2_grp = str(rules_list.results[y].scope[g])
                    apl2_grp_lst = (apl2_grp.split("/"))
                    apl2_grp_str = str((apl2_grp_lst[-1]))
                    apl2_output_grp = (apl2_grp_str.split("'")[0])
                    apl2_list.append(apl2_output_grp)
                    g += 1
                joined = (', '.join(apl2_list))
                joined_str = str(joined)
                emergency.write(start_row, 6, joined_str, style_alignleft)

            if rules_list.results[y].action == 'DROP':
                emergency.write(start_row, 7, rules_list.results[y].action, style_red)
            elif rules_list.results[y].action == 'REJECT':
                emergency.write(start_row, 7, rules_list.results[y].action, style_red)
            else:
                emergency.write(start_row, 7, rules_list.results[y].action, style_green)

            emergency.write(start_row, 8, rules_list.results[y].direction)
            emergency.write(start_row, 9, rules_list.results[y].disabled)
            emergency.write(start_row, 10, rules_list.results[y].ip_protocol)
            emergency.write(start_row, 11, rules_list.results[y].logged)
            start_row += 1
            n += 1
            y += 1

    
    ##########################################
    ####  INFRASTRUCTURE POLICIES & RULES ####
    ##########################################
    
    inf_policy_list = []
    for i in range(all_policies):
        if security_policy_list[i][0] == 'Infrastructure':
            inf_policy_list.append((policies_json["results"][i]["category"], policies_json["results"][i]["id"], policies_json["results"][i]["display_name"], policies_json["results"][i]["scope"]))
    all_app_policies = len(inf_policy_list)

    start_row = 0
    for i in range(all_app_policies):
        start_row += 1
        infrastructure.write(start_row, 0, 'Security Policy: ' +str(inf_policy_list[i][2]), style_sec_pol)

        applied_2_list = []
        for applied_2 in inf_policy_list[i][3]:
            applied_string = str(applied_2)
            split_string_applied = (applied_string.split("/"))
            split_string = str((split_string_applied[-1]))
            applied_2_out = (split_string.split("'")[0])
            applied_2_list.append(applied_2_out)
        
            joined = (', '.join(applied_2_list))
            joined_str = str(joined)
                
            if applied_2_list[0] == 'ANY':
                infrastructure.write(start_row, 1, 'Applied To: DFW', style_red)
            else:
                infrastructure.write(start_row, 1, 'Applied To: ' +joined_str, style_green)

        start_row += 1
        domain_id = 'default'
        rules_svc = Rules(stub_config)
        rules_list = rules_svc.list(domain_id, inf_policy_list[i][1])
        n = 1
        y = 0
        while n <= rules_list.result_count:
            infrastructure.write(start_row, 0, inf_policy_list[i][2], style_sec_pol)
            infrastructure.write(start_row, 1, rules_list.results[y].display_name)

            src_grp = str(rules_list.results[y].source_groups)
            src_grp_lst = (src_grp.split("/"))
            src_grp_str = str((src_grp_lst[-1]))
            src_output_grp = (src_grp_str.split("'")[0])
            if src_output_grp == '[':
                infrastructure.write(start_row, 2, 'ANY')
            else:
                infrastructure.write(start_row, 2, src_output_grp)
            
            dst_grp = str(rules_list.results[y].destination_groups)
            dst_grp_lst = (dst_grp.split("/"))
            dst_grp_str = str((dst_grp_lst[-1]))
            dst_output_grp = (dst_grp_str.split("'")[0])
            if dst_output_grp == '[':
                infrastructure.write(start_row, 3, 'ANY')
            else:
                infrastructure.write(start_row, 3, dst_output_grp)
            
            svc_grp = str(rules_list.results[y].services)
            svc_grp_lst = (svc_grp.split("/"))
            svc_grp_str = str((svc_grp_lst[-1]))
            svc_output_grp = (svc_grp_str.split("'")[0])
            if svc_output_grp == '[':
                infrastructure.write(start_row, 4, 'ANY')
            else:
                infrastructure.write(start_row, 4, svc_output_grp)

            infrastructure.write(start_row, 5, rules_list.results[y].profiles)

            if rules_list.results[y].scope[0] == 'ANY':
                infrastructure.write(start_row, 6, 'dFW')
            else:
                g = 0
                apl2_list = []
                for g in range(len(rules_list.results[y].scope)):
                    apl2_grp = str(rules_list.results[y].scope[g])
                    apl2_grp_lst = (apl2_grp.split("/"))
                    apl2_grp_str = str((apl2_grp_lst[-1]))
                    apl2_output_grp = (apl2_grp_str.split("'")[0])
                    apl2_list.append(apl2_output_grp)
                    g += 1
                joined = (', '.join(apl2_list))
                joined_str = str(joined)
                infrastructure.write(start_row, 6, joined_str, style_alignleft)

            if rules_list.results[y].action == 'DROP':
                infrastructure.write(start_row, 7, rules_list.results[y].action, style_red)
            elif rules_list.results[y].action == 'REJECT':
                infrastructure.write(start_row, 7, rules_list.results[y].action, style_red)
            else:
                infrastructure.write(start_row, 7, rules_list.results[y].action, style_green)

            infrastructure.write(start_row, 8, rules_list.results[y].direction)
            infrastructure.write(start_row, 9, rules_list.results[y].disabled)
            infrastructure.write(start_row, 10, rules_list.results[y].ip_protocol)
            infrastructure.write(start_row, 11, rules_list.results[y].logged)
            start_row += 1
            n += 1
            y += 1

    ##########################################
    ####  ENVIRONMENT POLICIES & RULES    ####
    ##########################################
    
    env_policy_list = []
    for i in range(all_policies):
        if security_policy_list[i][0] == 'Environment':
            env_policy_list.append((policies_json["results"][i]["category"], policies_json["results"][i]["id"], policies_json["results"][i]["display_name"], policies_json["results"][i]["scope"]))
    all_app_policies = len(env_policy_list)

    start_row = 0
    for i in range(all_app_policies):
        start_row += 1
        environment.write(start_row, 0, 'Security Policy: ' +str(env_policy_list[i][2]), style_sec_pol)

        applied_2_list = []
        for applied_2 in env_policy_list[i][3]:
            applied_string = str(applied_2)
            split_string_applied = (applied_string.split("/"))
            split_string = str((split_string_applied[-1]))
            applied_2_out = (split_string.split("'")[0])
            applied_2_list.append(applied_2_out)
        
            joined = (', '.join(applied_2_list))
            joined_str = str(joined)
                
            if applied_2_list[0] == 'ANY':
                environment.write(start_row, 1, 'Applied To: DFW', style_red)
            else:
                environment.write(start_row, 1, 'Applied To: ' +joined_str, style_green)

        start_row += 1
        domain_id = 'default'
        rules_svc = Rules(stub_config)
        rules_list = rules_svc.list(domain_id, env_policy_list[i][1])
        n = 1
        y = 0
        while n <= rules_list.result_count:
            environment.write(start_row, 0, env_policy_list[i][2], style_sec_pol)
            environment.write(start_row, 1, rules_list.results[y].display_name)

            src_grp = str(rules_list.results[y].source_groups)
            src_grp_lst = (src_grp.split("/"))
            src_grp_str = str((src_grp_lst[-1]))
            src_output_grp = (src_grp_str.split("'")[0])
            if src_output_grp == '[':
                environment.write(start_row, 2, 'ANY')
            else:
                environment.write(start_row, 2, src_output_grp)
            
            dst_grp = str(rules_list.results[y].destination_groups)
            dst_grp_lst = (dst_grp.split("/"))
            dst_grp_str = str((dst_grp_lst[-1]))
            dst_output_grp = (dst_grp_str.split("'")[0])
            if dst_output_grp == '[':
                environment.write(start_row, 3, 'ANY')
            else:
                environment.write(start_row, 3, dst_output_grp)
            
            svc_grp = str(rules_list.results[y].services)
            svc_grp_lst = (svc_grp.split("/"))
            svc_grp_str = str((svc_grp_lst[-1]))
            svc_output_grp = (svc_grp_str.split("'")[0])
            if svc_output_grp == '[':
                environment.write(start_row, 4, 'ANY')
            else:
                environment.write(start_row, 4, svc_output_grp)

            environment.write(start_row, 5, rules_list.results[y].profiles)

            if rules_list.results[y].scope[0] == 'ANY':
                environment.write(start_row, 6, 'dFW')
            else:
                g = 0
                apl2_list = []
                for g in range(len(rules_list.results[y].scope)):
                    apl2_grp = str(rules_list.results[y].scope[g])
                    apl2_grp_lst = (apl2_grp.split("/"))
                    apl2_grp_str = str((apl2_grp_lst[-1]))
                    apl2_output_grp = (apl2_grp_str.split("'")[0])
                    apl2_list.append(apl2_output_grp)
                    g += 1
                joined = (', '.join(apl2_list))
                joined_str = str(joined)
                environment.write(start_row, 6, joined_str, style_alignleft)

            if rules_list.results[y].action == 'DROP':
                environment.write(start_row, 7, rules_list.results[y].action, style_red)
            elif rules_list.results[y].action == 'REJECT':
                environment.write(start_row, 7, rules_list.results[y].action, style_red)
            else:
                environment.write(start_row, 7, rules_list.results[y].action, style_green)

            environment.write(start_row, 8, rules_list.results[y].direction)
            environment.write(start_row, 9, rules_list.results[y].disabled)
            environment.write(start_row, 10, rules_list.results[y].ip_protocol)
            environment.write(start_row, 11, rules_list.results[y].logged)
            start_row += 1
            n += 1
            y += 1


    ##########################################
    ####  APPLICATION POLICIES & RULES    ####
    ##########################################

    app_policy_list = []
    for i in range(all_policies):
        if security_policy_list[i][0] == 'Application':
            app_policy_list.append((policies_json["results"][i]["category"], policies_json["results"][i]["id"], policies_json["results"][i]["display_name"], policies_json["results"][i]["scope"]))
    all_app_policies = len(app_policy_list)

    start_row = 0
    for i in range(all_app_policies):
        start_row += 1
        application.write(start_row, 0, 'Security Policy: ' +str(app_policy_list[i][2]), style_sec_pol)

        applied_2_list = []
        for applied_2 in app_policy_list[i][3]:
            applied_string = str(applied_2)
            split_string_applied = (applied_string.split("/"))
            split_string = str((split_string_applied[-1]))
            applied_2_out = (split_string.split("'")[0])
            applied_2_list.append(applied_2_out)
       
            joined = (', '.join(applied_2_list))
            joined_str = str(joined)
                
            if applied_2_list[0] == 'ANY':
                application.write(start_row, 1, 'Applied To: DFW', style_red)
            else:
                application.write(start_row, 1, 'Applied To: ' +joined_str, style_green)

        start_row += 1
        domain_id = 'default'
        rules_svc = Rules(stub_config)
        rules_list = rules_svc.list(domain_id, app_policy_list[i][1])
        n = 1
        y = 0
        while n <= rules_list.result_count:
            application.write(start_row, 0, app_policy_list[i][2], style_sec_pol)
            application.write(start_row, 1, rules_list.results[y].display_name)

            src_grp = str(rules_list.results[y].source_groups)
            src_grp_lst = (src_grp.split("/"))
            src_grp_str = str((src_grp_lst[-1]))
            src_output_grp = (src_grp_str.split("'")[0])
            if src_output_grp == '[':
                application.write(start_row, 2, 'ANY')
            else:
                application.write(start_row, 2, src_output_grp)
            
            dst_grp = str(rules_list.results[y].destination_groups)
            dst_grp_lst = (dst_grp.split("/"))
            dst_grp_str = str((dst_grp_lst[-1]))
            dst_output_grp = (dst_grp_str.split("'")[0])
            if dst_output_grp == '[':
                application.write(start_row, 3, 'ANY')
            else:
                application.write(start_row, 3, dst_output_grp)
            
            svc_grp = str(rules_list.results[y].services)
            svc_grp_lst = (svc_grp.split("/"))
            svc_grp_str = str((svc_grp_lst[-1]))
            svc_output_grp = (svc_grp_str.split("'")[0])
            if svc_output_grp == '[':
                application.write(start_row, 4, 'ANY')
            else:
                application.write(start_row, 4, svc_output_grp)

            application.write(start_row, 5, rules_list.results[y].profiles)

            if rules_list.results[y].scope[0] == 'ANY':
                application.write(start_row, 6, 'dFW')
            else:
                g = 0
                apl2_list = []
                for g in range(len(rules_list.results[y].scope)):
                    apl2_grp = str(rules_list.results[y].scope[g])
                    apl2_grp_lst = (apl2_grp.split("/"))
                    apl2_grp_str = str((apl2_grp_lst[-1]))
                    apl2_output_grp = (apl2_grp_str.split("'")[0])
                    apl2_list.append(apl2_output_grp)
                    g += 1
                joined = (', '.join(apl2_list))
                joined_str = str(joined)
                application.write(start_row, 6, joined_str, style_alignleft)

            if rules_list.results[y].action == 'DROP':
                application.write(start_row, 7, rules_list.results[y].action, style_red)
            elif rules_list.results[y].action == 'REJECT':
                application.write(start_row, 7, rules_list.results[y].action, style_red)
            else:
                application.write(start_row, 7, rules_list.results[y].action, style_green)

            application.write(start_row, 8, rules_list.results[y].direction)
            application.write(start_row, 9, rules_list.results[y].disabled)
            application.write(start_row, 10, rules_list.results[y].ip_protocol)
            application.write(start_row, 11, rules_list.results[y].logged)
            start_row += 1
            n += 1
            y += 1
    
    groups_wkbk.save('Distributed Firewall.xls')

if __name__ == "__main__":
    main()
