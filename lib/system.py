#!/usr/bin/env python
# coding: utf-8
#
import requests
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from sys import platform
import sys, getopt, os
import yaml
import requests
from vmware.vapi.lib import connect
from vmware.vapi.security.user_password import \
        create_user_password_security_context

YAML_CFG_FILE = 'config.yml'

def GetAPI(session,url, auth_list, resp_type = ''):
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
    Parameters
    ----------
    PATH : Str
        Path of Cert files
    """
    TAG = [0,0]
    for fname in os.listdir(PATH):
        if fname.endswith('.crt'):
            print("Found .crt file: %s" % fname)
            TAG[0] = PATH + '/' + fname
        if fname.endswith('.key'):
            print("Found .key file: %s" % fname)
            TAG[1] = PATH + '/' + fname
    
    return TAG
        

def ReadYAMLCfgFile(YAML_CFG_FILE):
    """
    ReadYAMLCfgFile(YAML_CFG_FILE)
    Read a YAML File and return Dictionnary
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


