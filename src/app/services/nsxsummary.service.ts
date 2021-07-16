import { Injectable } from '@angular/core';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { LoginSession } from '../class/loginSession';
import {TransportNode} from '../class/TransportNode'
import { NSXManager, Service} from '../class/ClusterNSX'


@Injectable({
  providedIn: 'root'
})
export class NsxsummaryService {
  public mysession: LoginSession;

  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  getNodeStatus(Tab: any){
    let Tabresult = []
    for(let nd of Tab){
      let TN = new TransportNode(nd.display_name)
      TN.host_node_deployment_status = nd.status.host_node_deployment_status
      TN.lcp_status = nd.status.lcp_connectivity_status
      TN.mpa_status = nd.status.mpa_connectivity_status
      TN.managementIp = nd.ip_addresses[0]
      if(nd.status.lcp_connectivity_status != 'UP' && nd.mpa_connectivity_status != 'UP'){
        TN.status = 'DOWN'
      }
      else{
        TN.status = 'UP'
      }
      Tabresult.push(TN)
    }
    return Tabresult
  }

  async getClusterStatus(): Promise<any>{
    let TabNSX = []

    let cluster_status_json =  await this.session.getAPI(this.mysession, '/api/v1/cluster/status')
    let cluster_json =  await this.session.getAPI(this.mysession, '/api/v1/cluster');
    let result = await Promise.all([cluster_status_json, cluster_json])

    // Create list of members
    for (let group of result[0]['detailed_cluster_status']['groups']){

      if (group.group_type == 'MANAGER'){
        for (let member of group['members']){
          let nsxmgr = new NSXManager(member.member_uuid)
          nsxmgr.fqdn = member.member_fqdn
          nsxmgr.ip = member.member_ip
          nsxmgr.status = member.member_status
          nsxmgr.services = []

          TabNSX.push(nsxmgr)
        }
     } 
    }
    for (let group of result[0]['detailed_cluster_status']['groups']){
      let SVCObj = new Service(group.group_type)
      SVCObj.id = group.group_id
      SVCObj.status = group.group_status

      for (let member of group['members']){
          for (let nsx of TabNSX){
            if (nsx.id == member.member_uuid){
              nsx.services.push(SVCObj)
            }
          }
      }
     }
    return [TabNSX, result[0], result[1]]
    }
  
  async getRouting(): Promise<any>{  
    let t0_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-0s');
    let t1_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-1s');
    let sg_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/segments');

    let result = await Promise.all([t0_json, t1_json, sg_json])

    return [result[0].result_count, result[1].result_count, result[2].result_count]
  }

  async getSecurity(): Promise<any>{
    let gp_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/domains/default/groups');
    let profiles_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/context-profiles');
    let services_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/services');

    let result = await Promise.all([gp_json, profiles_json, services_json])

    return [result[0].result_count, result[1].result_count, result[2].result_count]
  }

  async getNodes(): Promise<any>{
    let edge_cluster_json =  await this.session.getAPI(this.mysession, '/api/v1/edge-clusters');
    let edge_json =  await this.session.getAPI(this.mysession, '/api/v1/search/query?query=resource_type:Edgenode');
    let host_json =  await this.session.getAPI(this.mysession, '/api/v1/search/query?query=resource_type:Hostnode');

    let result = await Promise.all([edge_cluster_json, edge_json, host_json])

    return [result[0].result_count, result[1].result_count, result[2].result_count]
  }

}
