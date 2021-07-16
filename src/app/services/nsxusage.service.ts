import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { Usage } from '../class/ClusterNSX'

@Injectable({
  providedIn: 'root'
})
export class NsxusageService {
  public mysession: LoginSession;

  constructor(
    private session: SessionService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  async getUsage(): Promise<any>{
    let TabInventory: any[] = [];
    let TabNetwork: any[] = [];
    let TabSecurity: any[] = [];

    const inventory_json =  await this.session.getAPI(this.mysession, '/api/v1/capacity/usage?category=inventory');
    const network_json =  await this.session.getAPI(this.mysession, '/api/v1/capacity/usage?category=networking');
    const security_json =  await this.session.getAPI(this.mysession, '/api/v1/capacity/usage?category=security');
    
    let result = await Promise.all([inventory_json, network_json, security_json])
    // get Inventory usage
    for( let n of result[0].capacity_usage){
      TabInventory.push(new Usage(n.display_name,n.current_usage_count, n.max_supported_count, n.current_usage_percentage))
    }
    
    // get Network usage
    for( let n of result[1].capacity_usage){
      TabNetwork.push(new Usage(n.display_name,n.current_usage_count, n.max_supported_count, n.current_usage_percentage))
    }
    
    // get Security usage
    for( let n of result[2].capacity_usage){
      TabSecurity.push(new Usage(n.display_name,n.current_usage_count, n.max_supported_count, n.current_usage_percentage))
    }
    
    return [TabInventory, TabNetwork, TabSecurity]
  }
}
