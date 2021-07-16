import { Component, OnInit } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { ExportService} from '../services/export.service';
import { SessionService } from '../services/session.service';
import {VmsService } from '../services/vms.service';
import { HttpClient } from '@angular/common/http';
import { ClarityIcons,downloadCloudIcon,downloadIcon, fileGroupIcon } from '@cds/core/icon';
import { VM } from '../class/VM';
import * as _ from 'lodash';


@Component({
  selector: 'app-vms',
  templateUrl: './vms.component.html',
  styleUrls: ['./vms.component.css']
})

export class VmsComponent implements OnInit {
  public mysession: LoginSession;
  public vm: VM
  TabVMs: any[] = [];
  // TabRules: any[] = [];
  Header= ['VMs Name', 'VMs ID', 'Tags', 'Host', 'Segments', 'Attachement ID','Group', 'Status', 'Diff Status']
  HeaderDiff = [
    { header: 'VMs Name', col: 'name'},
    { header: 'VMs ID', col: 'id'},
    { header: 'Tags', col: 'tags', subcol: 'tag'},
    { header: 'Host', col: 'hosts'},
    { header: 'Segments', col: 'segments'},
    { header: 'Group', col: 'groups'},
    { header: 'Status', col: 'status'},
  ]
  Name = 'VMs'
  HeaderRules= ['VMs Name', 'VMs ID', 'Tags', 'Host', 'Segments', 'Attachement ID','Group', 'Status']
  NameRules = ''
  loading = true
  loadingAll = true
  loadingDetail = true
  boolexport = false
  error = false
  error_message = ""
  isCompared = false;
  DiffTab: any = []


  constructor(
    private myexport: ExportService,
    private vms: VmsService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(downloadIcon, downloadCloudIcon, fileGroupIcon);

    this.loading = true
    this.loadingAll = true
    this.TabVMs = await this.vms.GetAllVMs()
    this.loading = false
    // Get Groups by VMs
    for (let vm of this.TabVMs){
      await this.vms.GetVMGroups(vm)
    }
    this.loadingAll = false
  }

  async onDetailOpen($event: any): Promise<void>{
    this.loadingDetail = true
    if ($event !== null){
      for (let rule of $event['ports'] ){
        await this.vms.GetRules(rule.segment_port, $event)
      }
    }
    this.loadingDetail = false
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

  ExportRules(type: string, detail: any){
    this.boolexport = true

    let TabRules = []
    let separator = ""
    if (type == 'XLS'){ separator = ', '}
    else{ separator = '/'}

    let TabTags = []
    for (let tag of detail.tags){
      if(tag.scope != ""){
        TabTags.push(tag.tag + ":" + tag.scope)
      }
      else{
        TabTags.push(tag.tag)
      }
    }
    for (let port of detail.ports){
      for( let sect of port.section_list){
        for( let rule of sect.rules){
          TabRules.push({
            'name': detail.name,
            'id': detail.id,
            'host': detail.host,
            'tags': TabTags.join(separator),
            'segments': detail.segments.join(separator),
            'groups': detail.groups.join(separator),
            'status': detail.status,
            'ports': port.port_id,
            'section': sect.name,
            'category': sect.cat,
            'rule': rule.name,
            'rule_id': rule.id,
            'source': rule.sources.join(separator),
            'destination': rule.destinations.join(separator),
            'services': rule.services.join(separator),
            'action': rule.action
          })
        }
      }
    }
    this.boolexport = false

    switch(type){
      case 'XLS': {
        let Formatdata = {
          'header': this.vms.Header_Rules,
          'data': TabRules,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.vms.RulesConditionalFormating)
        break;
      }
      case 'CSV': {
        this.myexport.generateCSV(detail.name + '_Rules', this.vms.Header_Rules, TabRules, true)
        break;
      }
      case 'JSON': {
        this.myexport.generateJSON(detail.name, detail)
        break;
      }
      case 'YAML': {
        this.myexport.generateYAML(detail.name, detail)
        break;
      }
      default:{
        let Formatdata = {
          'header': this.Header,
          'data': TabRules,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.vms.RulesConditionalFormating)
        break;
      }
    }
  }

  Export(type: string, Tab:any, PrefixName: any){
    let Export: any
    switch(type){
      case 'XLS': {
        Export = this.vms.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.vms.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.vms.formatDataExport(Tab, '/')
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
        Export = this.vms.formatDataExport(Tab, ', ')
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