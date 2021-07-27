import { Component, Input, OnInit } from '@angular/core';
import { IppoolService } from '../services/ippool.service'
import { ExportService } from '../services/export.service';
import { ToolsService } from '../services/tools.service';
import { ClarityIcons, fileGroupIcon, downloadCloudIcon  } from '@cds/core/icon';
import * as _ from 'lodash';

@Component({
  selector: 'app-ippool',
  templateUrl: './ippool.component.html',
  styleUrls: ['./ippool.component.css']
})


export class IppoolComponent implements OnInit {
  @Input() DiffTab: any = []
  loading = true
  isCompared = false;
  error = false
  error_message = ""
  TabPool: any

  /**
    Header Definition for Excel Sheet
   */
  Header = this.pool.Header
  HeaderDiff = this.pool.HeaderDiff
  Name = this.pool.Name

   /**
  * @ignore
  */
  constructor(
    public myexport: ExportService,
    private pool: IppoolService,
    private tools: ToolsService,
  ) { 
  }

  async ngOnInit(): Promise<void> {
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon );
    this.TabPool = await this.pool.getIPPool()
    this.loading = false
  }


 getDiff(diffArrayOut: any){
  this.DiffTab = _.values(diffArrayOut)
  this.isCompared = true
 }

  /**
  * Perform export of HTML tab to different export format file (XLS, CSV, YAML, JSON)
  * @example
  * Export('YAML)
  * @param {string} type  The type of exported file
  */

  Export(type: string, Tab:any, PrefixName: any){
    let Export: any

    switch(type){
      case 'XLS': {
        Export = this.pool.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata])
        break;
      }
      case 'CSV': {
        Export = this.pool.formatDataExport(Tab, '/')
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
        Export = this.pool.formatDataExport(Tab, ', ')
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
