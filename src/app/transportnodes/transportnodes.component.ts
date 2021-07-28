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

  Name = this.tn.Name
  Header = this.tn.Header
  HeaderDiff = this.tn.HeaderDiff

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
