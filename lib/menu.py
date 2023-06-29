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
from lib.health import GetBGPSessions, GetHealthNSXCluster, GetNSXSummary, GetTNTunnels, GetTNStatus, GetComputeDetail,\
    GetEdgeCLDetail, GetEdgeStatus, GetLRSum, GetNetworkUsage, GetSecurityUsage, GetInventoryUsage, GetDFWRulesVNIC, GetDFWRulesStats
from lib.docs_alarms import SheetAlarms
from lib.docs_monitoring import SheetMonitoring
from lib.docs_groups import SheetSecGrp
from lib.docs_securitypolicies import SheetSecPol
from lib.docs_securitypolicies_and_rules import SheetSecDFW
from lib.docs_tier1_segments import SheetT1Segments
from lib.docs_RoutingSessions import SheetBGPSession
from lib.docs_lr_summary import SheetRouterSum
from lib.docs_lr_ports import SheetRouterPorts
from lib.docs_tier1_segments import SheetT1Segments
from lib.docs_logical_switches import SheetSegments
from lib.docs_tier0_routingtables import SheetT0RoutingTable
from lib.docs_tier1_forwardingtables import SheetT1ForwardingTable
from lib.docs_nsxmanagers import SheetNSXManagerInfo
from lib.docs_discovered_nodes import SheetFabDiscoveredNodes
from lib.docs_transportzones import SheetTZ
from lib.docs_services import SheetNSXServices
from lib.docs_tn_tunnels import SheetTunnels
from lib.docs_set import DocsSetMultiple, DocsSetOne
from lib.system import style, CopyFile
from lib.excel import CreateXLSFile
from lib.diff import IfDiff, GetDiffFileName, SetXLSDiffFile
import os
import traceback

# Definition of one menu
class Menu:
    def __init__(self, content, short_view, submenus = None, func = None, xlsfile = None):
        self.content = content
        self.short_view = short_view
        self.func = func
        self.xlsfile = xlsfile
        if submenus != None:
            self.choices = dict(enumerate(submenus, 1)) #create dictionnary of submenus
            for sub in submenus:
                sub.parent = self # Definition of parent menu for each submenu
        else:
            self.choices = {}
            
def MainMenu(authlist,dest,menu_path,menu_mode):
    global XLS_Dest
    XLS_Dest = dest
    FabManager = Menu("","NSX-T Manager Info", None, SheetNSXManagerInfo, "NSX_Managers_Info")
    FabNodes = Menu("","Fabric Discovered Nodes", None, SheetFabDiscoveredNodes, "Fabric_Discovered_Nodes")
    FabTZ = Menu("","Transport Zones", None, SheetTZ, "Transport_Zones")
    FabServices = Menu("","NSX-T Services", None, SheetNSXServices, "Services")
    FabTunnles = Menu("","Transport Node Tunnels", None, SheetTunnels,"Transport_Node_Tunnels")
    FabPrev = Menu("","Return to previous menu", None, 'Back')
    
    VNSSegment = Menu("","Export Segments", None, SheetSegments, "Segments")
    VNSRouterSum = Menu("", "Export Logical Router Summary", None, SheetRouterSum,"Logical_Router_Summary")
    VNSRouterPort = Menu("", "Export Logical Router Ports", None, SheetRouterPorts, "Logical_Router_Ports")
    VNST1Segment = Menu("", "Export Tier-1 Segment Connectivity", None, SheetT1Segments, "Tier1_Segments")
    VNST1RoutingSessions = Menu("", "Export Tier-0 BGP Sessions", None, SheetBGPSession, "Tier0_BGP_Sessions")
    VNST0 = Menu("", "Export Tier-0 Routing Tables", None, SheetT0RoutingTable, "Tier0_Routing_Tables")
    VNST1Tables = Menu("", "Export Tier-1 Forwarding Tables", None, SheetT1ForwardingTable, "Tier1_Forwarding_Tables")
    VNSPrev = Menu("", "Return to previous menu", None, 'Back')

    SecGrp = Menu("","Export Security Group Info", None, SheetSecGrp, "Security_Groups")
    SecPol = Menu("","Export Security Policies", None, SheetSecPol, "Security_Policies")
    SecDFW = Menu("","Export Distributed Firewall", None, SheetSecDFW, "Rules_Distributed_Firewall")
    SecPrev = Menu("","Return to previous menu", None, 'Back')

    MonAlarm = Menu("", "Export Alarms", None, SheetAlarms,"Alarms")
    MonConfig = Menu("", "Monitoring Config", None, SheetMonitoring, "Monitoring")
    MonPrev = Menu("", "Return to previous menu", None, 'Back')

    DocSetOneFile = Menu("","One file (appended results for JSON, YAML format) and one Excel file with one tab per menu. Not supported for CSV.", None, DocsSetOne)
    DocSetMultiple = Menu("","Multiple files", None, DocsSetMultiple)
    DocSetPrev = Menu("", "Return to previous menu", None, 'Back')

    DocFab = Menu("\nNSX-T Fabric Documents", "NSX-T Fabric Options", [FabManager, FabNodes, FabTZ, FabServices, FabTunnles, FabPrev])
    DocVNS = Menu("\nVirtual Networking Documents", "Virtual Networking Options", [VNSSegment,VNSRouterSum,VNSRouterPort,VNST1Segment,VNST1RoutingSessions, VNST0,VNST1Tables,VNSPrev])
    DocSecu = Menu("\nSecurity Documents", "Security Options" ,[SecGrp, SecPol, SecDFW, SecPrev])
    DocMon = Menu("\nMonitoring & Alarm Documents", "Monitoring & Alarm Options" ,[MonAlarm, MonConfig, MonPrev])
    DocSet = Menu("\nNSX Document Set", "Create documentation set", [DocSetOneFile,DocSetMultiple,DocSetPrev])
    DocPrev = Menu("", "Return to main menu", None, 'Back')

    subhealth1 = Menu("", "Display NSX-T Summary", None, GetNSXSummary)
    subhealth2 = Menu("", "Display NSX-T Manager Cluster & Appliance Status", None, GetHealthNSXCluster)
    subhealth3 = Menu("", "Display Transport node tunnels", None, GetTNTunnels)
    subhealth4 = Menu("", "Display Edge Transport Node Connectivity", None, GetEdgeStatus)
    subhealth5 = Menu("", "Display Host Transport Node Connectivity", None, GetTNStatus)
    subhealth6 = Menu("", "Display Edge Cluster Details", None, GetEdgeCLDetail)
    subhealth7 = Menu("", "Display Compute Manager Details", None, GetComputeDetail)
    subhealth8 = Menu("", "Display Logical Router Summary", None, GetLRSum)
    subhealth9 = Menu("", "Display BGP Sessions Summary", None, GetBGPSessions)
    subhealth10 = Menu("", "Display Networking Usage", None, GetNetworkUsage)
    subhealth11 = Menu("", "Display Security Usage", None, GetSecurityUsage)
    subhealth12 = Menu("", "Display Inventory Usage", None, GetInventoryUsage)
    subhealth13 = Menu("", "Display DFW Rules per VNIC", None, GetDFWRulesVNIC)
    subhealth14 = Menu("", "Display DFW Rules statistics", None, GetDFWRulesStats)
    subhealth15 = Menu("", "Return to previous menu", None, 'Back')

    Doc = Menu("\nNSX-T Documentation", "NSX-T Documentation", [DocFab, DocVNS, DocSecu, DocMon, DocSet, DocPrev])
    Health = Menu("\nHealth Checks", "Health Checks", [subhealth1,subhealth2,subhealth3,subhealth4,subhealth5,subhealth6,subhealth7,subhealth8,subhealth9,subhealth10,subhealth11, subhealth12, subhealth13, subhealth14])

    main = Menu("Main Menu", "", [Doc, Health])
    main.parent = main
    current_menu = main

    # Check if diff mode
    if IfDiff() :
        # copy initial file xls config to compare
        xls_diff_filename = GetDiffFileName()
        xls_diff_temp_file = xls_diff_filename.rsplit( ".", 1 )[ 0 ]
        xls_diff_temp_file = xls_diff_temp_file + "_TEMP" + ".xlsx"
        CopyFile(xls_diff_filename, xls_diff_temp_file)
        # If diff mode : build doc XLS
        SetXLSDiffFile(authlist, xls_diff_temp_file)
        # delete temp diff file
        try:
            os.remove(xls_diff_temp_file)
        except OSError as e:  ## if failed, report it back to the user ##
            print ("Error: %s - %s." % (e.filename, e.strerror))
        return

    while True:
        if not menu_mode:
            print("\n")
            print("\n".join([f"{num}) {current_menu.choices[num].short_view}" for num in current_menu.choices]))
        inpt = None
        # If cli args inputs for menu navigation
        if len(menu_path) > 0:
            # Read the first arg of cli then pop this arg.
            inpt = menu_path[0]
            menu_path.pop(0)
        # Else ask user for menu navigation
        else:
            inpt = input("Choice ('back' to previous menu, 'exit' to exit program): ")
        if inpt == "exit":
            break
        elif inpt == "back":
            current_menu = current_menu.parent
        else:
##### Debug
#            inpt = int(inpt)
#            if not current_menu.choices[inpt].choices:
#                if current_menu.choices[inpt].func == 'Back':
#                    current_menu = current_menu.parent
#                    continue
#                else:
#                    # Create one file
#                    if 'Sheet' in current_menu.choices[inpt].func.__name__:
#                        CreateXLSFile(authlist,current_menu.choices[inpt].xlsfile, current_menu.choices[inpt].func)
#                        #WB = CreateXLSFile(authlist,current_menu.choices[inpt].xlsfile)
#                        ## Creation of sheet
#                        #TN_WS = WB[0].active
#                        #TN_WS.title = current_menu.choices[inpt].xlsfile
#                        #current_menu.choices[inpt].func(authlist,WB[0],TN_WS)
#                        #WB[0].save(WB[1])
#                        continue
#                    # For Health and documentations set
#                    else:
#                        current_menu.choices[inpt].func(authlist)
#                        continue
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
                        # Create one file
                        if 'Sheet' in current_menu.choices[inpt].func.__name__:
                            CreateXLSFile(authlist,current_menu.choices[inpt].xlsfile, current_menu.choices[inpt].func)
                            #WB = CreateXLSFile(authlist,current_menu.choices[inpt].xlsfile)
                            ## Creation of sheet
                            #TN_WS = WB[0].active
                            #TN_WS.title = current_menu.choices[inpt].xlsfile
                            #current_menu.choices[inpt].func(authlist,WB[0],TN_WS)
                            #WB[0].save(WB[1])
                            continue
                        # For Health and documentations set
                        else:
                            current_menu.choices[inpt].func(authlist)
                            continue
                    
                current_menu = current_menu.choices[inpt]
            except Exception as error:
                print(style.RED + "==> Invalid input: " + str(error) + style.NORMAL)
                traceback.print_exc()
