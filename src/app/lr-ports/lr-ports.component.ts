import { Component, Input, OnInit } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { ExportService} from '../services/export.service';
import { SessionService } from '../services/session.service';
import {LrportsService } from '../services/lrports.service'
import { ClarityIcons, downloadCloudIcon, fileGroupIcon } from '@cds/core/icon';
import * as _ from 'lodash';

@Component({
  selector: 'app-lr-ports',
  templateUrl: './lr-ports.component.html',
  styleUrls: ['./lr-ports.component.css']
})
export class LrPortsComponent implements OnInit {
  @Input() DiffTab: any = []
  loading = true
  isCompared = false;
  error = false
  error_message = ""
  TabPool: any
  
  public mysession: LoginSession;
  TabPorts: any[] = [];
  Header= ['LR Port Name', 'ID', 'Attachment Type', 'Attachment ID', 'Logical Router Name', 'Logical Router ID','Segment Name', 'Segment ID', 'Create User', 'Admin State', 'Status', 'Diff Status' ]
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
  Name = 'LR_Ports'

  constructor(
    private myexport: ExportService,
    private lrports: LrportsService
    ) { 
    this.mysession = SessionService.getSession()
  }

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon );
    this.TabPorts =  await this.lrports.getLRPorts()
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
        Export = this.lrports.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.lrports.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.lrports.formatDataExport(Tab, '/')
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
        Export = this.lrports.formatDataExport(Tab, ', ')
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
