import { Component, OnInit } from '@angular/core';
import { ClarityIcons, fileGroupIcon, uploadIcon } from '@cds/core/icon';
import * as _ from 'lodash';
import { ExportService} from '../services/export.service';
import {TransportnodesService } from '../services/transportnodes.service'

@Component({
  selector: 'app-transportnodes',
  templateUrl: './transportnodes.component.html',
  styleUrls: ['./transportnodes.component.css']
})

export class TransportnodesComponent implements OnInit {
  TabNodes: any[] = [];
  TabNodesDiff: any[];
  TabHost: any[] = [];
  TabEdge: any[]= [];

  loading = true
  error = false
  error_message = ""
  isCompared = false;
  DiffTab: any = []

  Name = "Tranport_Nodes"
  Header = [
    'Transport Node Name',
    'Type',
    'ID', 
    'Management IP', 
    'Switch Name',
    'Switch Mode', 
    'Switch Type',
    'Transport Zones',
    'Uplink Profile',
    'Teaming Policy',
    'Physical Interfaces',
    'Uplink Interfaces',
    'Active Interface',
    'Transport Vlan',
    'MTU',
    'Serial Number', 
    'FullVersion', 
    'Maintenance Mode', 
    'Deployement Status',
    'PowerState',
    'Diff Status'
  ]

  HeaderDiff = [
    { header: 'Transport Node Name', col: 'name'},
    { header: 'Type', col: 'type'},
    { header: 'ID', col: 'id'},
    { header: 'Management IP', col: 'managementIp'},
    { header: 'Switch Name', col: 'hostswitch', subcol: 'name'},
    { header: 'Switch Mode', col: 'hostswitch', subcol: 'mode'},
    { header: 'Switch Type', col: 'hostswitch', subcol: 'type'},
    { header: 'Transport Zones', col: 'TZ', subcol: 'name'},
    // { header: 'Uplink Profile', col: ''},
    // { header: 'Teaming Policy', col: ''},
    // { header: 'Physical Interfaces', col: ''},
    // { header: 'Uplink Interfaces', col: ''},
    // { header: 'Active Interface', col: ''},
    // { header: 'Transport Vlan', col: ''},
    { header: 'MTU', col: 'MTU'},
    { header: 'Serial Number', col: 'serialNumber'},
    { header: 'FullVersion', col: 'full_version'},
    { header: 'Maintenance Mode', col: 'inMaintenanceMode'},
    { header: 'Deployement Status', col: 'host_node_deployment_status'},
    { header: 'PowerState', col: 'powerState'}
  ]


  constructor(
    private myexport: ExportService,
    private tn: TransportnodesService
    ) { }

    async ngOnInit(): Promise<void>{
      ClarityIcons.addIcons(uploadIcon, fileGroupIcon);
      this.TabNodes = await this.tn.getTN()
      for (let node of this.TabNodes){
        if(node.type == 'HostNode'){
          this.TabHost.push(node)
        }
        else {
          this.TabEdge.push(node)
        }
      }
      // Stringlify and parse to obtain erase object
      let tmp = JSON.stringify(this.TabNodes, null, 2)
      this.TabNodesDiff = JSON.parse(tmp)
      this.loading = false
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

  Export(type: string, Tab:any, PrefixName: any){
    let Export: any

    switch(type){
      case 'XLS': {
        Export = this.tn.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.tn.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.tn.formatDataExport(Tab, '/')
        this.myexport.generateCSV(PrefixName, this.Header, Export, true)
        break;
      }
      case 'JSON': {
        this.myexport.generateJSON(PrefixName, Tab)
        break;
      }
      case 'YAML': {
        this.myexport.generateYAML(PrefixName, Tab)
        break;
      }
      default:{
        Export = this.tn.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata])
        break;
      }
    }
  }
}
