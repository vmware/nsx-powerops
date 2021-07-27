import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { Node, EdgeCluster} from '../class/Node'
import { Route } from '../class/Router'

@Injectable({
  providedIn: 'root'
})
export class RoutingtablesService {
  public mysession: LoginSession;

  Header= ['Router Name', 'Edge Node Name', 'Edge Node ID', 'Edge Node Status', 'Route Type', 'Network', 'Admin Distance', 'Next Hop', 'Router Component ID', 'Router Component Type', 'Router HA', 'Diff Status' ]
  Name = "Routing_Table"
  HeaderDiff = [
    { header: 'Router Name', col: 'router'},
    { header: 'Edge Node Name', col: 'node_name'},
    { header: 'Edge Node ID', col: 'node_id'},
    { header: 'Edge Node Status', col: 'node_status'},
    { header: 'Route Type', col: 'type'},
    { header: 'Network', col: 'network'},
    { header: 'Admin Distance', col: 'admin_distance'},
    { header: 'Next Hop', col: 'gateway'},
    { header: 'Router Component ID', col: 'router_id'},
    { header: 'Router Component Type', col: 'router_type'},
  ]

  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  formatDataExport(Table: any){
    let Tabline = []
    if( Table.length > 0){
      for ( let route of Table){
        Tabline.push({
          router: route.router,
          node_name: route.node_name,
          node_id: route.node_id,
          node_status: route.node_status,
          type: route.type,
          network: route.network,
          admin_distance: route.admin_distance,
          gateway: route.gateway,
          router_id: route.router_id,
          router_type: route.router_type,
          router_ha: route.router_ha,
          diffstatus: route.diffstatus
        })
      }
    }
    return Tabline
  }

  async getRouters(TypeRouter: string): Promise<any>{
    let routers_json: any
    if(TypeRouter == 'T0'){
      routers_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-0s');
    }
    else{
      routers_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-1s');
    }
  if (routers_json.result_count > 0){

    return routers_json.results
  }
  else{
    return []
  }
}

  async getRoutingTable(rtr: string, TypeRouter: string): Promise<any>{
    let router_url = ""
    let TabRT = []
    let EdgeCluster = await this.getEdgeInfo()

    if (TypeRouter == 'T0'){
      router_url = '/policy/api/v1/infra/tier-0s/' + rtr + '/routing-table'
      const t0state =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-0s/' + rtr + '/state');
      // add State on Router Object
      if ('tier0_status' in t0state){
        if('per_node_status' in t0state.tier0_status){
          for (let tn of t0state.tier0_status.per_node_status){
            for(let ec of EdgeCluster){
              for(let member of ec.members){
                if(member.id == tn.transport_node_id){
                  member.status = tn.high_availability_status
                }
              }
            }
          }
        }
      }
    }
    else{
      const t1state =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/tier-1s/' + rtr + '/state');
      // Get T1 State
      if ('tier1_status' in t1state){
          if ('per_node_status' in t1state.tier1_status){
            // Get only routes for Active routers
            for (let node of t1state.tier1_status.per_node_status){
              router_url = '/policy/api/v1/infra/tier-1s/'  + rtr  + '/forwarding-table?edge_id=' + node.transport_node_id
              for(let ec of EdgeCluster){
                for(let member of ec.members){
                  if(member.id == node.transport_node_id){
                    member.status = node.high_availability_status
                  }
                }
              }
            }
          }
      }
    }

    if (router_url != ""){
      let route_json = await this.session.getAPI(this.mysession, router_url)
      if (route_json.result_count > 0){
      for(let route of route_json.results){
        //if entries in table, loop on entries 
        if( route.count >0)
        {
          for (let entry of route.route_entries){
                let RouteObj = new Route(entry.network, entry.next_hop)
                RouteObj.network = entry.network
                RouteObj.gateway = entry.next_hop
                RouteObj.admin_distance = entry.admin_distance
                RouteObj.type = entry.route_type
                RouteObj.router = rtr
                RouteObj.router_id = entry.lr_component_id
                RouteObj.router_type = entry.lr_component_type
                // Get node name
                let tmp = route.edge_node.split('/')
                let index = tmp[tmp.length - 1]
                let cluster_id = tmp[tmp.length -3]
                
                for (let edc of EdgeCluster){
                  if (edc.id == cluster_id){
                    for(let member of edc.members){
                      if( member.member_index == index){
                        RouteObj.node_status = member.status
                        RouteObj.node_name = member.name
                        RouteObj.node_id = member.id
                        member.table.push(RouteObj)
                        TabRT.push(RouteObj)
                      }
                    }
                  }
                }
        }
        }
      }
      }
    }
    // else{
    //   TabRT = [{node_name: "no routes" }]
    // }
    return TabRT
  }

  async getEdgeInfo(): Promise<any>{
    let TabEdgeCluster = []
    let ec_json =  await this.session.getAPI(this.mysession, '/api/v1/edge-clusters');
    let edge_json =  await this.session.getAPI(this.mysession, "/api/v1/transport-nodes?node_types=EdgeNode");

    let result = await Promise.all([ec_json, edge_json])
    if (result[0].result_count > 0){
      for (let ec of result[0].results){
        let EdgeClusterObj = new EdgeCluster(ec.display_name)
        EdgeClusterObj.description = ec.description
        EdgeClusterObj.id = ec.id
        EdgeClusterObj.deployment_type = ec.deployment_type
        // Get member
        for (let member of ec.members){
          for (let edge of result[1].results){
            if (member.transport_node_id == edge.id){
              let EdgeObj = new Node(edge.display_name)
              EdgeObj.description = edge.description
              EdgeObj.id = edge.id
              EdgeObj.type = edge.resource_type
              EdgeObj.member_index = member.member_index
              EdgeClusterObj.members.push(EdgeObj)
            }
          }
        }
        TabEdgeCluster.push(EdgeClusterObj)
      }
    }
    return TabEdgeCluster
  }

  async getData(separator: string):Promise<any>{
    let T0_TabRTExport: any[] = []
    let T1_TabRTExport: any[] = []

    let TabRouterT0 = await this.getRouters('T0')
    TabRouterT0.forEach((element: { [x: string]: boolean; }) => { element['open'] = false });
    let TabRouterT1 = await this.getRouters('T1')
    TabRouterT1.forEach((element: { [x: string]: boolean; }) => { element['open'] = false });
    // Get all Routing Tables of T0 routers
    if (TabRouterT0.length >0){
      for (let rt of TabRouterT0){
        let RT = await this.getRoutingTable(rt.display_name,'T0')
        let temp = this.formatDataExport(RT)
        T0_TabRTExport = T0_TabRTExport.concat(temp)
      }
    }
    else{
      T0_TabRTExport = this.formatDataExport(TabRouterT0)
    }
    // Get all Routing Tables of T1 routers
    if (TabRouterT1.length >0){
      for (let rt of TabRouterT1){
        let RT = await this.getRoutingTable(rt.display_name,'T1')
        T1_TabRTExport = T1_TabRTExport.concat(this.formatDataExport(RT))
      }
    }
    else{
      T1_TabRTExport = this.formatDataExport(TabRouterT1)
    }

    let TabRouting = [
      {
        'header': ['Router Name', 'Edge Node Name', 'Edge Node ID', 'Edge Node Status', 'Route Type', 'Network', 'Admin Distance', 'Next Hop', 'Router Component ID', 'Router Component Type', 'Router HA', 'Diff Status' ],
        'name': 'T0_Routing_Table',
        'data': T0_TabRTExport,
      },
      {
        'header': ['Router Name', 'Edge Node Name', 'Edge Node ID', 'Edge Node Status', 'Route Type', 'Network', 'Admin Distance', 'Next Hop', 'Router Component ID', 'Router Component Type', 'Router HA', 'Diff Status' ],
        'name': 'T1_Routing_Table',
        'data': T1_TabRTExport,
      }
    ]
    return TabRouting
  }
}
