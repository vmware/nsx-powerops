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

  Header = this.bgp.Header
  HeaderDiff = this.bgp.HeaderDiff
  Name = this.bgp.Name

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
