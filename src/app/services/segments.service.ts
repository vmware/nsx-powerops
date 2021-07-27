import { Injectable } from '@angular/core';
import { SessionService } from '../services/session.service';
import { LoginSession } from '../class/loginSession';
import { Segment, TZ } from '../class/Segment';

@Injectable({
  providedIn: 'root'
})
export class SegmentsService {
  public mysession: LoginSession;
  Header= ['Name', 'Type', 'Vlan', 'Subnet', 'Gateway', 'Attached to', 'Router Type','VNI', 'TZ Name', 'Replication Mode', 'Admin Status', 'Diff Status' ]
  HeaderDiff = [
    { header: 'Name', col: 'name'},
    { header: 'Type', col: 'type'},
    { header: 'Vlan', col: 'vlan'},
    { header: 'Subnet', col: 'subnets', subcol: 'network'},
    { header: 'Gateway', col: 'subnets', subcol: 'gateway_address'},
    { header: 'Attached to', col: 'connectedto'},
    { header: 'Router Type', col: 'routertype'},
    { header: 'VNI', col: 'vni'},
    { header: 'TZ Name', col: 'tz', subcol: 'name'},
    { header: 'Replication Mode', col: 'replication_mode'},
    { header: 'Admin Status', col: 'state'},
  ]
  
  Name = "Segments"
  ConditionalFormating = {
    sheet: this.Name,
    column:   [
      {
      columnIndex:  this.Header.indexOf('Admin Status') + 1,
      rules: [{
        color: 'green',
        text: 'UP'
      },
      {
        color: 'red',
        text: 'DOWN'
      }]
      }]
  }

  constructor(
    private session: SessionService,
    ) { 
    this.mysession = SessionService.getSession()
    }

  async getSegments(){
    let TabSegments: any[] = [];

    let tz_json =  this.session.getAPI(this.mysession, '/policy/api/v1/infra/sites/default/enforcement-points/default/transport-zones')
    let seg_json =  this.session.getAPI(this.mysession, '/policy/api/v1/infra/segments');
    let ls_json =  this.session.getAPI(this.mysession, '/api/v1/logical-switches');
    let lr_json =  this.session.getAPI(this.mysession, '/api/v1/logical-routers');

    let result = await Promise.all([seg_json, ls_json, tz_json, lr_json])
    if (result[0].result_count > 0){
      for (let seg of result[0].results) {
        let SegmentObj = new Segment(seg.display_name)
        SegmentObj.id = seg.unique_id
        SegmentObj.replication_mode = seg.replication_mode
        SegmentObj.resource_type = seg.resource_type
        SegmentObj.type = seg.type
        SegmentObj.state = seg.admin_state
        SegmentObj.subnets = [{ 'gateway_address': "", 'network': ""}]
        SegmentObj.tz = new TZ()

        if (seg.hasOwnProperty('transport_zone_path') ){
          let tz_id = seg.transport_zone_path.split('/')
          for (let tzone of result[2].results){
            if (tzone.id == tz_id[tz_id.length -1]) {
              SegmentObj.tz = new TZ(tzone.display_name, tzone.tz_type.split('_')[0])
              SegmentObj.tz.name = tzone.display_name
              SegmentObj.tz.type = tzone.tz_type.split('_')[0]
            }
          }
        }
        else{
          for(let ls of result[1].results){
            if (ls.id === seg.unique_id){
              for (let tzone of result[2].results){
                if (tzone.id == ls.transport_zone_id) {
                  SegmentObj.tz = new TZ(tzone.display_name, tzone.tz_type.split('_')[0])
                  SegmentObj.tz.name = tzone.display_name
                  SegmentObj.tz.type = tzone.tz_type.split('_')[0]
                }
              }
            }
          }
        }
        if (seg.hasOwnProperty('connectivity_path')){
          // Search Router Name
          for (let rtr of result[3].results){
            if(rtr.hasOwnProperty('tags')){
              for (let tg of rtr.tags){
                if(tg.tag == seg.connectivity_path){
                  SegmentObj.connectedto = rtr.display_name
                }
              }
            }
          }
          SegmentObj.routertype = seg.connectivity_path.split('/')[2]
        }
        if(seg.hasOwnProperty('advanced_config')){
          SegmentObj.connectivity = seg.advanced_config.connectivity
        }
        if (seg.hasOwnProperty('subnets')) { SegmentObj.subnets = seg.subnets }

        if (seg.hasOwnProperty('vlan_ids')) { SegmentObj.vlan = seg.vlan_ids }

        // get VNI
        for (let ls of result[1].results){
          if (seg.unique_id == ls.id && 'vni' in ls){
            SegmentObj.vni = ls.vni
          }
        }
        TabSegments.push(SegmentObj)
      }
    }
    return TabSegments
  }

  formatDataExport(TabSegments: any, separator: string){
    let Tabline = []
    for( let seg of TabSegments){
      //treatment multiple GW
      let gw = []
      let network = []
      for (let sub of seg.subnets){
        gw.push(sub.gateway_address)
        network.push(sub.network)
      }
      Tabline.push({
        'name': seg.name,
        'type': seg.tz.type,
        'vlan': seg.vlan.join(separator),
        'subnet': network.join(separator),
        'gw': gw.join(separator),
        'attachedto': seg.connectedto,
        'router_type': seg.routertype,
        'vni': seg.vni,
        'tz': seg.tz.name,
        'rep': seg.replication_mode,
        'status': seg.state,
        'diffstatus': seg.diffstatus
      })
    }
    return Tabline
  }

  async getData(separator: string) {
    // Get Data for audit
    return await this.getSegments()
  }
}
