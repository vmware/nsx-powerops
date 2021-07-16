import { Component,  Input,  OnInit } from '@angular/core';
import { FormGroup, FormControl } from '@angular/forms';
import { ExportService } from '../services/export.service';
import { SegmentsService } from '../services/segments.service';
import { LrsummaryService } from '../services/lrsummary.service';
import { LrportsService } from '../services/lrports.service';
import { BgpService } from '../services/bgp.service';
import { RoutingtablesService } from '../services/routingtables.service';
import { ManagerinfosService } from '../services/managerinfos.service';
import { TransportzoneService } from '../services/transportzone.service';
import { NsxservicesService } from '../services/nsxservices.service';
import { TunnelsService } from '../services/tunnels.service';
import { GroupsService } from '../services/groups.service';
import { PoliciesService } from '../services/policies.service';
import { RulesService } from '../services/rules.service';
import { TNstatusService } from '../services/tnstatus.service';
import { AlarmsService } from '../services/alarms.service';
import { TransportnodesService} from '../services/transportnodes.service'
import { VmsService} from '../services/vms.service'
import { IppoolService } from '../services/ippool.service'
import { bundleIcon, ClarityIcons, clusterIcon, fileGroupIcon, networkSwitchIcon, shieldIcon } from '@cds/core/icon';
import { HomeComponent } from '../home/home.component';
import * as _ from 'lodash';

@Component({
  selector: 'app-audit',
  templateUrl: './audit.component.html',
  styleUrls: ['./audit.component.css'],
})


export class AuditComponent implements OnInit {
  @Input() DiffTab: any = []

  Name = 'Audit'
  isCompared = false;

  tabfunction: {  [key: string]: any} = {
    ManagerInfos: this.managerinfos,
    TransportZones: this.tz,
    Nodes: this.tn,
    Tunnels: this.tunnels,
    Alarms: this.alarms,
    Segments: this.segments,
    LogicalRouters: this.lrsummary,
    LogicalPorts: this.lrports,
    BGP: this.bgp,
    RoutingTables: this.routingtables,
    Services: this.nsxservices,
    Groups: this.groups,
    Policies: this.policies,
    Rules: this.rules,
    IPpools: this.ippools,
    VMs: this.vms
  };

  TabAudit: any[] = [];
  TabConditionnalFormating: any[] = []
  ToggleState: { [key: string]: any} = {}
  AuditForm: FormGroup | undefined;
  ToggleAllFabricBoolean = false
  ToggleAllNetworkingBoolean = false
  ToggleAllSecurityBoolean = false
  LoadingallFabric = false
  LoadingallNetworking = false
  LoadingallSecurity = false
  loading = true

  NameMenu = ""
  loadingallconfig = false
  difftabloading = false
  getallconfig = true
  TabAllconfig: any = {}

  constructor(
    private segments: SegmentsService,
    private vms: VmsService,
    private myexport: ExportService,
    private nsxsegments: SegmentsService,
    private lrsummary: LrsummaryService,
    private lrports: LrportsService,
    private bgp: BgpService,
    private routingtables: RoutingtablesService,
    private managerinfos: ManagerinfosService,
    private tz: TransportzoneService,
    private nsxservices: NsxservicesService,
    private tunnels: TunnelsService,
    private groups: GroupsService,
    private policies: PoliciesService,
    private rules: RulesService,
    private alarms: AlarmsService,
    private tnstatus: TNstatusService,
    private tn: TransportnodesService,
    private ippools: IppoolService,
    public listmenu: HomeComponent,
    ) { }



  async ngOnInit(): Promise<void> {
    ClarityIcons.addIcons(shieldIcon, clusterIcon, networkSwitchIcon, fileGroupIcon, bundleIcon);

    for (let tg of this.listmenu.TabFabric){
      this.ToggleState[tg.id] = tg.isActive
      this.AuditForm?.addControl(tg.id, new FormControl(tg.isActive))
    }
    for (let tg of this.listmenu.TabNetwork){
      this.ToggleState[tg.id] = tg.isActive
      this.AuditForm?.addControl(tg.id, new FormControl(tg.isActive))
    }
    for (let tg of this.listmenu.TabSecurity){
      this.ToggleState[tg.id] = tg.isActive
      this.AuditForm?.addControl(tg.id, new FormControl(tg.isActive))
    }
  }

  isObject(val: any): boolean {
    if(typeof(val) === 'object'){
      return true
    }
    return false
  }

  isArray(val: any): boolean{
    if (Array.isArray(val)){
      return true
    }
    return false
  }

  isArrayofObject(val: any): boolean {
    if (Array.isArray(val)){
      for(let item of val){
        if (typeof(item) === 'object'){
          return true
        }
        return false
      }
    }
    return false
  }

  async getDiff(diffArrayOut: any){
    this.difftabloading = true
    let tempTab = {}
    for(let key of Object.keys(diffArrayOut)){
      tempTab = Object.assign({key}, diffArrayOut[key])
      this.DiffTab.push(tempTab)
    }
    this.isCompared = true
    this.difftabloading = false
 }

  async getAllConfig(typeexport: string){
    this.loadingallconfig = true
    // Check if all config is already in memory
    if(Object.keys(this.TabAllconfig).length === 0){
      // Get all config for Fabric menu
      for (let menu of this.listmenu.TabFabric){
        this.NameMenu = menu.id
        this.TabAllconfig[menu.id] = { 'items': "", 'diffstatus': ""}
        this.TabAllconfig[menu.id]['items'] = await this.tabfunction[menu.id].getData()
        this.TabConditionnalFormating.push(this.tabfunction[menu.id].ConditionalFormating)
        this.TabAllconfig[menu.id]['diffstatus'] = ""
      }
      // Get all config for network menu
      for (let menu of this.listmenu.TabNetwork){
      this.NameMenu = menu.id
      this.TabAllconfig[menu.id] = { 'items': "", 'diffstatus': ""}
       // Routing Tables audit is have already tabs, so need to concat the array from getData of Routing Tables with the global one 
      if (menu.id == 'RoutingTables'){
        let allroutes = []
        let allrt = await this.tabfunction[menu.id].getData(',')
        // get and concat routing table of T0 and T1
        for (let rt of allrt){
          allroutes = allroutes.concat(rt.data)
        }
        this.TabAllconfig[menu.id]['items'] = allroutes
        this.TabAllconfig[menu.id]['diffstatus'] = ""

      }
      else{
        this.TabAllconfig[menu.id]['items'] = await this.tabfunction[menu.id].getData(',')
        this.TabConditionnalFormating.push(this.tabfunction[menu.id].ConditionalFormating)
        this.TabAllconfig[menu.id]['diffstatus'] = ""

      }
      }
      // Get all config for security menu
      for (let menu of this.listmenu.TabSecurity){
      this.NameMenu = menu.id
      this.TabAllconfig[menu.id] = { 'items': "", 'diffstatus': ""}
      this.TabAllconfig[menu.id]['items'] = await this.tabfunction[menu.id].getData(',')
      this.TabConditionnalFormating.push(this.tabfunction[menu.id].ConditionalFormating)
      this.TabAllconfig[menu.id]['diffstatus'] = ""
      }
    }
    if(typeexport === 'JSON'){
      this.myexport.generateJSON('Config', this.TabAllconfig)
    }
    else{
      this.myexport.generateYAML('Config', this.TabAllconfig)
    }
    this.loadingallconfig = false
    this.getallconfig = true
  }

  async ToggleAllFabric(){
    this.LoadingallFabric = true
    if(this.ToggleAllFabricBoolean){
      for (let tg of this.listmenu.TabFabric){
        this.ToggleState[tg.id] = true
        await this.toggle(tg.id).then (result => {
          this.LoadingallFabric = false
          this.LoadingallNetworking = false
          this.LoadingallSecurity = false
        })
      }
    }
    else{
      for (let tg of this.listmenu.TabFabric){
        this.ToggleState[tg.id] = false
      }
    }
  }

  async ToggleAllNetworking(){
    this.LoadingallNetworking = true
    if(this.ToggleAllNetworkingBoolean){
      for (let tg of this.listmenu.TabNetwork){
        this.ToggleState[tg.id] = true
        await this.toggle(tg.id)
      }
    }
    else{
      for (let tg of this.listmenu.TabNetwork){
        this.ToggleState[tg.id] = false
      }
    }
    this.LoadingallFabric = false
    this.LoadingallNetworking = false
    this.LoadingallSecurity = false
  }

  async ToggleAllSecurity(){
    this.LoadingallSecurity = true
    if(this.ToggleAllSecurityBoolean){
      for (let tg of this.listmenu.TabSecurity){
        this.ToggleState[tg.id] = true
        await this.toggle(tg.id)
      }
    }
    else{
      for (let tg of this.listmenu.TabSecurity){
        this.ToggleState[tg.id] = false
      }
    }
    this.LoadingallFabric = false
    this.LoadingallNetworking = false
    this.LoadingallSecurity = false
  }

  async toggle(name: any){
    if (!this.ToggleAllFabric || !this.ToggleAllNetworking || !this.ToggleAllSecurity){
     this.loading = true
    }
    // Routing Tables audit is have already tabs, so need to concat the array from getData of Routing Tables with the global one 
   if (this.ToggleState[name] && name == 'RoutingTables'){
     this.NameMenu = name
     let tabrouting = await this.tabfunction[name].getData()
     // Add ToggleID
     for (let tb of tabrouting){
       tb['toggleID'] = name
     }
     this.TabAudit = this.TabAudit.concat(tabrouting)
   }
   else if (this.ToggleState[name]){
     this.NameMenu = name
     this.TabConditionnalFormating.push(this.tabfunction[name].ConditionalFormating)
     this.TabAudit.push({
       'header': this.tabfunction[name].Header,
       'toggleID' : name,
       'name': this.tabfunction[name].Name,
       'data': await this.tabfunction[name].getData()
     })
   }
   else{
     // Case if user toggle off one audit : remove from audit array, the tab
     let index = this.TabAudit.findIndex(x => x.name === name);
     this.TabAudit.splice(index, 1);
   }
   this.loading = false
 }

  onExportDiff(type: string, Tab: any, filename: string){
  if(type === 'JSON'){
    this.myexport.generateJSON(filename, Object.assign({}, Tab))
  }
  else{
    this.myexport.generateYAML(filename, Object.assign({}, Tab))
  }
  }

  Format(Tab: any, separator: string){
    let CpTab  = []
    for(let element of Tab){
      let Formatdata = {
        'header': element.header,
        'toggleID': element.toggleID,
        'name': element.name
      }
      Formatdata['data'] = this.tabfunction[element.toggleID].formatDataExport(element.data, separator)
      CpTab.push(Formatdata)
    }
    return CpTab
  }

  // On submit of EXPORT Button
  onSubmit(typeexport: string){
    switch(typeexport){
      case 'XLS': {
        // Create XLS file
        let tab = this.Format(this.TabAudit, ',')
        this.myexport.generateExcel('Audit', tab, this.TabConditionnalFormating)
        break;
      }
      case 'CSV': {
        let tab = this.Format(this.TabAudit, ';')
        this.myexport.createZIPFile(tab, 'CSV')
        break;
      }
      case 'JSON': {
        let ExportData = []
        for ( let item of this.TabAudit){
          let itemobj = {}
          itemobj['key'] = item.toggleID
          itemobj['items'] = item.data
          itemobj['diffstatus'] = ""
          ExportData.push(itemobj)
        }
        this.myexport.generateJSON('Audit_JSON', ExportData)
        break;
      }
      case 'ZIPJSON': {
        this.myexport.createZIPFile(this.TabAudit, 'JSON')
        break;
      }
      case 'YAML': {
        let ExportData = []
        for ( let item of this.TabAudit){
          let itemobj = {}
          itemobj['key'] = item.toggleID
          itemobj['items'] = item.data
          itemobj['diffstatus'] = ""
          ExportData.push(itemobj)
        }
        this.myexport.generateYAML('Audit_YAML', ExportData)
        break;
      }
      case 'ZIPYAML': {
        this.myexport.createZIPFile(this.TabAudit, 'YAML')
        break;
      }
      default:{
        break;
      }
    }
     // reset Toggle
     this.TabAudit = []
     this.TabConditionnalFormating = []
     this. NameMenu = ""
     this.loading = true
     this.ToggleAllFabricBoolean = false
     this.ToggleAllNetworkingBoolean = false
     this.ToggleAllSecurityBoolean = false
     for (let toggle in this.ToggleState){
       this.ToggleState[toggle] = false
     }
  }


}
