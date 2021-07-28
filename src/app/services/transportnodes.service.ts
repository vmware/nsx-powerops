import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { TransportNode, HostSwitch, Interface, Profile, Teaming } from '../class/TransportNode'
import { TransportZone } from '../class/TransportZone';

@Injectable({
  providedIn: 'root'
})

export class TransportnodesService {
  public mysession: LoginSession;
  Name = "Tranport_Nodes"
  Header = [
    'Transport Node Name',
    'Type',
    'ID', 
    'Management IP', 
    'Switch Name',
    'Switch Mode', 
    'Switch Type',
    'Transport Zones',
    'Uplink Profile',
    'Teaming Policy',
    'Physical Interfaces',
    'Uplink Interfaces',
    'Active Interface',
    'Transport Vlan',
    'MTU',
    'Serial Number', 
    'FullVersion', 
    'Maintenance Mode', 
    'Deployement Status',
    'PowerState',
    'Diff Status'
  ]

  HeaderDiff = [
    { header: 'Transport Node Name', col: 'name'},
    { header: 'Type', col: 'type'},
    { header: 'ID', col: 'id'},
    { header: 'Management IP', col: 'managementIp'},
    { header: 'Switch Name', col: 'hostswitch', subcol: 'name'},
    { header: 'Switch Mode', col: 'hostswitch', subcol: 'mode'},
    { header: 'Switch Type', col: 'hostswitch', subcol: 'type'},
    { header: 'Transport Zones', col: 'TZ', subcol: 'name'},
    // { header: 'Uplink Profile', col: ''},
    // { header: 'Teaming Policy', col: ''},
    // { header: 'Physical Interfaces', col: ''},
    // { header: 'Uplink Interfaces', col: ''},
    // { header: 'Active Interface', col: ''},
    // { header: 'Transport Vlan', col: ''},
    { header: 'MTU', col: 'MTU'},
    { header: 'Serial Number', col: 'serialNumber'},
    { header: 'FullVersion', col: 'full_version'},
    { header: 'Maintenance Mode', col: 'inMaintenanceMode'},
    { header: 'Deployement Status', col: 'host_node_deployment_status'},
    { header: 'PowerState', col: 'powerState'}
  ]

  ConditionalFormating = {
    sheet: this.Name,
    column: [
      {
      columnIndex:  this.Header.indexOf('Deployement Status') + 1,
      rules: [{
        color: 'green',
        text: 'INSTALL_SUCCESSFUL'
      },
      {
        color: 'red',
        text: 'prepped'
      }]
      },
      {
      columnIndex:  this.Header.indexOf('PowerState') + 1,
      rules: [{
        color: 'green',
        text: 'poweredOn'
      },
      {
        color: 'red',
        text: 'Unknown'
      }
      ]
      },
    ]
  }
  
  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  formatDataExport(Tab: any[], separator: string){
    let Tabline = []
    for( let tn of Tab){
      let TabSWName = []
      let TabSWMode = []
      let TabSWType = []
      let TabSWpnics = []
      let TabSWuplinks = []
      let TabSWProfileName = []
      let TabSWMTU = []
      let TabSWTransportVLAN = []
      let TabSWActiveInterface = []
      let TabSWTeamingPolicy = []

      tn.hostswitch.forEach((sw: any) => {
        TabSWName.push(sw.name)
        TabSWMode.push(sw.mode)
        TabSWType.push(sw.type)
        if ('profile' in sw){
          TabSWProfileName.push(sw.profile.name)
          TabSWTeamingPolicy.push(sw.profile.teaming.policy)
          TabSWMTU.push(sw.profile.mtu)
          TabSWTransportVLAN.push(sw.profile.transport_vlan)
          sw.profile.teaming.active_list.forEach((acint: any) => {
            TabSWActiveInterface.push(acint.device_name)
          });
        }
        else{
          TabSWProfileName.push("")
          TabSWTeamingPolicy.push("")
          TabSWMTU.push("")
          TabSWTransportVLAN.push("")
          TabSWActiveInterface.push("")
        }
        sw.pnics.forEach((pnic: any) => {
          TabSWpnics.push(pnic.device_name)
        });

        sw.uplinks.forEach((uplink: any) => {
          TabSWuplinks.push(uplink.uplink_name)
        });
      });

      let TabTZ= []
      tn.TZ.forEach((tz: { name: string; }) => {
        TabTZ.push(tz.name)
      });

      Tabline.push({
        'Transport Node Name': tn.name,
        'Type': tn.type,
        'ID': tn.id, 
        'Management IP': tn.managementIp, 
        'Switch Name': TabSWName.join(separator),
        'Switch Mode': TabSWMode.join(separator), 
        'Switch Type': TabSWType.join(separator),
        'Transport Zones': TabTZ.join(separator),
        'Uplink Profile': TabSWProfileName.join(separator),
        'Teaming Policy': TabSWTeamingPolicy.join(separator),
        'Physical Interfaces': TabSWpnics.join(separator),
        'Uplink Interfaces': TabSWuplinks.join(separator),
        'Active Interface': TabSWActiveInterface.join(separator),
        'Transport Vlan': TabSWTransportVLAN.join(separator),
        'MTU': TabSWMTU.join(separator),
        'Serial Number': tn.serialNumber, 
        'FullVersion': tn.full_version, 
        'Maintenance Mode': tn.inMaintenanceMode, 
        'Deployement Status': tn.host_node_deployment_status,
        'PowerState': tn.powerState,
        'Diff Status': tn.diffstatus
      })
    }
    return Tabline
  }

  getTZInfo(tz: any){
    let TZObj = new TransportZone(tz.id,tz.display_name,tz.transport_type)
    TZObj.default = tz.is_default
    TZObj.nested = tz.nested_nsx
    TZObj.description = tz.description
    TZObj.resource_type = tz.resource_type
    if ('uplink_teaming_policy_names' in tz){ TZObj.uplink_teaming_policy_names = tz.uplink_teaming_policy_names}
    return TZObj
  }

  getDetail(TN: any, TNObj: any, tz_json: { results: any; }, status_json: { results: any; }, up_json: { results: any; }){
    TNObj.inMaintenanceMode = TN.maintenance_mode
    TNObj.type = TN.node_deployment_info.resource_type
    if ('os_type' in TN.node_deployment_info){
      TNObj.full_version = TN.node_deployment_info.os_type + '-' + TN.node_deployment_info.os_version
    }
    else{
      TNObj.full_version = ""
    }
    TNObj.id = TN.id
    TNObj.host_node_deployment_status = 'Unknown'
    TNObj.ipaddresses = TN.node_deployment_info.ip_addresses
    // Treatment Transport Zone
    for (let tz of tz_json.results){
        TN.transport_zone_endpoints.forEach((tz_element: { transport_zone_id: any; }) => {
          if (tz_element.transport_zone_id == tz.id){
            let TZObj = this.getTZInfo(tz)
            TNObj.TZ.push(TZObj)
          }
        });
    }
     // Deployment status       
    for (let st_node of status_json.results){
      if(TN.id == st_node.id){
        TNObj.host_node_deployment_status = st_node.status.host_node_deployment_status
      }
    }
    // Treatment of HostSwitch
    for (let sw of TN.host_switch_spec.host_switches){
        // Check if TZ already there
        if(TNObj.TZ.length == 0){
          for (let tz of tz_json.results){
          sw.transport_zone_endpoints.forEach((tz_element: { transport_zone_id: any; }) => {
            if (tz_element.transport_zone_id == tz.id){
              let TZObj = this.getTZInfo(tz)
              TNObj.TZ.push(TZObj)
              }
            })
          }
        }
        let HostSwitchObj = new HostSwitch(sw.host_switch_id, sw.host_switch_name, sw.host_switch_mode)
        HostSwitchObj.type = sw.host_switch_type
        // uplink and interfaces
        HostSwitchObj.uplinks = []
        if ('uplinks' in sw){
          for (let upl of sw.uplinks){
            HostSwitchObj.uplinks.push(new Interface(upl.vds_uplink_name,upl.uplink_name))
          }
        }
        HostSwitchObj.pnics = []
        for (let int of sw.pnics){
          let IntObj = new Interface(int.device_name, int.uplink_name)
          HostSwitchObj.pnics.push(IntObj)
        }
        // Treatment of Switch Profile
        for (let switch_pr of sw.host_switch_profile_ids){
          // HostSwitchObj.profile = new Profile("")
          for ( let profile of up_json.results) {
            if (switch_pr.value === profile.id ){
              HostSwitchObj.profile = new Profile(profile.display_name)
              HostSwitchObj.profile.id = profile.id
              if ('mtu' in profile) {      
                HostSwitchObj.profile.mtu = profile.mtu
              }
              else{
                HostSwitchObj.profile.mtu = 0
              }
              HostSwitchObj.profile.encap = profile.encap
              HostSwitchObj.profile.resource_type = profile.resource_type
              HostSwitchObj.profile.transport_vlan = profile.transport_vlan
              HostSwitchObj.profile.teaming = new Teaming(profile.teaming.policy)
              HostSwitchObj.profile.teaming.active_list = []
              HostSwitchObj.profile.teaming.secondary_list = []

              for (let team_int of profile.teaming.active_list){
                if (HostSwitchObj.pnics.length > 0){
                  for (let int of HostSwitchObj.pnics){
                    if (int.uplink_name == team_int.uplink_name){
                      HostSwitchObj.profile.teaming.active_list.push(int)
                    }
                  }
                }
                else{
                  for (let upl of HostSwitchObj.uplinks){
                    if (upl.uplink_name == team_int.uplink_name){
                      HostSwitchObj.profile.teaming.active_list.push(upl)
                    }
                  }
                }

              }
            }
          }
        }

        TNObj.hostswitch.push(HostSwitchObj)
    }
    if (TNObj.managementIp == "" && TNObj.ipaddresses.length == 1){
      TNObj.managementIp = TNObj.ipaddresses[0]
    }
    return TNObj
  }

  async getTN(){
    let TabTN = []
    const tn_json = await this.session.getAPI(this.mysession, "/api/v1/transport-nodes")
    const disc_node_json = await this.session.getAPI(this.mysession, '/api/v1/fabric/discovered-nodes')

    const tz_json =  await this.session.getAPI(this.mysession, "/api/v1/transport-zones");
    const url_two = '/policy/api/v1/search?query=_exists_:resource_type%20AND%20!_exists_:nsx_id%20AND%20!_create_user:nsx_policy%20AND%20resource_type:HostNode&page_size=50&cursor=&data_source=INTENT&exclude_internal_types=true'
    const status_json =  await this.session.getAPI(this.mysession, url_two);
    const up_json =  await this.session.getAPI(this.mysession, "/api/v1/host-switch-profiles");

    let result = await Promise.all([tn_json, disc_node_json, tz_json, status_json, up_json])

    // Loop on Discovered Node
    if (result[1].result_count >0){
      for (let dc of result[1].results){
        // create of TN Object
        let DNObj = new TransportNode(dc.display_name)
        DNObj.type = dc.node_type
        DNObj.external_id = dc.external_id
        DNObj.id = dc.external_id
        DNObj.managementIp = ""
        DNObj.MTU = 0
        // DNObj.TransportVlan = "Unknown"
        DNObj.ipaddresses = []
        DNObj.host_node_deployment_status = "Non prepped NSX-T Host"
        DNObj.TZ = []
        DNObj.hostswitch = []

        for (let propertie of dc.origin_properties){
          if (propertie.key == 'managementIp') { DNObj.managementIp = propertie.value}
          if (propertie.key == 'powerState') { DNObj.powerState = propertie.value}
          if (propertie.key == 'inMaintenanceMode') { DNObj.inMaintenanceMode = propertie.value}
          if (propertie.key == 'fullName') { DNObj.full_version = propertie.value}
          if (propertie.key == 'serialNumber') { DNObj.serialNumber = propertie.value}
        }
        TabTN.push(DNObj)
      }
    }
    // Adding informations from TN API
    if(result[0].result_count >0){
      for (let tn of result[0].results){
        //Search in TabTN if Node already existing
        if ((TabTN.find(x => x.external_id === tn.node_deployment_info.discovered_node_id) == undefined) || !('discovered_node_id' in tn.node_deployment_info)){
              let TNObj = new TransportNode(tn.display_name)
              TNObj.managementIp = ""
              TNObj.powerState = 'Unknown'
              TNObj.TZ = []
              TNObj.hostswitch = []
              TabTN.push(this.getDetail(tn,TNObj, tz_json, status_json, up_json))
        }
        else{
              for (let TN of TabTN){
                if (TN.external_id ==  tn.node_deployment_info.discovered_node_id){
                  let tnobj_mod = this.getDetail(tn,TN, tz_json, status_json, up_json)
                }
              }
        }
      }
    }
    return TabTN
  }

  async getData(separator: string): Promise<any>{
    return await this.getTN();
  }
}