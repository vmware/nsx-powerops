import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { ComputeMgr } from '../class/ClusterNSX'
import { EdgeCluster, Node } from '../class/Node'

@Injectable({
  providedIn: 'root'
})
export class TNstatusService {
  public mysession: LoginSession;

  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  async getCompute(): Promise<any>{
    let TabCompute: any[] = [];
    const Compute_json =  await this.session.getAPI(this.mysession, '/api/v1/fabric/compute-managers');

    if (Compute_json.result_count > 0){
      for (let cp of Compute_json.results){
        let computemgr = new ComputeMgr(cp.id, cp.server)
        computemgr.origin = cp.origin_type
        computemgr.build = cp.origin_properties[0].value

        TabCompute.push(computemgr)
      }
    }
    return TabCompute
  }

  async getEdgeClusterStatus(): Promise<any>{
    let TabEdgeCluster: any[] = [];

    const EdgeCluster_json =  await this.session.getAPI(this.mysession, '/api/v1/edge-clusters');

    if (EdgeCluster_json.result_count > 0){
      for (let ed of EdgeCluster_json.results){
        let edgecluster = new EdgeCluster(ed.display_name)
        edgecluster.deployment_type = ed.deployment_type
        edgecluster.resource_type = ed.resource_type
        edgecluster.member_node_type = ed.member_node_type

        TabEdgeCluster.push(edgecluster)
      }
    }
    return TabEdgeCluster
  }

  async getEdgeStatus(): Promise<any>{
    let TabEdge: any[] = [];
    const Edge_json =  await this.session.getAPI(this.mysession, '/api/v1/search/query?query=resource_type:Edgenode');

    if (Edge_json.result_count > 0){
      for (let ed of Edge_json.results){
        let ctrnodeIP = ""
        let status = "DOWN"
        if (ed.status.lcp_connectivity_status_details.length > 0){
          ctrnodeIP = ed.status.lcp_connectivity_status_details[0].control_node_ip;
          status = ed.status.lcp_connectivity_status_details[0].status
        }
        let edge = new Node(ed.display_name)
        edge.lcp_connectivity_status =  ed.status.lcp_connectivity_status
        edge.mpa_connectivity_status = ed.status.mpa_connectivity_status
        edge.mpa_connectivity_status_details = ed.status.mpa_connectivity_status_details
        edge.host_node_deployment_status = ed.status.host_node_deployment_status
        edge.control_node_ip = ctrnodeIP
        edge.status = status
        TabEdge.push(edge)
      }
    }
    return TabEdge
  }

    async getTNStatus(): Promise<any>{
      let TabTN: any[] = [];

      const TN_json =  await this.session.getAPI(this.mysession, '/api/v1/search/query?query=resource_type:Hostnode');
      if (TN_json.result_count > 0){
        for (let tn of TN_json.results){
          let ctrnodeIP = ""
          let status = "DOWN"
          if (tn.status.lcp_connectivity_status_details.length > 0){
            ctrnodeIP = tn.status.lcp_connectivity_status_details[0].control_node_ip;
            status = tn.status.lcp_connectivity_status_details[0].status
          }
          let node = new Node(tn.display_name)
          node.lcp_connectivity_status =  tn.status.lcp_connectivity_status
          node.mpa_connectivity_status = tn.status.mpa_connectivity_status
          node.mpa_connectivity_status_details = tn.status.mpa_connectivity_status_details
          node.host_node_deployment_status = tn.status.host_node_deployment_status
          node.control_node_ip = ctrnodeIP
          node.status = status
          TabTN.push(node)
        }
      }
      return TabTN
    }

}
