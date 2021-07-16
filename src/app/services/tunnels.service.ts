import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { Tunnel } from '../class/Tunnel'
import { TransportNode } from '../class/TransportNode'

@Injectable({
  providedIn: 'root'
})
export class TunnelsService {
  public mysession: LoginSession;
  Header= ['Transport Node', 'Tunnel Name', 'Tunnel Status', 'Egress Interface', 'Local IP', 'Remote IP', 'Remote Node ID', 'Remote Node Name', 'Encap', 'Diff Status' ]
  Name = 'Tunnels'
  ConditionalFormating = {
    sheet: this.Name,
    column:   [{
      columnIndex:  this.Header.indexOf('Tunnel Status') + 1,
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
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  formatDataExport(Tab: any[], separator: string){
    let Tabline = []
    for( let tunnel of Tab){
      Tabline.push({
        'node': tunnel.node.name,
        'name': tunnel.name,
        'status': tunnel.status,
        'egress_int': tunnel.egress_int,
        'local_ip': tunnel.local_ip,
        'remote_ip': tunnel.remote_ip,
        'remote_node_id': tunnel.remote_node_id,
        'remote_node_display_name': tunnel.remote_node_display_name,
        'encap': tunnel.encap,
        'diffstatus': tunnel.diffstatus
      })
    }
    return Tabline
  }

  async getTransportNodes(){
    let TabTN = []
    const transport_node_json =  await this.session.getAPI(this.mysession, '/api/v1/transport-nodes');
    if (transport_node_json.result_count > 0){
      for (let node of transport_node_json.results){
        let TN = new TransportNode(node.display_name)
        TN.id = node.id
        TabTN.push(TN)
      }
    }
    return TabTN
  }

  async getTunnels(Node: any){
    let TabTunnels: any[] = [];
    const tunnel_json =  await this.session.getAPI(this.mysession, '/api/v1/transport-nodes/' + Node.id + '/tunnels');
    if (tunnel_json.result_count > 0){
      for (let tunnel of tunnel_json.tunnels){
        let TunnelObj = new Tunnel(tunnel.name)
        TunnelObj.node = Node
        TunnelObj.status = tunnel.status
        TunnelObj.egress_int = tunnel.egress_interface
        TunnelObj.local_ip = tunnel.local_ip
        TunnelObj.remote_ip = tunnel.remote_ip
        TunnelObj.remote_node_display_name = tunnel.remote_node_display_name
        TunnelObj.remote_node_id = tunnel.remote_node_id
        TunnelObj.encap = tunnel.encap
        TabTunnels.push(TunnelObj)
      }
    }
    return TabTunnels
  }

  async getData(): Promise<any>{
    let TabTunnels = []
    let TabTN = await this.getTransportNodes()
    for(let tn of TabTN){
      let tmp = await this.getTunnels(tn)
      TabTunnels =TabTunnels.concat(tmp)
    }
    return TabTunnels
  }
}
