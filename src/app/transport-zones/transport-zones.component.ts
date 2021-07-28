import { Component, OnInit } from '@angular/core';
import { ClarityIcons, fileGroupIcon, uploadIcon } from '@cds/core/icon';
import * as _ from 'lodash';
import { ExportService } from '../services/export.service';
import { TransportzoneService } from '../services/transportzone.service'

@Component({
  selector: 'app-transport-zones',
  templateUrl: './transport-zones.component.html',
  styleUrls: ['./transport-zones.component.css']
})
export class TransportZonesComponent implements OnInit {
  TabTZ: any;

  Name = this.tz.Name
  Header = this.tz.Header
  HeaderDiff = this.tz.HeaderDiff

  loading = true;
  exportxls = true
  error = false
  error_message = ""
  isCompared = false;
  DiffTab: any = []

  constructor(
    private tz: TransportzoneService,
    private myexport: ExportService,
    ) { }

    async ngOnInit(): Promise<void>{
      ClarityIcons.addIcons(uploadIcon, fileGroupIcon);
      this.TabTZ = await this.tz.getTransportZones()
      this.loading = false;
  }


 getDiff(diffArrayOut: any){
  this.DiffTab = _.values(diffArrayOut)
  this.isCompared = true
 }

   // Export XLS file
   async Export(type: string): Promise<void>{

    let Export: any
    switch(type){
      case 'XLS': {
        Export = this.tz.formatDataExport(this.TabTZ, ', ');
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata])
        break;
      }
      case 'CSV': {
        Export = this.tz.formatDataExport(this.TabTZ, '/');
        this.myexport.generateCSV(this.Name, this.Header, Export, true)
        break;
      }
      case 'JSON': {
        this.myexport.generateJSON(this.Name, this.TabTZ)
        break;
      }
      case 'YAML': {
        this.myexport.generateYAML(this.Name, this.TabTZ)
        break;
      }
      default:{
        Export = this.tz.formatDataExport(this.TabTZ, ', ');
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
