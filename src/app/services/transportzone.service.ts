import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { TransportZone } from '../class/TransportZone';
import { HostSwitch } from '../class/TransportNode';

@Injectable({
  providedIn: 'root'
})
export class TransportzoneService {
  public mysession: LoginSession;
  Header= ['Name', 'Description', 'ID', 'Ressource Type','Host Switch Name', 'Host Switch ID', 'Host Switch Mode', 'Host Switch Default','is Default','is Nested NSX', 'Transport Type', 'Uplink Teaming Policy' ]
  HeaderDiff = [
    { header: 'Name', col: 'name'},
    { header: 'Description', col: 'description'},
    { header: 'ID', col: 'id'},
    { header: 'Ressource Type', col: 'resource_type'},
    { header: 'Host Switch Name', col: 'hostswitch', subcol: 'name'},
    { header: 'Host Switch ID', col: 'hostswitch', subcol: 'id'},
    { header: 'Host Switch Mode', col: 'host_switch_mode'},
    { header: 'Host Switch Default', col: 'hostswitch', subcol: 'type'},
    { header: 'is Default', col: 'default'},
    { header: 'is Nested NSX', col: 'nested'},
    { header: 'Transport Type', col: 'type'},
    { header: 'Uplink Teaming Policy', col: 'uplink_teaming_policy_names'}
  ]
  Name = 'Transport_Zones'

  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }
  
  formatDataExport(Tab: any[], separator: string){
    let Tabline = []
    for( let tz of Tab){
      let teaming = ""
      if ('uplink_teaming_policy_names' in tz){
        teaming = tz.uplink_teaming_policy_names.join(', ')
      }
      Tabline.push({
        'name': tz.name,
        'description': tz.description,
        'id': tz.id,
        'resource_type': tz.resource_type,
        'host_swithc_id': tz.hostswitch.id,
        'host_switch_mode': tz.hostswitch.mode,
        'host_switch_name': tz.hostswitch.name,
        'is_default': tz.default,
        'nested': tz.nested,
        'type': tz.transport_type,
        'teaming': teaming,
        'diffstatus': tz.diffstatus
      })
    }
    return Tabline
  }

  async getTransportZones(){
    let TabTZ = []
    let tz_json =  await this.session.getAPI(this.mysession, "/api/v1/transport-zones");
    if (tz_json.result_count > 0){
      for (let tz of tz_json.results){
        let TZObj = new TransportZone(tz.id, tz.display_name, tz.transport_type)
        TZObj.default = tz.is_default
        TZObj.nested = tz.nested_nsx
        if ('description' in tz){
          TZObj.description = tz.description
        } 
        TZObj.host_switch_id = tz.host_switch_id
        TZObj.host_switch_mode = tz.host_switch_mode
        TZObj.host_switch_name = tz.host_switch_name
        TZObj.hostswitch = new HostSwitch(tz.host_switch_id, tz.host_switch_name, tz.host_switch_mode)
        TZObj.resource_type = tz.resource_type
        if ('uplink_teaming_policy_names' in tz){ TZObj.uplink_teaming_policy_names = tz.uplink_teaming_policy_names}
        TabTZ.push(TZObj)
      }
    }
    return TabTZ
  }

  async getData(): Promise<any>{
    return await this.getTransportZones();
  }
}
