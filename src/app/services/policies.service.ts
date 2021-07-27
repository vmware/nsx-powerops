import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { Policy} from '../class/Rules'

@Injectable({
  providedIn: 'root'
})
export class PoliciesService {
  public mysession: LoginSession;
  Header= ['Security Policies ID', 'Security Policy Name', 'NSX Policy Path', 'Sequence Number', 'Category', 'is Stateful', 'Diff Status' ]
  HeaderDiff = [
    { header: 'Security Policies ID', col: 'id'},
    { header: 'Security Policy Name', col: 'name'},
    { header: 'NSX Policy Path', col: 'path'},
    { header: 'Sequence Number', col: 'sequence_nb'},
    { header: 'Category', col: 'category'},
    { header: 'is Stateful', col: 'stateful'},
  ]
  Name = "Security_Policies"
  
  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }


  async getPolicies(): Promise<any>{
    let TabPolicies: any[] = [];
    const policies_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/domains/default/security-policies');

    if (policies_json.result_count > 0){
      for (let policy of policies_json.results){
        let PolObj = new Policy(policy.display_name)
        PolObj.id = policy.id
        PolObj.path = policy.path
        PolObj.sequence_nb = policy.sequence_number
        PolObj.category = policy.category
        PolObj.stateful = policy.stateful
        TabPolicies.push(PolObj)
      }
    }
    return TabPolicies
  }

  formatDataExport(Tab: any, separator: string){
    let Tabline = []
    for( let policy of Tab){
      Tabline.push({
        'id': policy.id,
        'name':  policy.name,
        'path': policy.path,
        'sequence_number': policy.sequence_nb,
        'category': policy.category,
        'stateful': policy.stateful,
        'diffstatus': policy.diffstatus
      })
    }
    return Tabline
   }

  async getData(separator: string): Promise<any>{
    return  await this.getPolicies()
  }
}
