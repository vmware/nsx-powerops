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
import pathlib, lib.menu
from lib.excel import FillSheet, Workbook, ConditionnalFormat, FillSheetCSV
from lib.system import style, GetAPI, ConnectNSX, os, GetCSV


def SheetBGPSession(auth_list,WORKBOOK,TN_WS, NSX_Config ={} ):
    NSX_Config['T0Sessions'] = []
    Dict_Sessions = {}

    SessionNSX = ConnectNSX(auth_list)
    ########### GET Tier-0 Gateways  ###########
    t0_url = '/policy/api/v1/infra/tier-0s'
    t0_json = GetAPI(SessionNSX[0],t0_url, auth_list)

    XLS_Lines = []
    TN_HEADER_ROW = ('T0','BGP status','ECMP','Inter-SR','Source IP address','Local AS','Neighbor IP address', 'Remote AS', 'Total IN Prefixes', 'Total OUT prefixes', 'Session Status')

    if isinstance(t0_json, dict) and 'results' in t0_json and t0_json['result_count'] > 0: 
        for t0 in t0_json["results"]:
            #localservice_url = "/policy/api/v1/infra/tier-0s/"+ t0['display_name'] +"/locale-services"
            localservice = "default"
            bgpstatus_url = "/policy/api/v1/infra/tier-0s/" + t0['display_name'] + "/locale-services/" + localservice + "/bgp/neighbors/status"
            bgpconfig_url = "/policy/api/v1/infra/tier-0s/" + t0['display_name'] + "/locale-services/" + localservice + "/bgp"
            #t0_localservice = GetAPI(SessionNSX[0],localservice_url, auth_list)
            bgpstatus_json = GetAPI(SessionNSX[0],bgpstatus_url, auth_list)
            bgpconfig_json = GetAPI(SessionNSX[0],bgpconfig_url, auth_list)
            Dict_Sessions['T0_name'] = t0['display_name']
            # BGP Sessions treatment
            if isinstance(bgpstatus_json, dict) and 'results' in bgpstatus_json: 
                Dict_Sessions['bgp_sessions'] = []
                Dict_bgp_session = {}
                if 'local_as_num' in bgpconfig_json:
                    Dict_bgp_session['local_as'] = str(bgpconfig_json['local_as_num'])
                else:
                    Dict_bgp_session['local_as'] = ""
                if 'inter_sr_ibgp' in bgpconfig_json:
                    Dict_bgp_session['inter_sr_ibgp'] = str(bgpconfig_json['inter_sr_ibgp']).upper()
                else:
                    Dict_bgp_session['inter_sr_ibgp'] = ''

                Dict_bgp_session['bgp_status'] = str(bgpconfig_json['enabled']).upper()
                Dict_bgp_session['ecmp'] = str(bgpconfig_json['ecmp']).upper()

                for session in bgpstatus_json['results']:
                    Dict_bgp_session['source_ip'] = session['source_address']
                    Dict_bgp_session['remote_ip'] = session['neighbor_address']
                    Dict_bgp_session['remote_as'] = str(session['remote_as_number'])
                    Dict_bgp_session['total_in'] = str(session['total_in_prefix_count'])
                    Dict_bgp_session['total_out'] = str(session['total_out_prefix_count'])
                    Dict_bgp_session['connection_state'] = session['connection_state']
                    Dict_Sessions['bgp_sessions'].append(Dict_bgp_session)
                    XLS_Lines.append([Dict_Sessions['T0_name'], Dict_bgp_session['bgp_status'], Dict_bgp_session['ecmp'], Dict_bgp_session['inter_sr_ibgp'], Dict_bgp_session['source_ip'], Dict_bgp_session['local_as'], Dict_bgp_session['remote_ip'], Dict_bgp_session['remote_as'],Dict_bgp_session['total_in'], Dict_bgp_session['total_out'],Dict_bgp_session['connection_state']])
                
            elif not bgpstatus_json:
                XLS_Lines.append([t0['display_name'],"No BGP sessions","","","","","","","","",""])        
            else:
                XLS_Lines.append([t0['display_name']," No BGP sessions","","","","","","","","",""])
            
            NSX_Config['T0Sessions'].append(Dict_Sessions)

        print(" --> Get BGP sessions for " + style.ORANGE + t0['display_name'] + style.NORMAL)

    else:
        XLS_Lines.append(["No T0 router found","","","","","","","","","",""])

    if GetCSV():
        CSV = WORKBOOK
        FillSheetCSV(CSV,TN_HEADER_ROW,XLS_Lines)
    else:
        FillSheet(WORKBOOK,TN_WS.title,TN_HEADER_ROW,XLS_Lines,"0072BA")
    ConditionnalFormat(TN_WS, 'K2:K' + str(len(XLS_Lines) + 1), 'ESTABLISHED')
    ConditionnalFormat(TN_WS, 'B2:B' + str(len(XLS_Lines) + 1), 'TRUE')
