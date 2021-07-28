import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { Service, Entry } from '../class/Services';

@Injectable({
  providedIn: 'root'
})
export class NsxservicesService {
  public mysession: LoginSession;
  Header= ['Name', 'ID', 'Created By', 'Protocol', 'Sources', 'Destinations','Description','Tags', 'Diff Status' ]
  Name = "Services"
  HeaderDiff = [
    { header: 'Name', col: 'name'},
    { header: 'ID', col: 'id'},
    { header: 'Created By', col: 'createdby'},
    { header: 'Protocol', col: 'entries', subcol: 'protocol'},
    { header: 'Sources', col: 'entries', subcol: 'sources'},
    { header: 'Destinations', col: 'entries', subcol: 'destinations'},
    { header: 'Description', col: 'description'},
    { header: 'Tags', col: 'tags'},
  ]
  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  async getServices(): Promise<any>{
    let TabSrv: any[] = [];
    const services_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/services');

    if(services_json.result_count > 0){
      for (let sr of services_json.results){
        let SrvObj = new Service(sr.display_name, [])
        SrvObj.createdby = sr._create_user
        SrvObj.description =sr.description
        SrvObj.resource_type =sr.resource_type
        SrvObj.id = sr.id
        SrvObj.tags = []
  
        if ('tags' in sr){
          for (let tag of sr.tags){    
            SrvObj.tags.push({'tag': tag.tag, 'scope': tag.scope})
          }
        }
        for (let svc of sr.service_entries){
          let EntryObj = new Entry(svc.display_name)
          EntryObj.destinations = 'ANY'
          EntryObj.sources = 'ANY'
  
          if ('l4_protocol' in svc){
            EntryObj.protocol = svc.l4_protocol
            if (svc.source_ports.length >0){
              EntryObj.sources = svc.source_ports
            }
            EntryObj.destinations = svc.destination_ports
          } 
          else if ('protocol' in svc){ 
            EntryObj.protocol = svc.protocol
            if ("icmp_type" in svc){
              EntryObj.destinations = svc.icmp_type
            }
          }
          else if("alg" in svc){
            EntryObj.protocol = svc.alg
            EntryObj.destinations = svc.destination_ports
          }
          else if ("protocol_number" in svc){ 
            // List_Proto.push(svc.protocol_number) 
          }
          else if ("ether_type" in svc) { 
            // List_Proto.push(svc.ether_type) 
          }    
          else {
            EntryObj.protocol = 'IGMP'
          }
          
          SrvObj.entries.push(EntryObj)
        }
        TabSrv.push(SrvObj)
      }
    }
    return TabSrv
  }

  formatDataExport(TabServices: any, separator: string){
    let destination: any
    let source: any
    let Tabline = []
    let TabTags = []
    for( let srv of TabServices){
      for (let tag of srv.tags){
        TabTags.push(tag.tag + ":" + tag.scope)
      }
      for(let entry of srv.entries){
        destination = entry.destinations
        source = entry.sources
        if (Array.isArray(entry.destinations)){
          destination = entry.destinations.join(separator)
        }
        if (Array.isArray(entry.sources)){
          source = entry.sources.join(separator)
        }
       
        Tabline.push({
          'name': srv.name,
          'id': srv.id,
          'createdby': srv.createdby,
          'protocol': entry.protocol,
          'source': source,
          'destination': destination,
          'description': srv.description,
          'tags': TabTags.join(separator),
          'diffstatus': srv.diffstatus
        })
      }
    }
    return Tabline
  }

  async getData(): Promise<any> {
    // Get Data for audit
    return await this.getServices();
  }
}
