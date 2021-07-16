import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { ToolsService } from '../services/tools.service';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { PlatformLocation } from '@angular/common';
import { VM, Interface } from '../class/VM';
import { Tag } from '../class/Tags';

@Injectable({
  providedIn: 'root'
})
export class VmsService {
  public mysession: LoginSession;
  public vm: VM

  Header= ['VMs Name', 'VMs ID', 'Tags', 'Host', 'Segments', 'Attachement ID','Group', 'Status', 'Diff Status']
  Header_Rules = ['VM Name', 'VM ID', 'Host', 'Tags', 'Segments', 'Groups', 'Status', 'Ports', 'Section', 'Categories', 'Rules Name', 'Rules ID', 'Source', 'Destination', 'Services', 'Action']
  Name = 'VMs'
  ConditionalFormating = {
    sheet: this.Name,
    column:   [
      {
      columnIndex:  this.Header.indexOf('Status') + 1,
      rules: [
      {
        color: 'red',
        text: 'VM_STOPPED'
      },
      {
        color: 'green',
        text: 'VM_RUNNING'
      }]
      },
    ]
  }
  RulesConditionalFormating = {
    sheet: this.Name,
    column:   [
      {
      columnIndex:  this.Header_Rules.indexOf('Action') + 1,
      rules: [
      {
        color: 'red',
        text: 'REJECT'
      },
      {
        color: 'orange',
        text: 'DROP'
      },
      {
        color: 'green',
        text: 'ALLOW'
      }]
      },
    ]
  }


  constructor(
    private session: SessionService,
    private tools: ToolsService,
    private plaformLocation: PlatformLocation,
    public http: HttpClient
    ) {
      this.mysession = SessionService.getSession()
     }

  async GetVMGroups(vm: VM){
    // Get Group of a VM
    const vms_group_url = '/policy/api/v1/global-infra/virtual-machine-group-associations?vm_external_id='

    let list_gp_json = await this.session.getAPI(this.mysession, vms_group_url + vm.id)
    if (list_gp_json.result_count > 0){
      for (let gp of list_gp_json.results){
        vm['groups'].push(gp.target_display_name)
      }
    }
  }

  async GetAllVMs(){
      let TabVMs: any[] = [];
      const vms_url = '/api/v1/fabric/virtual-machines';
      const lr_ports_url = '/api/v1/search/query?query=resource_type:LogicalPort';
      const lswitch_url = '/api/v1/logical-switches';
      const vif_url = '/api/v1/fabric/vifs';

      let vms_json =  this.session.getAPI(this.mysession, vms_url);
      let ls_json = this.session.getAPI(this.mysession, lswitch_url);
      let lrports_json =  this.session.getAPI(this.mysession, lr_ports_url);
      let vifs_json =  this.session.getAPI(this.mysession, vif_url);

      let result = await Promise.all([lrports_json, vms_json, ls_json, vifs_json])
      
      if (result[1].result_count > 0){
        for (let vm of result[1].results){
          let VMObj = new VM(vm.display_name)
          VMObj.status = vm.power_state
          VMObj.id = vm.external_id
          VMObj.host = vm.source.target_display_name

          // Get VIFs
          for (let vif of result[3].results){
            if (vif.owner_vm_id == vm.external_id){
              let int = new Interface(vif.display_name)
              int.vif_id = ""
              int.status = "DOWN"
              if ('lport_attachment_id' in vif){int.vif_id = vif.lport_attachment_id }
              int.section_list = []
              int.ip = []
              if (vif.ip_address_info.length > 0){
                int.ip = vif.ip_address_info[0].ip_addresses
              }
              int.mac = vif.mac_address
              VMObj.ports.push(int)
            }
          }
          // Get Segments attached to the VM
          for (let port of result[0].results){
            // Object rules for a port
            for (let int of VMObj.ports){
              if ('attachment' in port && port.attachment.id == int.vif_id){
                // Get Segment name from logical_switch_id
                result[2].results.forEach(element => {
                  if(element.id == port.logical_switch_id){
                    int.segment_name = element.display_name
                  }
                });
                int.status = port.status.status
                int.segment_port = port.id
              }
            }

            for (let ls of result[2].results){
              if ( port.display_name.indexOf(vm.display_name) >= 0&& port.logical_switch_id == ls.id){
                  VMObj.segments.push(ls.display_name)
                }
            }
          }
        // Get Tags
          if('tags' in vm ){
            for (let tag of vm.tags){
              let TagObj = new Tag(tag.tag)
              TagObj.scope = tag.scope
              VMObj.tags.push(TagObj)
            }
          }
          TabVMs.push(VMObj)
        }      
      }
       return TabVMs
  }

  async GetRules(port: any, vm: VM): Promise<void>{
    const dfw_url = '/nsxapi/rpc/call/FirewallFacade'
    const httpOptions = new HttpHeaders({
        'Content-Type':  'application/json',
        'Access-Control-Allow-Origin': '*',
        'Accept': '*/*',
        'NSX': this.mysession.nsxmanager,
        'Authorization': 'Basic ' + btoa(this.mysession.username + ':' + this.mysession.password),
        'Access-Control-Allow-Methods': 'OPTIONS, HEAD, GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type,Access-Control-Allow-Origin,Access-Control-Allow-Methods, Authorization'
    })
    // Get section
    let body = {"method":"listSections","id":1,"params":[{"applied_tos": port,"deep_search":true,"type":"LAYER3","page_size":1000}]}
    let sect = await this.http.post('http://' + this.plaformLocation.hostname + ':8080' + dfw_url, body, {'headers': httpOptions, 'observe': "response"}).toPromise()
    let result = []
    if ('result' in sect.body){
      result = sect.body['result']['results']
    }
    // get section rules for a VIF
    for (let int of vm['ports']){
      if (int.segment_port == port){
        // Initialize section
        int.section_list = []
        for (let section of result){
          int.section_list.push({id: section.id, name: section.display_name, cat: section.category, stateful: section.stateful })
        }
        // Get rules by Section for each VIF
        for (let sect of int['section_list']){
          sect['rules'] = []
          let httpbody = {"method":"getRules","id":1,"params":[ sect.id,{"applied_tos": port,"deep_search":true,"page_size":1000}]}
          let result = await this.http.post('http://' + this.plaformLocation.hostname + ':8080' + dfw_url, httpbody, {'headers': httpOptions}).toPromise()
          for (let rule of result['result']['results']){
            //get src
            let sources = []
            if ('sources' in rule){
              for (let src of rule.sources){
                sources.push(src.target_display_name)
              }
            }
            else{
              sources = ['any']
            }
             //get dest
             let destinations = []
             if ('destinations' in rule){
               for (let dst of rule.destinations){
                 destinations.push(dst.target_display_name)
               }
             }
             else{
               destinations = ['any']
             }
            //get port
            let ports = []
            if ('services' in rule){
              for (let port of rule.services){
                ports.push(port.target_display_name)
              }
            }
            else{
              ports = ['any']
            }
            sect['rules'].push({ name: rule.display_name, id: rule.id, sources: sources, destinations: destinations, services: ports, action: rule.action})
          }
       }
      }
    }
  }

  formatDataExport(TabVMs: any, separator: string){
    let Tabline = []
    // for( let vm of this.tools.FormatData(TabVMs, separator)){
    for( let vm of TabVMs){
      let TabTags = []
      let TabInt = []
      // Format Tag
      for (let tag of vm.tags){
          if(tag.scope != ""){
            TabTags.push(tag.tag + ":" + tag.scope)
          }
          else{
            TabTags.push(tag.tag)
          }
      }
      // Format Interface
      for (let int of vm.ports){
        TabInt.push(int.name)
      }
      Tabline.push({
        'name': vm.name,
        'id': vm.id,
        'tags': TabTags.join(separator),
        'host': vm.host,
        'segments': vm.segments.join(separator),
        'ports': TabInt.join(separator),
        'groups': vm.groups.join(separator),
        'status': vm.status,
        'diffstatus': vm.diffstatus
      })
    }
    return Tabline
  }

  async getData(): Promise<any> {
    // Get Data for audit
    let TabVMs= await this.GetAllVMs();
    for (let vm of TabVMs){
      await this.GetVMGroups(vm)
    }
    return TabVMs
  }
}
