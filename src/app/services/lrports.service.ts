import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { Port } from '../class/Port'

@Injectable({
  providedIn: 'root'
})
export class LrportsService {
  public mysession: LoginSession;
  Header= ['LR Port Name', 'ID', 'Attachment Type', 'Attachment ID', 'Logical Router Name', 'Logical Router ID','Segment Name', 'Segment ID', 'Create User', 'Admin State', 'Status', 'Diff Status' ]
  Name = 'LR_Ports'
  HeaderDiff = [
    { header: 'LR Port Name', col: 'name'},
    { header: 'ID', col: 'id'},
    { header: 'Attachment Type', col: 'attachment_type'},
    { header: 'Attachment ID', col: 'attachment_id'},
    { header: 'Logical Router Name', col: 'router_name'},
    { header: 'Logical Router ID', col: 'router_id'},
    { header: 'Segment Name', col: 'segment_name'},
    { header: 'Segment ID', col: 'segment_id'},
    { header: 'Create User', col: 'createdby'},
    { header: 'Admin State', col: 'state'},
    { header: 'Status', col: 'status'},
  ]
  
  ConditionalFormating = {
    sheet: this.Name,
    column:   [
      {
      columnIndex:  this.Header.indexOf('Admin State') + 1,
      rules: [{
        color: 'red',
        text: 'DOWN'
      },
      {
        color: 'green',
        text: 'UP'
      }]
      },
      {
      columnIndex:  this.Header.indexOf('Status') + 1,
      rules: [{
        color: 'green',
        text: 'UP'
      },
      {
        color: 'red',
        text: 'DOWN'
      }]
      },
    ]
  }

  constructor(
    private session: SessionService,
  ) {
    this.mysession = SessionService.getSession()
   }

   formatDataExport(TabPorts: any, separator: string){
    let Tabline = []
    for( let lr of TabPorts){
      Tabline.push({
        'name': lr.name,
        'id': lr.id,
        'attachment_type': lr.attachment_type,
        'attachment_id': lr.attachment_id,
        'lr_name': lr.router_name,
        'lr_id': lr.router_id,
        'seg_name': lr.segment_name,
        'seg_id': lr.segment_id,
        'createdby': lr.createdby,
        'state': lr.state,
        'status': lr.status,
        'diffstatus': lr.diffstatus
      })
    }
    return Tabline
  }

  async getLRPorts(): Promise<any>{
    let TabPorts = []
    let portsdown_json =  await this.session.getAPI(this.mysession, '/api/v1/search/query?query=resource_type:LogicalRouterDownLinkPort');
    let ports_json =  await this.session.getAPI(this.mysession, '/api/v1/search/query?query=resource_type:LogicalPort');
    let router_json =  await this.session.getAPI(this.mysession, '/api/v1/logical-routers');
    let switch_json = await this.session.getAPI(this.mysession, '/api/v1/logical-switches');

    let result = await Promise.all([ports_json, portsdown_json, router_json, switch_json])

    if (result[0].result_count > 0){
      for (let port of result[0].results){
        let PortObj = new Port(port.display_name)
        PortObj.id = port.id
        PortObj.segment_name =""
        PortObj.router_name = ""
        PortObj.router_id = ""
        PortObj.attachment_id = ""
        PortObj.attachment_type = ""
        PortObj.segment_id =  port.logical_switch_id,
        PortObj.createdby =  port._create_user,
        PortObj.state =  port.admin_state, 
        PortObj.status =  port.status.status

        if ('attachment' in port){
          PortObj.attachment_type = port.attachment.attachment_type;
          PortObj.attachment_id = port.attachment.id;
        }

        for (let ls of result[3].results){
          if (ls.id == port.logical_switch_id){
            // Get Segment Name
            PortObj.segment_name = ls.display_name;
            for (let lrdown of result[1].results){
              if (lrdown.linked_logical_switch_port_id){
                if (port.id == lrdown.linked_logical_switch_port_id.target_id){
                  for (let router of result[2].results){
                    if (lrdown.logical_router_id == router.id){
                      // Get Router Name and ID
                      PortObj.router_name = router.display_name
                      PortObj.router_id = router.id
                    }
                  }
                }
              }
            }
          }
        }
        TabPorts.push(PortObj)
      }
    }
    return TabPorts
  }

  async getData(): Promise<any> {
    // Get Data for audit
    return await this.getLRPorts()
  }
}
