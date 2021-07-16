import { Component, OnInit } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { ManagerinfosService} from '../services/managerinfos.service'
import { ExportService } from '../services/export.service';
import {ClusterNSX} from '../class/ClusterNSX'
import { ClarityIcons, downloadCloudIcon, fileGroupIcon } from '@cds/core/icon';
import * as _ from 'lodash';


@Component({
  selector: 'app-manager-infos',
  templateUrl: './manager-infos.component.html',
  styleUrls: ['./manager-infos.component.css']
})
export class ManagerInfosComponent implements OnInit {
  public mysession: LoginSession;
  Name = "Manager_Infos"
  Header = [
    'Group',
    'Group Type',
    'Group Status',
    'Member FQDN',
    'Member IP',
    'Member UUID',
    'Member Status',
    'Diff Status'
  ]
  HeaderDiff = [
    { header: 'Group', col: 'name'},
    { header: 'Group Type', col: 'name'},
    { header: 'Group Status', col: 'status'},
    { header: 'Member FQDN', col: 'members', subcol: 'fqdn'},
    { header: 'Member IP', col: 'members', subcol: 'ip'},
    { header: 'Member UUID', col: 'members', subcol: 'id'},
    { header: 'Member Status', col: 'members', subcol: 'status'},
  ]

  Cluster: any
  clusterID = ""
  clusterServices = []
  TabServices: any
  loading = true
  error = false
  error_message = ""
  isCompared = false;
  DiffTab: any = []

  constructor(
    private managerinfos: ManagerinfosService,
    private myexport: ExportService,
    ) { 
    this.mysession = SessionService.getSession()
  }

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon);
    this.Cluster = await this.managerinfos.getClusterInfo()
    this.clusterID = this.Cluster[0].id
    this.clusterServices = this.Cluster[0].services
    // Stringlify and parse to obtain erase object
    let tmp = JSON.stringify(this.Cluster[0].services, null, 2)
    this.TabServices = JSON.parse(tmp)
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
        Export = this.managerinfos.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.managerinfos.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.managerinfos.formatDataExport(Tab, '/')
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
        Export = this.managerinfos.formatDataExport(Tab, ', ')
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
