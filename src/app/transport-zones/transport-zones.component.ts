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
  Header= ['Name', 'Description', 'ID', 'Ressource Type','Host Switch Name', 'Host Switch ID', 'Host Switch Mode', 'Host Switch Default','is Default','is Nested NSX', 'Transport Type', 'Uplink Teaming Policy' ]

  HeaderDiff = [
    { header: 'Name', col: 'name'},
    { header: 'Description', col: 'description'},
    { header: 'ID', col: 'id'},
    { header: 'Ressource Type', col: 'resource_type'},
    { header: 'Host Switch Name', col: 'hostswitch', subcol: 'name'},
    { header: 'Host Switch ID', col: 'hostswitch', subcol: 'id'},
    { header: 'Host Switch Mode', col: 'host_switch_mode'},
    { header: 'Host Switch Default', col: 'hostswitch', subcol: 'type'},
    { header: 'is Default', col: 'default'},
    { header: 'is Nested NSX', col: 'nested'},
    { header: 'Transport Type', col: 'type'},
    { header: 'Uplink Teaming Policy', col: 'uplink_teaming_policy_names'}
  ]

  Name = 'Transport_Zones'
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
