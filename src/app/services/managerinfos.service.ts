import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import {ClusterNSX, NSXManager, Service} from '../class/ClusterNSX'
import { ActivatedRoute } from '@angular/router';

@Injectable({
  providedIn: 'root'
})
export class ManagerinfosService {
  public mysession: LoginSession;

  Name = "Manager_Infos"
  Header = ['Group','Group Type','Group Status','Member FQDN','Member IP','Member UUID','Member Status', 'Diff Status']
  ConditionalFormating = {
    sheet: this.Name,
    column:   [
      {
      columnIndex:  this.Header.indexOf('Group Status') + 1,
      rules: [{
        color: 'green',
        text: 'STABLE'
      },
      {
        color: 'red',
        text: 'UNSTABLE'
      }]
      },
      {
      columnIndex:  this.Header.indexOf('Group Status') + 1,
      rules: [{
        color: 'green',
        text: 'STABLE'
      },
      {
        color: 'red',
        text: 'UNSTABLE'
      }]
      },
      {
      columnIndex:  this.Header.indexOf('Member Status') + 1,
      rules: [{
        color: 'green',
        text: 'UP'
      },
      {
        color: 'red',
        text: 'DOWN'
      }
      ]
      },
    ]
  }


  constructor(
    private session: SessionService,
  ) {
    this.mysession = SessionService.getSession()
   }

   formatDataExport(cluster: any, separator: string){
    let Tabline = []

    if (cluster[0].hasOwnProperty("services")){
      for (let svc of cluster[0].services){
        let TabMember_fqdn = []
        let TabMember_ip = []
        let TabMember_id = []
        let TabMember_status = []
 
        for (let member of svc.members){
         TabMember_fqdn.push(member.fqdn)
         TabMember_id.push(member.id)
         TabMember_ip.push(member.ip)
         TabMember_status.push(member.status)
        }
       Tabline.push({
         'group': svc.id,
         'group_type': svc.name, 
         'group_status': svc.status, 
         'member_fqdn': TabMember_fqdn.join(separator), 
         'member_ip': TabMember_ip.join(separator), 
         'member_uuid': TabMember_id.join(separator), 
         'member_status': TabMember_status.join(separator),
         'diffstatus': svc.diffstatus
       })
    }
    }
    return Tabline
  }

   async getClusterInfo(){
 
    let nsxclstr_json =  await this.session.getAPI(this.mysession, '/api/v1/cluster/status');
    let Cluster = new ClusterNSX(nsxclstr_json.cluster_id,nsxclstr_json.control_cluster_status.status, [], [])
    for (let svc of nsxclstr_json.detailed_cluster_status.groups){

      let SVCObj = new Service(svc.group_type)
      SVCObj.id = svc.group_id
      SVCObj.status = svc.group_status
      SVCObj.members = []
      for (let mb of svc.members){
        let MemberObj = new NSXManager(mb.member_uuid)        
        MemberObj.status = mb.member_status
        MemberObj.fqdn = mb.member_fqdn
        MemberObj.ip = mb.member_ip
        SVCObj.members.push(MemberObj)
      }
      Cluster.services.push(SVCObj)
    }
    return [Cluster]
   }

  async getData(separator: string): Promise<any>{
    return await this.getClusterInfo();
  }
}
