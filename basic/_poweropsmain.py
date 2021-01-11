#!/usr/local/opt/python@3.8/bin/python3.8
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

#####  NSX-T POWEROPS FUNCTION DEFINITIONS #####

#Menu Validation Function
def invalid():
    print('')
    print("**** You have selected an invalid choice.  Please choose from one of the following options ****")
    print('')

def invalid_opt():
    invalid()
    main()

def invalid_opt_fab():
    invalid()
    opt_fab()

def invalid_opt_vns():
    invalid()
    opt_vns()

def invalid_opt_sec():
    invalid()
    opt_sec()

def invalid_opt_mon():
    invalid()
    opt_mon()

def invalid_opt_nsxhealth():
    invalid()
    opt_nsxhealth()

def invalid_opt_esxihealth():
    invalid()
    opt_esxihealth()

def invalid_opt_docs():
    invalid()
    opt_docs()

def invalid_opt_health():
    invalid()
    opt_health()

#Return to main menu
def menu_return():
    menu()

#Fabric Functions
def fab_opt_1():
    import docs_nsxmanagers
    docs_nsxmanagers.main()
    opt_fab()

def fab_opt_2():
    import docs_discovered_nodes
    docs_discovered_nodes.main()
    opt_fab()

def fab_opt_3():
    import docs_transportzones
    docs_transportzones.main()
    opt_fab()

def fab_opt_4():
    import docs_services
    docs_services.main()
    opt_fab()

def fab_opt_5():
    import docs_tn_tunnels
    docs_tn_tunnels.main()
    opt_fab()

#Virtual Networking Functions
def vns_opt_1():
    import docs_logical_switches
    docs_logical_switches.main()
    opt_vns()

def vns_opt_2():
    import docs_lr_summary
    docs_lr_summary.main()
    opt_vns()

def vns_opt_3():
    import docs_lr_ports
    docs_lr_ports.main()
    opt_vns()

def vns_opt_4():
    import docs_tier1_segments
    docs_tier1_segments.main()
    opt_vns()

def vns_opt_5():
    import docs_tier0_routingtables
    docs_tier0_routingtables.main()
    opt_vns()

def vns_opt_6():
    import docs_tier1_forwardingtables
    docs_tier1_forwardingtables.main()
    opt_vns()

#Security Functions
def sec_opt_1():
    import docs_groups
    docs_groups.main()
    opt_sec()

def sec_opt_2():
    import docs_securitypolicies
    docs_securitypolicies.main()
    opt_sec()

def sec_opt_3():
    import docs_securitypolicies_and_rules
    docs_securitypolicies_and_rules.main()
    opt_sec()

#NSX-T Alarms & Monitoring Functions
def mon_opt_1():
    import docs_alarms
    docs_alarms.main()
    opt_mon()

#NSX-T Health Check Functions
def nsx_hc_opt_1():
    import health_nsxcluster
    health_nsxcluster.main()
    opt_nsxhealth()

def nsx_hc_opt_2():
    import health_edgetnstatus
    health_edgetnstatus.main()
    opt_nsxhealth()

def nsx_hc_opt_3():
    import health_hosttnstatus
    health_hosttnstatus.main()
    opt_nsxhealth()

def nsx_hc_opt_4():
    import health_edgeclusters
    health_edgeclusters.main()
    opt_nsxhealth()

def nsx_hc_opt_5():
    import health_cmp_mgr
    health_cmp_mgr.main()
    opt_nsxhealth()

def nsx_hc_opt_6():
    import health_lr_summary
    health_lr_summary.main()
    opt_nsxhealth()

def nsx_hc_opt_7():
    import health_net_capacity
    health_net_capacity.main()
    opt_nsxhealth()

def nsx_hc_opt_8():
    import health_sec_capacity
    health_sec_capacity.main()
    opt_nsxhealth()

def nsx_hc_opt_9():
    import health_inv_capacity
    health_inv_capacity.main()
    opt_nsxhealth()

#ESXi Health Check Functions
def esxi_hc_opt_1():
    import health_tn_tunnels
    health_tn_tunnels.main()
    opt_esxihealth()

#Documentation Options
def opt_docs():
    print(" ")
    for option in doc_options:
        print(option+") "+doc_options.get(option)[0])
    
    choice = input("Please choose option: ")
    val = doc_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_docs

    action()

#Health Check Options
def opt_health():
    print(" ")
    for option in health_options:
        print(option+") "+health_options.get(option)[0])

    choice = input("Please choose option: ")
    val = health_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_health

    action()

#OPTION 1 - NSX-T Fabric Options
def opt_fab():
    print(" ")
    for option in fab_options:
        print(option+") "+fab_options.get(option)[0])

    choice = input("Please choose option: ")
    val = fab_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_fab

    action()

#OPTION 2 - Virtual Networking Options
def opt_vns():
    print(" ")
    for option in vns_options:
        print(option+") "+vns_options.get(option)[0])

    choice = input("Please choose option: ")
    val = vns_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_vns

    action()

#Create full documentation set
def doc_set():
    import time
    start_time = time.time()

    import docs_nsxmanagers
    docs_nsxmanagers.main()
    import docs_discovered_nodes
    docs_discovered_nodes.main()
    import docs_transportzones
    docs_transportzones.main()
    import docs_services
    docs_services.main()
    import docs_tn_tunnels
    docs_tn_tunnels.main()
    import docs_tier1_segments
    docs_tier1_segments.main()
    import docs_tier0_routingtables
    docs_tier0_routingtables.main()
    import docs_tier1_forwardingtables
    docs_tier1_forwardingtables.main()
    import docs_logical_switches
    docs_logical_switches.main()
    import docs_lr_summary
    docs_lr_summary.main()
    import docs_lr_ports
    docs_lr_ports.main()
    import docs_groups
    docs_groups.main()
    import docs_securitypolicies
    docs_securitypolicies.main()
    import docs_securitypolicies_and_rules
    docs_securitypolicies_and_rules.main()
    import docs_alarms
    docs_alarms.main()

    print('')
    print("Documentation set took %s seconds to complete" % (time.time() - start_time))
    print('')

    opt_docs()

#OPTION 3 - Security Options
def opt_sec():
    print(" ")
    for option in sec_options:
        print(option+") "+sec_options.get(option)[0])

    choice = input("Please choose option: ")
    val = sec_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_sec

    action()

#OPTION 4 - Monitoring & Alarm Options
def opt_mon():
    print(" ")
    for option in mon_options:
        print(option+") "+mon_options.get(option)[0])

    choice = input("Please choose option: ")
    val = mon_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_mon

    action()

def opt_nsxhealth():
    print(" ")
    for option in nsx_health_options:
        print(option+") "+nsx_health_options.get(option)[0])

    choice = input("Please choose option: ")
    val = nsx_health_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_nsxhealth

    action()

def opt_esxihealth():
    print(" ")
    for option in esxi_health_options:
        print(option+") "+esxi_health_options.get(option)[0])

    choice = input("Please choose option: ")
    val = esxi_health_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt_esxihealth

    action()

#####  SUB-MENU OPTIONS  #####

#FABRIC OPTIONS
fab_options = {"1":["NSX-T Manager Info",fab_opt_1], 
               "2":["Fabric Discovered Nodes",fab_opt_2],
               "3":["Transport Zones",fab_opt_3],
               "4":["NSX-T Services",fab_opt_4],
               "5":["Transport Node Tunnels",fab_opt_5],
               "6":["Return to previous menu",opt_docs]
        }

#VIRTUAL NETWORKING OPTIONS
vns_options = {"1":["Export Segments",vns_opt_1], 
               "2":["Export Logical Router Summary",vns_opt_2],
               "3":["Export Logical Router Ports",vns_opt_3],
               "4":["Export Tier-1 Segment Connectivity",vns_opt_4],
               "5":["Export Tier-0 Routing Tables",vns_opt_5],
               "6":["Export Tier-1 Forwarding Tables",vns_opt_6],
               "7":["Return to previous menu",opt_docs]
        }

#SECURITY OPTIONS
sec_options = {"1":["Export Security Group Info",sec_opt_1], 
               "2":["Export Security Policies",sec_opt_2],
               "3":["Export Distributed Firewall",sec_opt_3],
               "4":["Return to previous menu",opt_docs]
        }

#MONITORING & ALARM OPTIONS
mon_options = {"1":["Export Alarms",mon_opt_1], 
               "2":["Return to previous menu",opt_docs]
        }

#HEALTH CHECK OPTIONS
nsx_health_options = {"1":["Display NSX-T Manager Cluster & Appliance Status",nsx_hc_opt_1], 
                      "2":["Display Edge Transport Node Connectivity",nsx_hc_opt_2],
                      "3":["Display Host Transport Node Connectivity",nsx_hc_opt_3],
                      "4":["Display Edge Cluster Details",nsx_hc_opt_4],
                      "5":["Display Compute Manager Details",nsx_hc_opt_5],
                      "6":["Display Logical Router Summary",nsx_hc_opt_6],
                      "7":["Display Networking Usage",nsx_hc_opt_7],
                      "8":["Display Security Usage",nsx_hc_opt_8],
                      "9":["Display Inventory Usage",nsx_hc_opt_9],
                      "10":["Return to previous menu",opt_health]
                    }

esxi_health_options = {"1":["Get Transport Node Tunnels",esxi_hc_opt_1],
                       "2":["Return to previous menu",opt_health]}

doc_options = { "1":["NSX-T Fabric Options",opt_fab],
                "2":["Virtual Networking Options",opt_vns],
                "3":["Security Options",opt_sec],
                "4":["Monitoring & Alarm Options",opt_mon],
                "5":["Create documentation set",doc_set],
                "6":["Return to main menu",menu_return]
              }

health_options = { "1":["NSX-T Health Checks",opt_nsxhealth],
                   "2":["Host Transport Node Health Checks",opt_esxihealth],
                   "3":["Return to main menu",menu_return]
                }

main_options = { "1":["NSX-T Documentation",opt_docs],
                 "2":["Health Checks",opt_health],
                 "3":["Exit",quit]
               }

#CALL MAIN MENU FUNCTION & DO NOT CREATE OUTPUT DIRECTORY THIS IS CALLED FROM THE 'RETURN TO MENU' OPTION
def menu():
    print('')
    print('')
    print('################################################################################################')
    print('######                                                                                    ######')
    print('######    Hello & welcome to NSX-T PowerOps.  Please select one of the following options: ######')
    print('######                                                                                    ######')
    print('################################################################################################')
    print('')
    
    for option in main_options:
        print(option+") "+main_options.get(option)[0])

    choice = input("Please choose option: ")

    val = main_options.get(choice)

    if val is not None:
        action = val[1]
    else:
        action = invalid_opt

    action()

#CALL MAIN MENU FUNCTION & CREATE OUTPUT DIRECTORY
def main():
    print('')
    print('')
    print('################################################################################################')
    print('######                                                                                    ######')
    print('######    Hello & welcome to NSX-T PowerOps.  Please authenticate to NSX-T Manager:       ######')
    print('######                                                                                    ######')
    print('################################################################################################')
    print('')

    import _nsxauth
    from _nsxauth import response

    import importlib

    while response != '<Response [200]>':
        if response != '<Response [200]>':
            print('')
            print('Incorrect FQDN, Username or Password entered.  Please re-enter credentials:')
            print('') 
            importlib.reload(_nsxauth)
            from _nsxauth import response
        else: 
            import time
            import _createdir
            from _createdir import dest

            print('')
            print('Successful authentication.  Generating output directory....')
            print('')
            time.sleep(1)
            print('Documentation output directory is: ',dest)
            print('')
            time.sleep(1) 

            print('')
            print('##############################################################')
            print('######                                                  ######')
            print('######    Please select one of the following options:   ######')
            print('######                                                  ######')
            print('##############################################################')
            print('')
                
            for option in main_options:
                print(option+") "+main_options.get(option)[0])

            choice = input("Please choose option: ")

            val = main_options.get(choice)

            if val is not None:
                action = val[1]
            else:
                action = invalid_opt

            action()
    
    while response == '<Response [200]>':
        if response == '<Response [200]>':
            import time
            import _createdir
            from _createdir import dest

            print('')
            print('Successful authentication.  Generating output directory....')
            print('')
            time.sleep(1)
            print('Documentation output directory is: ',dest)
            print('')
            time.sleep(1) 

            print('')
            print('##############################################################')
            print('######                                                  ######')
            print('######    Please select one of the following options:   ######')
            print('######                                                  ######')
            print('##############################################################')
            print('')
                
            for option in main_options:
                print(option+") "+main_options.get(option)[0])

            choice = input("Please choose option: ")

            val = main_options.get(choice)

            if val is not None:
                action = val[1]
            else:
                action = invalid_opt

            action()

if __name__ == "__main__":
    main()
