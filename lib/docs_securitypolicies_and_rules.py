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
import pathlib, lib.menu,  pprint
from lib.excel import FillSheet, Workbook, FillSheetCSV, FillSheetJSON, FillSheetYAML
from lib.system import style, GetAPI, ConnectNSX, os, GetOutputFormat
from vmware.vapi.stdlib.client.factories import StubConfigurationFactory
from com.vmware.nsx_policy.infra.domains.security_policies_client import Rules


def GetListNameFromPath(LIST):
    # Get a list with path as element, and return a list with only the last element of the path
    returnlist = []
    for element in LIST:
        if 'ANY' in LIST:
            returnlist = ['ANY']
        else:
            lenList = len(element.split('/'))
            returnlist.append(element.split('/')[lenList - 1])

    return returnlist

def PrintRulesbyCategory(RULES,PolicyName, PolicyID,category, scopelist, XLSlines, NSX_Config):
    Dict_DFW = {}
    domain_id = 'default'
    ruleslist = RULES.list(domain_id, PolicyID)
    nb = len(ruleslist.results)
    print(" --> Getting rules of " + style.ORANGE + PolicyName + style.NORMAL + " from category: " + style.ORANGE + category + style.NORMAL)
    if ruleslist.result_count > 0:
        while True:
            for rule in ruleslist.results:
                srcgrouplist =GetListNameFromPath(rule.source_groups)
                dstgrouplist = GetListNameFromPath(rule.destination_groups)
                servicelist = GetListNameFromPath(rule.services)
                profilelist = GetListNameFromPath(rule.profiles)
                rulescopelist = GetListNameFromPath(rule.scope)

                Dict_DFW['policy_name'] = PolicyName
                Dict_DFW['scope'] = scopelist
                Dict_DFW['category'] = category
                Dict_DFW['rule_name'] = rule.display_name
                Dict_DFW['rule_id'] = rule.id
                Dict_DFW['source'] = srcgrouplist
                Dict_DFW['destination'] = dstgrouplist
                Dict_DFW['services'] = servicelist
                Dict_DFW['profile'] = profilelist
                Dict_DFW['rule_scope'] = rulescopelist
                Dict_DFW['direction'] = rule.direction
                Dict_DFW['state'] = rule.disabled
                Dict_DFW['ip_protocol'] = rule.ip_protocol
                Dict_DFW['logged'] = rule.logged
                NSX_Config['DFW'].append(Dict_DFW)
                XLSlines.append([PolicyName,", ".join(scopelist),category,rule.display_name, rule.unique_id, "\n".join(srcgrouplist), "\n".join(dstgrouplist), "\n".join(servicelist), "\n".join(profilelist), "\n".join(rulescopelist), str(rule.direction), str(rule.disabled), str(rule.ip_protocol), str(rule.logged)])

            if ruleslist.cursor is None:
                break
            else:
                print(" --> more than " + str(nb) + " results for " + style.RED + "Rules" + style.NORMAL + " - please wait")
                ruleslist = RULES.list(domain_id, PolicyID, cursor =ruleslist.cursor)
                nb = len(ruleslist.results) + nb


def SheetSecDFW(auth_list,WORKBOOK,TN_WS, NSX_Config = {}):
    NSX_Config['DFW'] = []
    # connection to NSX
    SessionNSX = ConnectNSX(auth_list)
    policies_json = GetAPI(SessionNSX[0],'/policy/api/v1/infra/domains/default/security-policies', auth_list)
    stub_config = StubConfigurationFactory.new_std_configuration(SessionNSX[1])
    rules_svc = Rules(stub_config)
    # Header of Excel and initialization of lines
    XLS_Lines = []
    TN_HEADER_ROW = ('Security Policy', 'Security Policy Applied to', 'Category','Rule Name', 'Rule ID','Source', 'Destination', 'Services', 'Profiles', 'Rule Applied to', 'Action', 'Direction', 'Disabled', 'IP Protocol', 'Logged')
    if isinstance(policies_json, dict) and 'results' in policies_json: 
        for policy in policies_json["results"]:
            # Check Applied to for policies
            scopelist= GetListNameFromPath(policy['scope'])
            ####  Get RULES       ####
            PrintRulesbyCategory(rules_svc, policy['display_name'],policy['id'],policy['category'], scopelist, XLS_Lines, NSX_Config)
    else:
        XLS_Lines.append(['No results', "", "", "", "", "", "", "", "", "", "", "", "", ""])
     
    if GetOutputFormat() == 'CSV':
        CSV = WORKBOOK
        FillSheetCSV(CSV,TN_HEADER_ROW,XLS_Lines)
    elif GetOutputFormat() == 'JSON':
        JSON = WORKBOOK
        FillSheetJSON(JSON, NSX_Config)
    elif GetOutputFormat() == 'YAML':
        YAML = WORKBOOK
        FillSheetYAML(YAML, NSX_Config)
    else:
        FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")

