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

from lib.health import *
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
from lib.docs_set import *

class Menu:
    def __init__(self, content, short_view, submenus = None, func = None):
        self.content = content
        self.short_view = short_view
        self.func = func
        if submenus != None:
            self.choices = dict(enumerate(submenus, 1))
            for sub in submenus:
                sub.parent = self
        else:
            self.choices = {}
            
def MainMenu(authlist,dest):
    global XLS_Dest
    XLS_Dest = dest
    FabManager = Menu("","NSX-T Manager Info", None, DocsNSXManagerInfo)
    FabNodes = Menu("","Fabric Discovered Nodes", None, DocsFabDiscoveredNodes)
    FabTZ = Menu("","Transport Zones", None, DocsTZ)
    FabServices = Menu("","NSX-T Services", None, DocsNSXServices)
    FabTunnles = Menu("","Transport Node Tunnels", None, DocsTunnels)
    FabPrev = Menu("","Return to previous menu", None, 'Back')
    
    VNSSegment = Menu("","Export Segments", None, DocsSegments)
    VNSRouterSum = Menu("", "Export Logical Router Summary", None, DocsRouterSum)
    VNSRouterPort = Menu("", "Export Logical Router Ports", None, DocsRouterPorts)
    VNST1Segment = Menu("", "Export Tier-1 Segment Connectivity", None, DocsT1Segments)
    VNST0 = Menu("", "Export Tier-0 Routing Tables", None, DocsT0RoutingTable)
    VNST1Tables = Menu("", "Export Tier-1 Forwarding Tables", None, DocsT1ForwardingTable)
    VNSPrev = Menu("", "Return to previous menu", None, 'Back')

    SecGrp = Menu("","Export Security Group Info", None, DocsSecGrp)
    SecPol = Menu("","Export Security Policies", None, DocsSecPol)
    SecDFW = Menu("","Export Distributed Firewall", None, DocsSecDFW)
    SecPrev = Menu("","Return to previous menu", None, 'Back')

    MonAlarm = Menu("", "Export Alarms", None, DocsAlarms )
    MonPrev = Menu("", "Return to previous menu", None, 'Back')

    DocFab = Menu("\nNSX-T Fabric Documents", "NSX-T Fabric Options", [FabManager, FabNodes, FabTZ, FabServices, FabTunnles, FabPrev])
    DocVNS = Menu("\nVirtual Networking Documents", "Virtual Networking Options", [VNSSegment,VNSRouterSum,VNSRouterPort,VNST1Segment,VNST0,VNST1Tables,VNSPrev])
    DocSecu = Menu("\nSecurity Documents", "Security Options" ,[SecGrp, SecPol, SecDFW, SecPrev])
    DocMon = Menu("\nMonitoring & Alarm Documents", "Monitoring & Alarm Options" ,[MonAlarm, MonPrev])
    DocSet = Menu("", "Create documentation set", None, DocsSet)
    DocPrev = Menu("", "Return to main menu", None, 'Back')

    subhealth1 = Menu("", "Display NSX-T Manager Cluster & Appliance Status", None, GetHealthNSXCluster)
    subhealth2 = Menu("", "Display Edge Transport Node Connectivity", None, GetEdgeStatus)
    subhealth3 = Menu("", "Display Host Transport Node Connectivity", None, GetTNStatus)
    subhealth4 = Menu("", "Display Edge Cluster Details", None, GetEdgeCLDetail)
    subhealth5 = Menu("", "Display Compute Manager Details", None, GetComputeDetail)
    subhealth6 = Menu("", "Display Logical Router Summary", None, GetLRSum)
    subhealth7 = Menu("", "Display Networking Usage", None, GetNetworkUsage)
    subhealth8 = Menu("", "Display Security Usage", None, GetSecurityUsage)
    subhealth9 = Menu("", "Display Inventory Usage", None, GetInventoryUsage)
    subhealth10 = Menu("", "Return to previous menu", None, 'Back')

    Doc = Menu("\nNSX-T Documentation", "NSX-T Documentation", [DocFab, DocVNS, DocSecu, DocMon, DocSet, DocPrev])
    Health = Menu("\nHealth Checks", "Health Checks", [subhealth1,subhealth2,subhealth3,subhealth4,subhealth5,subhealth6,subhealth7,subhealth8,subhealth9,subhealth10])

    main = Menu("Main Menu", "", [Doc, Health])
    main.parent = main
    current_menu = main
    while True:
        print("\n")
        print("\n".join([f"{num}) {current_menu.choices[num].short_view}" for num in current_menu.choices]))
        inpt = input("Choice: ")
        if inpt == "exit":
            break
        elif inpt == "back":
            current_menu = current_menu.parent
        else:
#### debug
            inpt = int(inpt)
            if not current_menu.choices[inpt].choices:
                if current_menu.choices[inpt].func == 'Back':
                    current_menu = current_menu.parent
                    continue
                else:
                    current_menu.choices[inpt].func(authlist)
                    continue
                
            current_menu = current_menu.choices[inpt]

####
    #        try:
    #            inpt = int(inpt)
    #            if not current_menu.choices[inpt].choices:
    #                if current_menu.choices[inpt].func == 'Back':
    #                    current_menu = current_menu.parent
    #                    continue
    #                else:
    #                    current_menu.choices[inpt].func(authlist)
    #                    continue
    #                
    #            current_menu = current_menu.choices[inpt]
    #        except Exception as error:
    #            print("!! ==> Invalid input")
    #            print(error)
            
