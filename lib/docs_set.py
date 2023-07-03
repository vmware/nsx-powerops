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
from lib.docs_summary import SheetSummary
from lib.docs_alarms import SheetAlarms
from lib.docs_monitoring import SheetMonitoring
from lib.docs_groups import SheetSecGrp
from lib.docs_securitypolicies import SheetSecPol
from lib.docs_securitypolicies_and_rules import SheetSecDFW
from lib.docs_tier1_segments import SheetT1Segments
from lib.docs_lr_summary import SheetRouterSum
from lib.docs_lr_ports import SheetRouterPorts
from lib.docs_tier1_segments import SheetT1Segments
from lib.docs_logical_switches import SheetSegments
from lib.docs_RoutingSessions import SheetBGPSession
from lib.docs_tier0_routingtables import SheetT0RoutingTable
from lib.docs_tier1_forwardingtables import SheetT1ForwardingTable
from lib.docs_nsxmanagers import SheetNSXManagerInfo
from lib.docs_discovered_nodes import SheetFabDiscoveredNodes
from lib.docs_transportzones import SheetTZ
from lib.docs_services import SheetNSXServices
from lib.docs_tn_tunnels import SheetTunnels
from lib.system import GetOutputFormat, style, os
from lib.excel import CreateXLSFile
import lib.menu
import time, pathlib, pprint

def DocsSetOne(SessionNSX):
    if GetOutputFormat() == 'CSV':
        print(style.RED + " ==> Invalid: CSV output incompatible with single file documentation set " + style.NORMAL)
        return
    global NSX_Config
    NSX_Config = {}
    start_time = time.time()
    WORKBOOK = CreateXLSFile(SessionNSX,'Audit_NSX')
    if WORKBOOK != None:
        if GetOutputFormat() == 'JSON' or GetOutputFormat() == 'YAML':
            TN_WS = WORKBOOK[1].active
            print('\nGenerating Summary sheet')
            SheetSummary(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('\nGenerating NSX-T Manager Information sheet')
            SheetNSXManagerInfo(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('Generating NSX-T Fabric Discovered Nodes sheet')
            SheetFabDiscoveredNodes(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('Generating NSX-T Transport Zones sheet')
            SheetTZ(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Services sheet')
            SheetNSXServices(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T TEP Tunnels sheet')
            SheetTunnels(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Segments sheet')
            SheetSegments(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router Summary sheet')
            SheetRouterSum(SessionNSX,WORKBOOK[0],TN_WS)
            print('Generating NSX-T Router Ports sheet')
            SheetRouterPorts(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router T1 Segments sheet')
            SheetT1Segments(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('Generating NSX-T Router T0 BGP Sessions sheet')
            SheetBGPSession(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router T0 Routing Tables sheet')
            SheetT0RoutingTable(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router T1 Forwarding Tables sheet')
            SheetT1ForwardingTable(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Groups sheet')
            SheetSecGrp(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Security Policies sheet')
            SheetSecPol(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Security DFW sheet')
            SheetSecDFW(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Alarms sheet')
            SheetAlarms(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Monitoring sheet')
            SheetMonitoring(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print("\nDocumentation set took %s seconds to complete\n" % (time.time() - start_time))
            WORKBOOK[1].close()
        else:
            TN_WS = WORKBOOK[0].active
            TN_WS.title = "Summary"
            print('\nGenerating Summary sheet')
            SheetSummary(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('\nGenerating NSX-T Manager Information sheet')
            TN_WS = WORKBOOK[0].create_sheet("NSX_Manager_Info")
            SheetNSXManagerInfo(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('Generating NSX-T Fabric Discovered Nodes sheet')
            TN_WS = WORKBOOK[0].create_sheet("Transport_Nodes")
            SheetFabDiscoveredNodes(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('Generating NSX-T Transport Zones sheet')
            TN_WS = WORKBOOK[0].create_sheet("Transport_Zones")
            SheetTZ(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Services sheet')
            TN_WS = WORKBOOK[0].create_sheet("Services")
            SheetNSXServices(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T TEP Tunnels sheet')
            TN_WS = WORKBOOK[0].create_sheet("Transport_Node_Tunnels")
            SheetTunnels(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Segments sheet')
            TN_WS = WORKBOOK[0].create_sheet("Segments")
            SheetSegments(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router Summary sheet')
            TN_WS = WORKBOOK[0].create_sheet("Logical_Router_Summary")
            SheetRouterSum(SessionNSX,WORKBOOK[0],TN_WS)
            print('Generating NSX-T Router Ports sheet')
            TN_WS = WORKBOOK[0].create_sheet("Logical_Router_Ports")
            SheetRouterPorts(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router T1 Segments sheet')
            TN_WS = WORKBOOK[0].create_sheet("Tier1_Segments")
            SheetT1Segments(SessionNSX,WORKBOOK[0],TN_WS,NSX_Config)
            print('Generating NSX-T Router T0 BGP Sessions sheet')
            TN_WS = WORKBOOK[0].create_sheet("Tier0_BGP_Sessions")
            SheetBGPSession(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router T0 Routing Tables sheet')
            TN_WS = WORKBOOK[0].create_sheet("Tier0_Routing_Tables")
            SheetT0RoutingTable(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Router T1 Forwarding Tables sheet')
            TN_WS = WORKBOOK[0].create_sheet("Tier1_Forwarding_Tables")
            SheetT1ForwardingTable(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Groups sheet')
            TN_WS = WORKBOOK[0].create_sheet("Security_Groups")
            SheetSecGrp(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Security Policies sheet')
            TN_WS = WORKBOOK[0].create_sheet("Security_Policies")
            SheetSecPol(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Security DFW sheet')
            TN_WS = WORKBOOK[0].create_sheet("Rules_Distributed_Firewall")
            SheetSecDFW(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Alarms sheet')
            TN_WS = WORKBOOK[0].create_sheet("Alarms")
            SheetAlarms(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print('Generating NSX-T Monitoring sheet')
            TN_WS = WORKBOOK[0].create_sheet("Monitoring")
            SheetMonitoring(SessionNSX,WORKBOOK[0],TN_WS, NSX_Config)
            print("\nDocumentation set took %s seconds to complete\n" % (time.time() - start_time))
            WORKBOOK[0].save(WORKBOOK[1])

def DocsSetMultiple(SessionNSX):
    start_time = time.time()
    CreateXLSFile(SessionNSX,"NSX_Managers_Info",SheetNSXManagerInfo)
    CreateXLSFile(SessionNSX,"Fabric_Discovered_Nodes",SheetFabDiscoveredNodes)
    CreateXLSFile(SessionNSX,"Transport_Node_Tunnels",SheetTunnels)
    CreateXLSFile(SessionNSX,"Transport_Zones",SheetTZ)
    CreateXLSFile(SessionNSX,"Services",SheetNSXServices)

    CreateXLSFile(SessionNSX,"Security_Groups",SheetSecGrp)
    CreateXLSFile(SessionNSX,"Security_Policies",SheetSecPol)
    CreateXLSFile(SessionNSX,"Rules_Distributed_Firewall",SheetSecDFW)

    CreateXLSFile(SessionNSX,"Segments",SheetSegments)
    CreateXLSFile(SessionNSX,"Logical_Router_Ports",SheetRouterPorts)
    CreateXLSFile(SessionNSX,"Logical_Router_Summary",SheetRouterSum)
    CreateXLSFile(SessionNSX,"Tier_0_BGP_Sessions",SheetBGPSession)
    CreateXLSFile(SessionNSX,"Tier_0_Routing_Tables",SheetT0RoutingTable)
    CreateXLSFile(SessionNSX,"Tier_1_Segments",SheetT1Segments)
    CreateXLSFile(SessionNSX,"Tier_1_Forwarding_Tables",SheetT1ForwardingTable)
    
    CreateXLSFile(SessionNSX,"Alarms",SheetAlarms)
    CreateXLSFile(SessionNSX,"Monitoring",SheetMonitoring)

    print("\nDocumentation set took %s seconds to complete\n" % (time.time() - start_time))
    
