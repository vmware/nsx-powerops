#!/usr/bin/env python
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
import requests
import urllib3
import getpass
from pathlib import Path
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from sys import platform
import sys, getopt, os, datetime
import yaml
import requests
from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

YAML_CFG_FILE = 'config.yml'

class style:
    RED = '\33[31m'
    ORANGE = '\33[33m'
    GREEN = '\33[32m'
    NORMAL = '\033[0m'

def CreateOutputFolder(PATH):
    """
    CreateOutputFolder(PATH)
    Create Folder for Excel Files
    Returns
    ----------
    Return the output excel files path
    Args
    ----------
    PATH : str
        path where the folder of output Excel files must take place.
    """
    global XLS_dest
    now = datetime.datetime.today() 
    nTime = now.strftime("%d-%m-%Y-%H-%M-%S")
    XLS_dest = os.path.join(PATH+nTime)
        
    if not os.path.exists(XLS_dest):
        os.makedirs(XLS_dest) #create destination dir
    
    return XLS_dest

def auth_nsx(nsx_mgr_fqdn,authmethod,cert):
    """
    AuthNSX(IP, authMethod, Cert)
    Realize a connection to NSX. Try to connect with cert files or normal Authentication
    Returns
    ----------
    Return a list with the HTTP Code of the response, a list of login/password in case of normal authentication or a list containing cert path and key path
    Args
    ----------
    IP : str
        IP or FQDN of NSx Manager
    authMethod : str
        AUTH or CERT
    cert : list
        list with cert and key files path
    """
    url_test = '/api/v1/node'

    if authmethod == 'AUTH':
        # Capture credential inputs
        username = input('Enter NSX-T Manager Username: ')
        password = getpass.getpass(prompt='Enter NSX Manager password: ') #Note password not displayed on screen
        auth_list = [username,password,authmethod]
    else:
        auth_list = [cert[0],cert[1],authmethod]

    try:
        SessionNSX = ConnectNSX(auth_list)
        req = GetAPI(SessionNSX[0],url_test, auth_list,'NOJSON')
        response = [str(req), auth_list]
    except:
        response = ['Failed',[]]
        quit

    return response


def GetAPI(session,url, auth_list, resp_type = ''):
    """
    GetAPI(session, url, auth_list, reponse_type)
    Realize a get in REST/API depending if wants a Json reponse, with authentication with certification or login
    Parameters
    ----------
    session : object
        session obejct created by ConnectNSX
    url : str
        URL of the request without protocol and IP/FQDN
    auth_list : list
        list with authentication parameters (login/cert, password/key, AUTH or CERT)
    response_type: str
        NOJSON must be used for a REST/API request which return no Json response
    """
    YAML_DICT = ReadYAMLCfgFile(YAML_CFG_FILE)
    if resp_type == 'NOJSON':
        if auth_list[2] == 'AUTH':
            return session.get('https://' + YAML_DICT['NSX_MGR_IP'] + str(url), auth=(auth_list[0], auth_list[1]), verify=session.verify)
        if auth_list[2] == 'CERT':
            return requests.get('https://' + YAML_DICT['NSX_MGR_IP'] + str(url), headers={'Content-type': 'application/json'}, cert=(auth_list[0], auth_list[1]), verify=session.verify)
    else:
        if auth_list[2] == 'AUTH':
            return session.get('https://' + YAML_DICT['NSX_MGR_IP'] + str(url), auth=(auth_list[0], auth_list[1]), verify=session.verify).json()
        if auth_list[2] == 'CERT':
            return requests.get('https://' + YAML_DICT['NSX_MGR_IP'] + str(url), headers={'Content-type': 'application/json'}, cert=(auth_list[0], auth_list[1]), verify=session.verify).json()


def ConnectNSX(auth_list):
    """
    ConnectNSX(list)
    Connection function to NSX. Can be by certifcates or by authentication.

    Returns
    ----------
    list with session object and connector object    
    Args
    ----------
    auth : list
        list must contain login/cert - password/key - Tag (AUTH or CERT)
    """
    YAML_DICT = ReadYAMLCfgFile(YAML_CFG_FILE)
    if auth_list[2] == 'AUTH':
        session = requests.session()
        session.verify = False
        connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + YAML_DICT['NSX_MGR_IP'])
        security_context = create_user_password_security_context(auth_list[0], auth_list[1])
        connector.set_security_context(security_context)
        return [session,connector]
    elif auth_list[2] == 'CERT':
        session = requests.session()
        session.verify = False
        session.cert = (auth_list[0], auth_list[1])
        connector = connect.get_requests_connector(session=session, msg_protocol='rest', url='https://' + YAML_DICT['NSX_MGR_IP'])
        return [session,connector]
    else:
        print("Issue on authentication")
        exit(1)


def CheckCertFiles(PATH):
    """
    CheckCertFile(YAML_CFG_FILE)
    Check if Cert files are present
    Returns
    ----------
    List with certification file path and key file path or 0,0    
    Parameters
    ----------
    PATH : Str
        Path of Cert files
    """
    TAG = [0,0]
    for fname in os.listdir(PATH):
        if Path(fname).suffix == '.crt':
            print("==> Found .crt file: \x1b[0;33;40m%s\x1b[0m" % fname)
            TAG[0] = PATH + os.path.pathsep + fname
        if Path(fname).suffix == '.key':
            print("==> Found .key file: \x1b[0;33;40m%s\x1b[0m" % fname)
            TAG[1] = PATH + os.path.pathsep + fname
    
    return TAG
        

def ReadYAMLCfgFile(YAML_CFG_FILE):
    """
    ReadYAMLCfgFile(YAML_CFG_FILE)
    Read a YAML File and return Dictionnary
    Return
    ----------
    Dictionnary of Yaml information
    Parameters
    ----------
    YAML_CFG_FILE : Str
        Name of YAML file
    """
    # Open and treatment of a YAML config file
    try:
        with open(YAML_CFG_FILE, 'r') as ymlfile:
            YAML_DICT = yaml.load(ymlfile, Loader=yaml.FullLoader)
            return YAML_DICT
    except Exception as e:
        print("File %s not found in INPUT directory" % (YAML_CFG_FILE))
        print(e)
        sys.exit(1)


