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
from lib.health import GetHealthNSXCluster, GetTNStatus, GetComputeDetail, GetEdgeCLDetail, GetEdgeStatus, GetLRSum, GetNetworkUsage, GetSecurityUsage, GetInventoryUsage
from lib.docs_alarms import CreateXLSAlarms
from lib.docs_groups import CreateXLSSecGrp
from lib.docs_securitypolicies import CreateXLSSecPol
from lib.docs_securitypolicies_and_rules import CreateXLSSecDFW
from lib.docs_tier1_segments import CreateXLST1Segments
from lib.docs_lr_summary import CreateXLSRouterSum
from lib.docs_lr_ports import CreateXLSRouterPorts
from lib.docs_tier1_segments import CreateXLST1Segments
from lib.docs_logical_switches import CreateXLSSegments
from lib.docs_tier0_routingtables import CreateXLST0RoutingTable
from lib.docs_tier1_forwardingtables import CreateXLST1ForwardingTable
from lib.docs_nsxmanagers import CreateXLSNSXManagerInfo
from lib.docs_discovered_nodes import CreateXLSFabDiscoveredNodes
from lib.docs_transportzones import CreateXLSTZ
from lib.docs_services import CreateXLSNSXServices
from lib.docs_tn_tunnels import CreateXLSTunnels
from lib.docs_set import DocsSetMultiple, DocsSetOne
from lib.system import style

# Definition of one menu
class Menu:
    def __init__(self, content, short_view, submenus = None, func = None):
        self.content = content
        self.short_view = short_view
        self.func = func
        if submenus != None:
            self.choices = dict(enumerate(submenus, 1)) #create dictionnary of submenus
            for sub in submenus:
                sub.parent = self # Definition of parent menu for each submenu
        else:
            self.choices = {}
            
def MainMenu(authlist,dest):
    global XLS_Dest
    XLS_Dest = dest
    FabManager = Menu("","NSX-T Manager Info", None, CreateXLSNSXManagerInfo)
    FabNodes = Menu("","Fabric Discovered Nodes", None, CreateXLSFabDiscoveredNodes)
    FabTZ = Menu("","Transport Zones", None, CreateXLSTZ)
    FabServices = Menu("","NSX-T Services", None, CreateXLSNSXServices)
    FabTunnles = Menu("","Transport Node Tunnels", None, CreateXLSTunnels)
    FabPrev = Menu("","Return to previous menu", None, 'Back')
    
    VNSSegment = Menu("","Export Segments", None, CreateXLSSegments)
    VNSRouterSum = Menu("", "Export Logical Router Summary", None, CreateXLSRouterSum)
    VNSRouterPort = Menu("", "Export Logical Router Ports", None, CreateXLSRouterPorts)
    VNST1Segment = Menu("", "Export Tier-1 Segment Connectivity", None, CreateXLST1Segments)
    VNST0 = Menu("", "Export Tier-0 Routing Tables", None, CreateXLST0RoutingTable)
    VNST1Tables = Menu("", "Export Tier-1 Forwarding Tables", None, CreateXLST1ForwardingTable)
    VNSPrev = Menu("", "Return to previous menu", None, 'Back')

    SecGrp = Menu("","Export Security Group Info", None, CreateXLSSecGrp)
    SecPol = Menu("","Export Security Policies", None, CreateXLSSecPol)
    SecDFW = Menu("","Export Distributed Firewall", None, CreateXLSSecDFW)
    SecPrev = Menu("","Return to previous menu", None, 'Back')

    MonAlarm = Menu("", "Export Alarms", None, CreateXLSAlarms)
    MonPrev = Menu("", "Return to previous menu", None, 'Back')

    DocSetOneFile = Menu("","One Excel file", None, DocsSetOne)
    DocSetMultiple = Menu("","Mulitple Excel files", None, DocsSetMultiple)
    DocSetPrev = Menu("", "Return to previous menu", None, 'Back')

    DocFab = Menu("\nNSX-T Fabric Documents", "NSX-T Fabric Options", [FabManager, FabNodes, FabTZ, FabServices, FabTunnles, FabPrev])
    DocVNS = Menu("\nVirtual Networking Documents", "Virtual Networking Options", [VNSSegment,VNSRouterSum,VNSRouterPort,VNST1Segment,VNST0,VNST1Tables,VNSPrev])
    DocSecu = Menu("\nSecurity Documents", "Security Options" ,[SecGrp, SecPol, SecDFW, SecPrev])
    DocMon = Menu("\nMonitoring & Alarm Documents", "Monitoring & Alarm Options" ,[MonAlarm, MonPrev])
    DocSet = Menu("\nNSX Document Set", "Create documentation set", [DocSetOneFile,DocSetMultiple,DocSetPrev])
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
        inpt = input("Choice ('back' to previous menu, 'exit' to exit program): ")
        if inpt == "exit":
            break
        elif inpt == "back":
            current_menu = current_menu.parent
        else:
#### Debug
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

###
            try:
                inpt = int(inpt)
                if not current_menu.choices[inpt].choices:
                    if current_menu.choices[inpt].func == 'Back':
                        current_menu = current_menu.parent
                        continue
                    else:
                        current_menu.choices[inpt].func(authlist)
                        continue
                    
                current_menu = current_menu.choices[inpt]
            except Exception as error:
                print(style.RED + "==> Invalid input: " + str(error) + style.NORMAL)
