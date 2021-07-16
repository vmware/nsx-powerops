import { Component, Input, OnInit } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { ExportService } from '../services/export.service';
import { BgpService } from '../services/bgp.service';
import { ClarityIcons, downloadCloudIcon, fileGroupIcon } from '@cds/core/icon';
import * as _ from 'lodash';

@Component({
  selector: 'app-bgp-sessions',
  templateUrl: './bgp-sessions.component.html',
  styleUrls: ['./bgp-sessions.component.css']
})
export class BgpSessionsComponent implements OnInit {
  @Input() DiffTab: any = []
  loading = true
  isCompared = false;
  error = false
  error_message = ""

  public mysession: LoginSession;
  TabBGP: any[] = [];
  Header= ['T0 Router', 'BGP Status', 'ECMP', 'Inter-SR','Source IP Address', 'Local AS', 'Neighbor IP Address', 'Remote AS', 'Total IN Prefixes', 'Total OUT Prefixes', 'Session Status', 'Type', 'Diff Status' ]
  HeaderDiff = [
    { header: 'T0 Router', col: 't0_name'},
    { header: 'BGP Status', col: 'bgp_status'},
    { header: 'ECMP', col: 'ecmp'},
    { header: 'Inter-SR', col: 'ibgp'},
    { header: 'Source IP Address', col: 'source_ip'},
    { header: 'Local AS', col: 'local_as'},
    { header: 'Neighbor IP Address', col: 'remote_ip'},
    { header: 'Remote AS', col: 'remote_as'},
    { header: 'Total IN Prefixes', col: 'prefix_in'},
    { header: 'Total OUT Prefixes', col: 'prefix_out'},
    { header: 'Session Status', col: 'status'},
  ]
  Name = 'BGP'

  constructor(
    private myexport: ExportService,
    private bgp: BgpService,
    private session: SessionService,

    ) { 
    this.mysession = SessionService.getSession()
  }

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon );

    this.TabBGP =  await this.bgp.getBGPSession()
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
  Export(type: string, Tab:any, PrefixName: any){
      let Export: any
  
      switch(type){
        case 'XLS': {
          Export = this.bgp.formatDataExport(Tab, ', ')
          let Formatdata = {
            'header': this.Header,
            'data': Export,
            'name': this.Name
          }
          this.myexport.generateExcel(this.Name, [Formatdata], this.bgp.ConditionalFormating)
          break;
        }
        case 'CSV': {
          Export = this.bgp.formatDataExport(Tab, '/')
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
          Export = this.bgp.formatDataExport(Tab, ', ')
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
