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

def DocsSet(auth_list):
    start_time = time.time()

    DocsNSXManagerInfo(auth_list)
    DocsFabDiscoveredNodes(auth_list)
    DocsTZ(auth_list)
    DocsNSXServices(auth_list)
    DocsTunnels(auth_list)
    DocsSegments(auth_list)
    DocsRouterSum(auth_list)
    DocsRouterPorts(auth_list)
    DocsT1Segments(auth_list)
    DocsT0RoutingTable(auth_list)
    DocsT1ForwardingTable(auth_list)
    DocsSecGrp(auth_list)
    DocsSecPol(auth_list)
    DocsSecDFW(auth_list)
    DocsAlarms(auth_list)

    print("\nDocumentation set took %s seconds to complete" % (time.time() - start_time))
    print('')

    