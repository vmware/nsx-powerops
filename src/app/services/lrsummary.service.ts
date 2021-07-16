import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { Router } from '../class/Router'

@Injectable({
  providedIn: 'root'
})
export class LrsummaryService {
  public mysession: LoginSession;
  Header= ['Name', 'ID', 'Edge Cluster Name', 'Edge Cluster ID','LR Type', 'HA Mode', 'Admin Failover Mode','Relocation', 'Diff Status' ]
  Name = 'LR_Summary'

  constructor(
    private session: SessionService,
  ) {
    this.mysession = SessionService.getSession()
   }

   async getLR(): Promise<any>{

    let lr_json =  await this.session.getAPI(this.mysession, '/api/v1/logical-routers');
    let ec_json =  await this.session.getAPI(this.mysession, '/api/v1/edge-clusters');
    let result = await Promise.all([lr_json, ec_json])

    let TabLR = []
    if (result[0].result_count > 0){
      for (let lr of result[0].results){
        let RouterObj = new Router(lr.display_name)
        RouterObj.id = lr.id
        RouterObj.type = lr.router_type,
        RouterObj.hamode = lr.high_availability_mode,
        RouterObj.failover = lr.failover_mode,
        RouterObj.relocation = lr.allocation_profile.enable_standby_relocation
        RouterObj.cluster_id = ""
        RouterObj.cluster_name = ""
        if (result[1].result_count > 0){
          for(let cl of result[1].results){
            if (cl.id == lr.edge_cluster_id){
              RouterObj.cluster_id = cl.id
              RouterObj.cluster_name = cl.display_name
            }
          }
        }
        TabLR.push(RouterObj)
      }
    }
    return TabLR
   }

   formatDataExport(TabLR: any, separator: string){
    let Tabline = []
    for( let lr of TabLR){
      Tabline.push({
        'name': lr.name,
        'id': lr.id,
        'cl_name': lr.cluster_name,
        'cl_ID': lr.cluster_id,
        'type': lr.type,
        'ha': lr.hamode,
        'failover': lr.failover,
        'relocation': lr.relocation,
        'diffstatus': lr.diffstatus
      })
    }
    return Tabline
   }

   async getData(separator: string): Promise<any> {
    // Get Data for audit
    return await this.getLR()
  }
}
