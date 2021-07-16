import { Component, OnInit } from '@angular/core';
import jspdf from 'jspdf';
import domtoimage from 'dom-to-image';
import { NsxsummaryService} from '../services/nsxsummary.service'
import { SessionService } from '../services/session.service';
import { LoginSession } from '../class/loginSession';
import { blockIcon, certificateIcon, ClarityIcons, clusterIcon, gridViewIcon, hostIcon, libraryIcon, networkSettingsIcon, nodeGroupIcon, routerIcon, switchIcon } from '@cds/core/icon';
import {TransportNode} from '../class/TransportNode'


@Component({
  selector: 'app-nsx-summary',
  templateUrl: './nsx-summary.component.html',
  styleUrls: ['./nsx-summary.component.css'],
})
export class NsxSummaryComponent implements OnInit {
  public mysession: LoginSession;
  TLClusterStatus: string = "processing"
  TLClusterCtrlStatus: string = "processing"
  TLOverallClusterStatus: string = "processing"
  TLNbManagers: string = "processing"
  TLNbOnlineManager: string = "processing"
  TLNbOfflineManager: string = "processing"
  offlinensx: any = 0;
  TabNode: any[] = [];
  TabSecurity: any[] = [];
  TabRouting: any[] = [];
  TabNSX: any[]= []
  TabResult: any[] =[];
  cluster_status_json: any = {}
  cluster_json: any = {}
  loading_nsxmgr = true
  loading = true
  node_json: any
  cluster_status = ""
  ctrl_status = ""
  overall_status = ""
  nb_nodes = 0
  nb_online_nodes = 0
  TabTN: TransportNode[] = []
  TabEdge: TransportNode[] = []
  edge: any[] = []
  node_status = ""

  constructor(
    private summary: NsxsummaryService,
    private session: SessionService,
     ) { 
      this.mysession = SessionService.getSession()
     }

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(clusterIcon, routerIcon, hostIcon, libraryIcon, gridViewIcon, certificateIcon, networkSettingsIcon, switchIcon, blockIcon, nodeGroupIcon);
    let node_json = this.session.getAPI(this.mysession, '/policy/api/v1/search?query=_exists_:resource_type%20AND%20!_exists_:nsx_id%20AND%20!_create_user:nsx_policy%20AND%20resource_type:HostNode&page_size=50&cursor=&data_source=INTENT&exclude_internal_types=true')
    let edge_json = this.session.getAPI(this.mysession, '/policy/api/v1/search?query=_exists_:resource_type%20AND%20!_exists_:nsx_id%20AND%20!_create_user:nsx_policy%20AND%20resource_type:EdgeNode&page_size=50&cursor=&data_source=INTENT&exclude_internal_types=true')
    let result = await Promise.all([node_json, edge_json])

    // Transport Node Status
    this.TabTN = this.summary.getNodeStatus(result[0].results)
     // Edge Node Status
    this.TabEdge = this.summary.getNodeStatus(result[1].results)

    this.TabResult = await this.summary.getClusterStatus()
    this.TabNSX = this.TabResult[0]
    // Specify status avoid error during HTML loading
    this.cluster_status = this.TabResult[1].mgmt_cluster_status.status
    this.ctrl_status = this.TabResult[1].control_cluster_status.status
    this.overall_status = this.TabResult[1].control_cluster_status.status
    this.nb_nodes = this.TabResult[2].nodes.length
    this.nb_online_nodes = this.TabResult[1].mgmt_cluster_status.online_nodes.length
    if ('offline_nodes' in this.TabResult[1].mgmt_cluster_status){
      this.offlinensx = this.TabResult[1].mgmt_cluster_status.offline_nodes.length
    }

    // NSX Cluster Status
    if (this.cluster_status === 'STABLE'){ this.TLClusterStatus = 'success' }
    else if (this.cluster_status == ''){ this.TLClusterStatus = 'processing' }
    else { this.TLClusterStatus = 'error' }
    // NSX Cluster CTRL Status
    if (this.ctrl_status === 'STABLE'){ this.TLClusterCtrlStatus = 'success' }
    else if (this.ctrl_status == ''){ this.TLClusterCtrlStatus = 'processing' }
    else { this.TLClusterCtrlStatus = 'error' }
    // NSX Overall Status
    if (this.overall_status === 'STABLE'){ this.TLOverallClusterStatus = 'success' }
    else if (this.overall_status == ''){ this.TLOverallClusterStatus = 'processing' }
    else { this.TLOverallClusterStatus = 'error' }
    // NSX Nb Managers
    if (this.nb_nodes > 1){ this.TLNbManagers = 'success' }
    else { this.TLNbManagers = 'error' }
    // NSX Nb Online
    if (this.nb_online_nodes == this.nb_nodes){ this.TLNbOnlineManager = 'success' }
    else if (this.nb_online_nodes != this.nb_nodes){ this.TLNbOnlineManager = 'error' }
    else { this.TLNbOnlineManager = 'processing' }
    // NSX Nb Offline
    if (this.offlinensx === 0){ this.TLNbOfflineManager = 'success' }
    else { this.TLNbOfflineManager = 'error' }

    this.loading_nsxmgr = false

    this.TabNode = await this.summary.getNodes();
    this.TabRouting = await this.summary.getRouting();
    this.TabSecurity = await this.summary.getSecurity();
    this.loading = false
  }

  generatePdf()  
  {  
    const data: any = document.getElementById('pdf');
    let width = data.clientWidth;
    let height = data.clientHeight;
    const options = { background: 'white', width: width + 50, height: height + 50}
    domtoimage.toPng(data, options).then((dataUrl) => {

       //Initialize JSPDF
      const doc = new jspdf('l', 'mm', [360, 280]);
      //const doc = new jspdf('l', 'mm', 'a4');
      const pageHeight= doc.internal.pageSize.height;
      const imgProps = doc.getImageProperties(dataUrl);
      const pdfWidth = doc.internal.pageSize.getWidth();
      const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;

      doc.addImage(dataUrl, 'PNG', 5, 5, pdfWidth, pdfHeight);
      doc.save('NSX_Summary')
   })
  }
}