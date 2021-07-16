import { Injectable } from '@angular/core';
import { SessionService } from '../services/session.service';
import { LoginSession } from '../class/loginSession';
import { BGPSession } from '../class/BGPSession';

@Injectable({
  providedIn: 'root'
})
export class BgpService {
  public mysession: LoginSession;
  Header= ['T0 Router', 'BGP Status', 'ECMP', 'Inter-SR','Source IP Address', 'Local AS', 'Neighbor IP Address', 'Remote AS', 'Total IN Prefixes', 'Total OUT Prefixes', 'Session Status', 'Type', 'Diff Status' ]
  Name = 'BGP'
  ConditionalFormating = {
    sheet: this.Name,
    column: [{
      columnIndex:  this.Header.indexOf('Session Status') + 1,
      rules: [{
        color: 'red',
        text: 'ACTIVE'
      },
      {
        color: 'red',
        text: 'CONNECT'
      },
      {
        color: 'red',
        text: 'IDLE'
      },
      {
        color: 'green',
        text: 'ESTABLISHED'}]
    }]
  }
  constructor(
    private session: SessionService,
    ) { 
    this.mysession = SessionService.getSession()
    }

    formatDataExport(TabBGP: any, separator: string){
      let Tabline = []
      for( let bgp of TabBGP){
        Tabline.push({
          't0_name': bgp.t0_name,
          'bgp_status': bgp.bgp_status,
          'ecmp': bgp.ecmp,
          'ibgp': bgp.ibgp,
          'source_ip': bgp.source_ip,
          'local_as': bgp.local_as,
          'remote_ip': bgp.remote_ip,
          'remote_as': bgp.remote_as,
          'prefix_in': bgp.prefix_in,
          'prefix_out': bgp.prefix_out,
          'status': bgp.status,
          'type': bgp.type,
          'diffstatus': bgp.diffstatus
        })
      }
      return Tabline
    }

    async getBGPSession(): Promise<any>{
      let TabBGP = []
      let router_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-0s');
      if (router_json.result_count > 0){
        for (let rt of router_json.results){
  
          let local_service_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-0s/' + rt.id + "/locale-services");
          for (let local of local_service_json.results){
            const bgp =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-0s/' + rt.id + "/locale-services/" + local.id + "/bgp");
            const neighbors =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-0s/' + rt.id + "/locale-services/" + local.id + "/bgp/neighbors/status");
  
            let result = await Promise.all([bgp, neighbors])
            if(neighbors.results.length > 0){
              for(let session of neighbors.results){
                let BGPObj = new BGPSession(rt.display_name, session.source_address,bgp.local_as_num, session.neighbor_address, session.remote_as_number)
                BGPObj.status = session.connection_state
                BGPObj.type = session.type
                BGPObj.bgp_status = bgp.enabled
                BGPObj.ecmp = bgp.ecmp
                BGPObj.ibgp = bgp.inter_sr_ibgp
                BGPObj.prefix_in = session.total_in_prefix_count
                BGPObj.prefix_out = session.total_out_prefix_count
                TabBGP.push(BGPObj)
              }
            }
          }
        }
      }
      return TabBGP
    }

    async getData(separator: string): Promise<any> {
    // Get Data for audit
    let TabBGP= await this.getBGPSession()
    return TabBGP
    }
}
