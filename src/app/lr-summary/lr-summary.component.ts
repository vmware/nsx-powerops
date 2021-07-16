import { Component, Input, OnInit } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { ExportService } from '../services/export.service';
import { LrsummaryService } from '../services/lrsummary.service'
import { ClarityIcons, downloadCloudIcon, fileGroupIcon } from '@cds/core/icon';
import * as _ from 'lodash';

@Component({
  selector: 'app-lr-summary',
  templateUrl: './lr-summary.component.html',
  styleUrls: ['./lr-summary.component.css']
})
export class LrSummaryComponent implements OnInit {
  @Input() DiffTab: any = []
  loading = true
  isCompared = false;
  error = false
  error_message = ""
  
  TabLR: any[] = [];
  Header= ['Name', 'ID', 'Edge Cluster Name', 'Edge Cluster ID','LR Type', 'HA Mode', 'Admin Failover Mode','Relocation' ]

  HeaderDiff = [
    { header: 'Name', col: 'name'},
    { header: 'ID', col: 'id'},
    { header: 'Edge Cluster Name', col: 'cluster_name'},
    { header: 'Edge Cluster ID', col: 'cluster_id'},
    { header: 'LR Type', col: 'type'},
    { header: 'HA Mode', col: 'hamode'},
    { header: 'Admin Failover Mode', col: 'failover'},
    { header: 'Relocation', col: 'relocation'},
  ]
  Name = 'LR_Summary'

  constructor(
    private myexport: ExportService,
    private lrsummary: LrsummaryService

    ) { 
    // this.mysession = SessionService.getSession()
  }

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon );
    this.TabLR =  await this.lrsummary.getLR()
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
        Export = this.lrsummary.formatDataExport(this.TabLR, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata])
        break;
      }
      case 'CSV': {
        Export = this.lrsummary.formatDataExport(this.TabLR, '/')
        this.myexport.generateCSV(this.Name, this.Header, Export, true)
        break;
      }
      case 'JSON': {
        this.myexport.generateJSON(this.Name, Tab)
        break;
      }
      case 'YAML': {
        this.myexport.generateYAML(this.Name, Tab)
        break;
      }
      default:{
        Export = this.lrsummary.formatDataExport(this.TabLR, '/')
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
