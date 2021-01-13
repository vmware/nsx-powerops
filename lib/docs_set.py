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
from lib.docs_alarms import *
from lib.docs_groups import *
from lib.docs_securitypolicies import *
from lib.docs_securitypolicies_and_rules import *
from lib.docs_tier1_segments import *
from lib.docs_lr_summary import *
from lib.docs_lr_ports import *
from lib.docs_tier1_segments import *
from lib.docs_logical_switches import *
from lib.docs_tier0_routingtables import *
from lib.docs_tier1_forwardingtables import *
from lib.docs_nsxmanagers import *
from lib.docs_discovered_nodes import *
from lib.docs_transportzones import *
from lib.docs_services import *
from lib.docs_tn_tunnels import *
from lib.system import *
import lib.menu
import time

def DocsSetOne(auth_list):
    start_time = time.time()
    # Setup excel workbook and worksheets 
    ls_wkbk = Workbook()  
    #### Check if script has already been run for this runtime of PowerOps.  If so, skip and do not overwrite ###
    XLS_File = lib.menu.XLS_Dest + os.path.sep + "Audit_NSX.xls"
    fname = pathlib.Path(XLS_File)
    if fname.exists():
        print('')
        print(fname, 'file already exists.  Not attempting to overwite')
        print('')
        return

    print('')
    print('Generating NSX-T Manager Information sheet')
    SheetNSXManagerInfo(auth_list,ls_wkbk)
    print('Generating NSX-T Fabric Discovered Nodes sheet')
    SheetFabDiscoveredNodes(auth_list,ls_wkbk)
    print('Generating NSX-T Transport Zones sheet')
    SheetTZ(auth_list,ls_wkbk)
    print('Generating NSX-T Services sheet')
    SheetNSXServices(auth_list,ls_wkbk)
    print('Generating NSX-T TEP Tunnels sheet')
    SheetTunnels(auth_list,ls_wkbk)
    print('Generating NSX-T Segments sheet')
    SheetSegments(auth_list,ls_wkbk)
    print('Generating NSX-T Router Summary sheet')
    SheetRouterSum(auth_list,ls_wkbk)
    print('Generating NSX-T Router Ports sheet')
    SheetRouterPorts(auth_list,ls_wkbk)
    print('Generating NSX-T Router T1 Segments sheet')
    SheetT1Segments(auth_list,ls_wkbk)
    print('Generating NSX-T Router T0 Routing Tables sheet')
    SheetT0RoutingTable(auth_list,ls_wkbk)
    print('Generating NSX-T Router T1 Forwarding Tables sheet')
    SheetT1ForwardingTable(auth_list,ls_wkbk)
    print('Generating NSX-T Groups sheet')
    SheetSecGrp(auth_list,ls_wkbk)
    print('Generating NSX-T Security Policies sheet')
    SheetSecPol(auth_list,ls_wkbk)
    print('Generating NSX-T Security DFW sheet')
    SheetSecDFW(auth_list,ls_wkbk)
    print('Generating NSX-T Alarms sheet')
    SheetAlarms(auth_list,ls_wkbk)
    print("\nDocumentation set took %s seconds to complete" % (time.time() - start_time))
    print('')
    ls_wkbk.save(XLS_File)

def DocsSetMultiple(auth_list):
    start_time = time.time()

    CreateXLSNSXManagerInfo(auth_list)
    CreateXLSFabDiscoveredNodes(auth_list)
    CreateXLSTZ(auth_list)
    CreateXLSNSXServices(auth_list)
    CreateXLSTunnels(auth_list)
    CreateXLSSegments(auth_list)
    CreateXLSRouterSum(auth_list)
    CreateXLSRouterPorts(auth_list)
    CreateXLST1Segments(auth_list)
    CreateXLST0RoutingTable(auth_list)
    CreateXLST1ForwardingTable(auth_list)
    CreateXLSSecGrp(auth_list)
    CreateXLSSecPol(auth_list)
    CreateXLSSecDFW(auth_list)
    CreateXLSAlarms(auth_list)

    print("\nDocumentation set took %s seconds to complete" % (time.time() - start_time))
    print('')

    