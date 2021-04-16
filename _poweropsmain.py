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
import time
from lib.system import CheckCertFiles, ReadYAMLCfgFile, CreateOutputFolder, style, auth_nsx
from lib.menu import MainMenu
import sys
import argparse



def print_help():
    print ("usage: run_powerops [--help] [--interactive] [--run config.yml | --menu config.yml]")
    print ("nsx-t powerops")
    print ("")
    print ("optional arguments:")
    print ("  --help, -h        show this help message and exit")
    print ("  --interactive, -i      Request to run powerops interactively and override optional yaml MENU field. (Default=False)")
    print ("  --run config.yml, -r config.yml     Path to YAML config file : NSX Manager params. & NSX data to collect (Default=config.yml)")
    print ("  --menu N [N ...], -m N [N ...]      Indicates option menu you want to retrieve. (Default=exit)")
    print("")
    print("menu navigation --> N [N ...] =")
    print("   exit  => Exit NSX-T powerops")
    print("   1 1 1 => NSX-T Fabric Options - NSX-T Manager Info")
    print("   1 1 2 => NSX-T Fabric Options - Fabric Discovered Nodes")
    print("   1 1 3 => NSX-T Fabric Options - Transport Zones")
    print("   1 1 4 => NSX-T Fabric Options - NSX-T Services")
    print("   1 1 5 => NSX-T Fabric Options - Transport Node Tunnels")
    print("   1 2 1 => Virtual Networking Options - Export Segments")
    print("   1 2 2 => Virtual Networking Options - Export Logical Router Summary")
    print("   1 2 3 => Virtual Networking Options - Export Logical Router Ports")
    print("   1 2 4 => Virtual Networking Options - Export Tier-1 Segment Connectivity")
    print("   1 2 5 => Virtual Networking Options - Export Tier-0 BGP Sessions")
    print("   1 2 6 => Virtual Networking Options - Export Tier-0 Routing Tables")
    print("   1 2 7 => Virtual Networking Options - Export Tier-1 Forwarding Tables")
    print("   1 3 1 => Security Options - Export Security Group Info")
    print("   1 3 2 => Security Options - Export Security Policies")
    print("   1 3 3 => Security Options - Export Distributed Firewall")
    print("   1 4 1 => Monitoring & Alarm Options - Export Alarms")
    print("   1 5 1 => Create documentation set - One Excel file")
    print("   1 5 1 => Create documentation set - Mulitple Excel files")
    print("   2 1   => Health Checks - Display NSX-T Summary")
    print("   2 2   => Health Checks - Display NSX-T Manager Cluster & Appliance Status")
    print("   2 3   => Health Checks - Display Transport node tunnels")
    print("   2 4   => Health Checks - Display Edge Transport Node Connectivity")
    print("   2 5   => Health Checks - Display Host Transport Node Connectivity")
    print("   2 6   => Health Checks - Display Edge Cluster Details")
    print("   2 7   => Health Checks - Display Compute Manager Details")
    print("   2 8   => Health Checks - Display Logical Router Summary")
    print("   2 9   => Health Checks - Display BGP Sessions Summary")
    print("   2 10  => Health Checks - Display Networking Usage")
    print("   2 11  => Health Checks - Display Security Usage")
    print("   2 12  => Health Checks - Display Inventory Usage")

def main():
    YAML_CFG_FILE = 'config.yml'

    # HELP COMMAND CHECKING
    # If command used with args, then remove first argument (=pyhton file)
    parser = argparse.ArgumentParser(description='nsx-t powerops', add_help=False)
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--run', '-r', metavar='config.yml', required=False, help='Path to YAML config file : NSX Manager params. & NSX data to collect (Default=config.yml)', default=argparse.SUPPRESS)
    group.add_argument('--menu', '-m', metavar='N', nargs='+', required=False, help='Indicates option menu you want to retrieve. (Default=exit)', default=argparse.SUPPRESS)
    parser.add_argument('--help', '-h', required=False, action='store_true')
    parser.add_argument('--interactive', '-i', required=False, action='store_true', default=False)
    args = parser.parse_args()
    if  args.help == True:
        print_help()
        quit()    

    # Start powerops
    print('')
    print('')
    print('################################################################################################')
    print('######                                                                                    ######')
    print('######    Hello & welcome to NSX-T PowerOps.  Please authenticate to NSX-T Manager:       ######')
    print('######                                                                                    ######')
    print('################################################################################################')
    print('')
    
    # Read the first arg of cli then pop this arg.
    sys.argv.pop(0)
    print ("\n==> CLI args :", str(sys.argv))
    
    # Mode menu (use menu path of CLI)
    if "menu" in args:
        sys.argv = args.menu
        sys.argv.append("exit")
    # Mode run (use YAML config file of CLI)
    if "run" in args:
        YAML_CFG_FILE = args.run
        # Ignore args in cli => use config yaml file.
        sys.argv = []
     # Mode interactive (do not use cli menu path if any)
    if args.interactive:
        sys.argv = []
    # Open and Treatment of YAML configuration file
    print("==> Read YAML config file: " + style.ORANGE + YAML_CFG_FILE + style.NORMAL)
    YAML_DICT = ReadYAMLCfgFile(YAML_CFG_FILE)
    # Check if all cert files are present and ask credential if not
    result = CheckCertFiles(YAML_DICT['CERT_PATH'])
    if result[0] != 0 and result[1] != 0:
        print(style.GREEN + "==> Found all certifications files needed (.crt and .key)"+style.NORMAL+"\n==> Trying to use certification authentication")
        ListAuth = auth_nsx(YAML_DICT['NSX_MGR_IP'],'CERT',result)
        if ListAuth[0] != 'Failed':
            print(style.GREEN + 'Successful authentication.' +style.NORMAL+ '\nGenerating output directory....')
            dest = CreateOutputFolder(YAML_DICT['OUTPUT_PATH'] + YAML_DICT['PREFIX_FOLDER'])
            print('Documentation output directory is: '+ style.ORANGE +  dest + style.NORMAL)
            time.sleep(1)
            result.append("CERT")
            # result is a list with cert, key and CERT
            # If using yaml file for automatic sub-menu navigation
            if 'MENU' in YAML_DICT and not args.interactive:
                # If multiple sub-menu navigation commands (list inside another list)
                if isinstance(YAML_DICT['MENU'][0], list):
                    for cur_nav_option in YAML_DICT['MENU']:
                        cur_nav_option.append('exit')
                        MainMenu(result,dest,cur_nav_option)
                else:
                    YAML_DICT['MENU'].append('exit')
                    MainMenu(result,dest,YAML_DICT['MENU'])
            else:
                MainMenu(result,dest,sys.argv)
        else:
            print(style.RED + 'Authentication with certificates failed.\n' + style.NORMAL)
            result = [0,0]
    else:
        print(style.RED + "==> Missing certifications files (.crt and .key)"+style.NORMAL+"\n==> Trying to normal authentication")

    if result[0] == 0 and result[1] == 0:
        print("==> Asking credential")
        print(style.GREEN + "==> Found NSX Manager IP or FQDN in yaml configuration file: " + style.ORANGE + YAML_DICT['NSX_MGR_IP'] + style.NORMAL)
        while True:
            ListAuth = auth_nsx(YAML_DICT['NSX_MGR_IP'],'AUTH',result)
            # Check if result is a HTTP Code (a int). If not, it a result in json
            if type(ListAuth[0]) == int or ListAuth[0] == 'Failed':
                print(style.RED + "\nIncorrect FQDN, Username or Password entered.  Please re-enter credentials:\n" + style.NORMAL)
            else:
                print(style.GREEN + "\nSuccessful authentication." + style.NORMAL + "\nGenerating output directory....\n")
                dest = CreateOutputFolder(YAML_DICT['OUTPUT_PATH'] + YAML_DICT['PREFIX_FOLDER'])
                print('Documentation output directory is: ' + style.ORANGE + dest + style.NORMAL)
                print('')
                time.sleep(1)
                result = [ListAuth[1][0],ListAuth[1][1], 'AUTH']
                break
        
        # If using yaml file for automatic sub-menu navigation
        if 'MENU' in YAML_DICT and not args.interactive:
            # If multiple sub-menu navigation commands (list inside another list)
            if isinstance(YAML_DICT['MENU'][0], list):
                for cur_nav_option in YAML_DICT['MENU']:
                    cur_nav_option.append('exit')
                    MainMenu(result,dest,cur_nav_option)
            else:
                YAML_DICT['MENU'].append('exit')
                MainMenu(result,dest,YAML_DICT['MENU'])
        else:
            MainMenu(result,dest,sys.argv)

if __name__ == "__main__":
    main()
