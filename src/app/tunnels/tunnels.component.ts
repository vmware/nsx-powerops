import { Component, OnInit } from '@angular/core';
import { ClarityIcons, fileGroupIcon, uploadIcon } from '@cds/core/icon';
import * as _ from 'lodash';
import { ExportService } from '../services/export.service';
import { TunnelsService } from '../services/tunnels.service'

@Component({
  selector: 'app-tunnels',
  templateUrl: './tunnels.component.html',
  styleUrls: ['./tunnels.component.css']
})

export class TunnelsComponent implements OnInit {
  TabTunnels: any[] = []
  Header= ['Transport Node', 'Tunnel Name', 'Tunnel Status', 'Egress Interface', 'Local IP', 'Remote IP', 'Remote Node ID', 'Remote Node Name', 'Encap', 'Diff Status' ]
  Name = 'Tunnels'


  HeaderDiff = [
    { header: 'Transport Node', col: 'node', subcol: 'name'},
    { header: 'Tunnel Name', col: 'name'},
    { header: 'Tunnel Status', col: 'status'},
    { header: 'Egress Interface', col: 'egress_int'},
    { header: 'Local IP', col: 'local_ip'},
    { header: 'Remote IP', col: 'remote_ip'},
    { header: 'Remote Node ID', col: 'remote_node_id'},
    { header: 'Remote Node Name', col: 'remote_node_display_name'},
    { header: 'Encap', col: 'encap'},
  ]

  exportloading = true
  exportxls = false
  loading = true
  error = false
  error_message = ""
  isCompared = false;
  DiffTab: any = []

  constructor(
    private tunnel: TunnelsService,
    private myexport: ExportService,
    ) { }

    async ngOnInit(): Promise<void>{
      ClarityIcons.addIcons(uploadIcon, fileGroupIcon);
      let TN = await this.tunnel.getTransportNodes()
      TN.forEach(async element => {
        let tmp = await this.tunnel.getTunnels(element)
        this.TabTunnels = this.TabTunnels.concat(tmp)

      });
      this.exportloading = false
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

  // Export XLS file
  async Export(type: string): Promise<void>{

    this.exportxls = true
    let Export: any
    switch(type){
      case 'XLS': {
        Export = this.tunnel.formatDataExport(this.TabTunnels, ', ');
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.tunnel.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.tunnel.formatDataExport(this.TabTunnels, '/');
        this.myexport.generateCSV(this.Name, this.Header, Export, true)
        break;
      }
      case 'JSON': {
        this.myexport.generateJSON(this.Name, this.TabTunnels)
        break;
      }
      case 'YAML': {
        this.myexport.generateYAML(this.Name, this.TabTunnels)
        break;
      }
      default:{
        Export = this.tunnel.formatDataExport(this.TabTunnels, ', ');
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata])
        break;
      }
    }
    this.exportxls = false

  }
}
