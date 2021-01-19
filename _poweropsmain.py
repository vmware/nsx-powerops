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

YAML_CFG_FILE = 'config.yml'

def main():
    print('')
    print('')
    print('################################################################################################')
    print('######                                                                                    ######')
    print('######    Hello & welcome to NSX-T PowerOps.  Please authenticate to NSX-T Manager:       ######')
    print('######                                                                                    ######')
    print('################################################################################################')
    print('')
    # Open and Treatment of YAML configuration file
    print("\n==> Read YAML config file: " + style.ORANGE + YAML_CFG_FILE + style.NORMAL)

    YAML_DICT = ReadYAMLCfgFile(YAML_CFG_FILE)
    # Check if all cert files are present and ask credential if not
    result = CheckCertFiles(YAML_DICT['CERT_PATH'])
    if result[0] != "" and result[1] != "":
        print(style.GREEN + "==> Found all certifications files needed (.crt and .key)"+style.NORMAL+"\n==> Trying to use certification authentication")
        ListAuth = auth_nsx(YAML_DICT['NSX_MGR_IP'],'CERT',result)
        if ListAuth[0] != 'Failed':
            print(style.GREEN + 'Successful authentication.' +style.NORMAL+ '\nGenerating output directory....')
            dest = CreateOutputFolder(YAML_DICT['OUTPUT_PATH'] + YAML_DICT['PREFIX_FOLDER'])
            print('Documentation output directory is: '+ style.ORANGE +  dest + style.NORMAL)
            time.sleep(1)
            result.append("CERT")
            # result is a list with cert, key and CERT
            MainMenu(result,dest)
        else:
            print(style.RED + 'Authentication with certificates failed.\n' + style.NORMAL)
            result[0] = ""
            result[1] = ""

    if result[0] == "" and result[1] == "":
        print("==> Asking credential")
        print(style.GREEN + "==> Found NSX Manager IP or FQDN in yaml configuration file: " + style.ORANGE + YAML_DICT['NSX_MGR_IP'] + style.NORMAL)
        response = ""
        while response != '<Response [200]>':
            ListAuth = auth_nsx(YAML_DICT['NSX_MGR_IP'],'AUTH',result)
            response = ListAuth[0]
            if response != '<Response [200]>':
                print(style.RED + "\nIncorrect FQDN, Username or Password entered.  Please re-enter credentials:\n" + style.NORMAL)
            else: 
                print(style.GREEN + "\nSuccessful authentication." + style.NORMAL + "\nGenerating output directory....\n")
                dest = CreateOutputFolder(YAML_DICT['OUTPUT_PATH'] + YAML_DICT['PREFIX_FOLDER'])
                print('Documentation output directory is: ' + style.ORANGE + dest + style.NORMAL)
                print('')
                time.sleep(1)
                result = [ListAuth[1][0],ListAuth[1][1], 'AUTH']
                # result is a list with login, password and AUTH
                MainMenu(result, dest)

if __name__ == "__main__":
    main()
