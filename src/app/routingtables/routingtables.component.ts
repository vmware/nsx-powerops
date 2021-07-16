import { Component, Input, OnInit } from '@angular/core';
import { ExportService } from '../services/export.service';
import { LoginSession } from '../class/loginSession';
import {RoutingtablesService} from '../services/routingtables.service'
import { SessionService } from '../services/session.service';
import { ClarityIcons, downloadCloudIcon, fileGroupIcon } from '@cds/core/icon';
import * as _ from 'lodash';


@Component({
  selector: 'app-routingtables',
  templateUrl: './routingtables.component.html',
  styleUrls: ['./routingtables.component.css']
})
export class RoutingtablesComponent implements OnInit {
  public mysession: LoginSession;
  @Input() DiffTab: any = []
  loading = true
  isCompared = false;
  error = false
  error_message = ""
  loadingdiff = true
  TabforDiff: any[] = []

  TabRT: any[] = [];
  T0_TabRTExport: any[] = []
  T1_TabRTExport: any[] = []
  TabRouterT0: any
  TabRouterT1: any
  RouterName: string = '...'
  RouterType: string
  Value = 0
  NbT0 = 0
  NbT1 = 0

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
  loadingAll = true
  exportloading = true
  exportxls = false
  RTRObj: any

  constructor(
      private RT: RoutingtablesService,
      private myexport: ExportService,
  ) { 
    this.mysession = SessionService.getSession()
  }

  async onDetailOpen(event: any, router: any, type: string): Promise<void>{
    this.TabRT = []
    this.loading = true
    router.open = event
    if (event ){
      this.TabRT = await this.RT.getRoutingTable(router.display_name, type)
    }
    this.loading = false
  }

  async ngOnInit(): Promise<void> {
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon );

    this.TabRouterT0 = await this.RT.getRouters('T0')
    this.NbT0 = this.TabRouterT0.length
    this.TabRouterT0.forEach((element: { [x: string]: boolean; }) => { element['open'] = false });
    this.TabRouterT1 = await this.RT.getRouters('T1')
    this.NbT1 = this.TabRouterT1.length
    this.TabRouterT1.forEach((element: { [x: string]: boolean; }) => { element['open'] = false });
    this.loadingAll = false

    // Get all routes for Diff
    for (let rt of this.TabRouterT0){
      this.T0_TabRTExport = await this.RT.getRoutingTable(rt.display_name,'T0')
      this.RouterName = rt.display_name
    }
    for (let rt of this.TabRouterT1){
      this.T1_TabRTExport = await this.RT.getRoutingTable(rt.display_name,'T1')
      this.TabforDiff = this.T0_TabRTExport.concat(this.T1_TabRTExport)
      this.RouterName = rt.display_name
    }
    this.loadingdiff = false
  }

    // To check type of variable in HTML
    typeOf(value: any) {
      return typeof value;
    }
  
    isArray(obj : any ) {
      return Array.isArray(obj)
   }
  
   getDiff(diffArrayOut: any){
    this.DiffTab = _.values(diffArrayOut)
    this.isCompared = true
   }


  ExportTable(RTRName: string, Table: any){
    let Export = []
    Export = this.RT.formatDataExport(Table)
    this.myexport.generateCSV(RTRName + '_RoutingTable', this.Header, Export, true)
  }

  async Export(type: string): Promise<void> {
    let TabRTExport = []
    // this.exportxls = true

    // Get all Routing Tables of T0 routers
    // let nbrouter = this.TabRouterT0.length + this.TabRouterT1.length
    // let tmp: number = 0
    // this.Value = 0

    // for (let rt of this.TabRouterT0){
    //   this.RouterName = rt.display_name
    //   this.RouterType = 'Tier 0'

    //   let RT = await this.RT.getRoutingTable(rt.display_name,'T0')
    //   tmp = this.Value + (100/nbrouter)
    //   this.Value =  Math.round(tmp * 10)/10
    //   T0_TabRTExport = T0_TabRTExport.concat(this.RT.formatDataExport(RT))
    // }

    // Get all Routing Tables of T1 routers
    // for (let rt of this.TabRouterT1){
    //   this.RouterName = rt.display_name
    //   this.RouterType = 'Tier 1'
    //   let RT = await this.RT.getRoutingTable(rt.display_name,'T1')
    //   tmp = this.Value + (100/nbrouter)
    //   this.Value =  Math.round(tmp * 10)/10
    //   T1_TabRTExport = T1_TabRTExport.concat(this.RT.formatDataExport(RT))
    // }

    switch(type){
      case 'XLS': {
        let TabRouting = [
          {
            'header': this.Header,
            'name': 'T0_Routing_Table',
            'data': this.T0_TabRTExport
          },
          {
            'header': this.Header,
            'name': 'T1_Routing_Table',
            'data': this.T1_TabRTExport
          }
        ]
        this.myexport.generateExcel('RoutingTables', TabRouting)
        break;
      }
      case 'CSV': {
        TabRTExport = this.T0_TabRTExport.concat(this.T1_TabRTExport)
        this.myexport.generateCSV('T0_RoutingTable', this.Header, TabRTExport, true)
        break;
      }
      case 'JSON': {
        TabRTExport = this.T0_TabRTExport.concat(this.T1_TabRTExport)
        this.myexport.generateJSON('RoutingTables', TabRTExport)
        break;
      }
      case 'YAML': {
        TabRTExport = this.T0_TabRTExport.concat(this.T1_TabRTExport)
        this.myexport.generateYAML('RoutingTables', TabRTExport)
        break;
      }
    }
    // this.exportxls = false
  }
}
