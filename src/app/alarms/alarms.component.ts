import { Component, Input, OnInit } from '@angular/core';
import { ExportService } from '../services/export.service';
import { AlarmsService } from '../services/alarms.service'
import { ToolsService } from '../services/tools.service';
import {ClrDatagridSortOrder} from '@clr/angular';
import { ClarityIcons, downloadCloudIcon, fileGroupIcon } from '@cds/core/icon';
import * as _ from "lodash";

@Component({
  selector: 'app-alarms',
  templateUrl: './alarms.component.html',
  styleUrls: ['./alarms.component.css']
})
export class AlarmsComponent implements OnInit {
  @Input() DiffTab: any = []
  loading = true
  isCompared = false;
  error = false
  error_message = ""

  TabAlarms: any[] = [];
  Header= ['Feature Name', 'Event Type', 'Node Name', 'Node Resource Type', 'Entity ID', 'Severity', 'Time', 'Status', 'Description', 'Recommended Action', 'Diff Status' ]
  HeaderDiff = [
    { header: 'Feature Name', col: 'feature_name'},
    { header: 'Event Type', col: 'event_type'},
    { header: 'Node Name', col: 'node_name'},
    { header: 'Node Resource Type', col: 'node_resource_type'},
    { header: 'Entity ID', col: 'entity_id'},
    { header: 'Severity', col: 'severity'},
    { header: 'Time', col: 'time'},
    { header: 'Status', col: 'status'},
    { header: 'Description', col: 'description'},
    { header: 'Recommended Action', col: 'recommended_action'},
  ]

  Name= 'Alarms'
  TimeSort: any

  constructor(
    private myexport: ExportService,
    private tools: ToolsService,
    private alarms: AlarmsService
    ) {}

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon );

     await this.alarms.getAlarms().then( res => {
      this.TabAlarms = res
      this.TimeSort = ClrDatagridSortOrder.DESC
      this.loading = false
    })
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
  Export(type: string, Tab:any, PrefixName: any){

    let Export: any

    switch(type){
      case 'XLS': {
        Export = this.alarms.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.alarms.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.alarms.formatDataExport(Tab, '/')
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
        Export = this.alarms.formatDataExport(Tab, ', ')
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
