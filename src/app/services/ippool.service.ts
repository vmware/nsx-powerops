import { Injectable } from '@angular/core';
import { IPBlock, IPPool, Range} from '../class/IPPool'
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';

@Injectable({
  providedIn: 'root'
})
export class IppoolService {
  public mysession: LoginSession;
  /**
    Header Definition for Excel Sheet
   */
    Header= ['IP Pool Name', 'IP Pool ID', 'Range', 'IP Block', 'Diff status' ]
    /**
    Name of Tab in Excel
   */
    Name = 'IP_Pools'

  constructor(

    private session: SessionService,

  ) {
    this.mysession = SessionService.getSession()
   }


  async getIPPool(){
    let TabIPPool: any[] = []
    let resultjson =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/ip-pools');

    if (resultjson.result_count > 0){
      for (let ippool of resultjson.results){
        let IPPoolObj = new IPPool(ippool.display_name, ippool.id)
        IPPoolObj.Range = []
        let pool_json = await this.session.getAPI(this.mysession, '/policy/api/v1/infra?base_path=/infra/ip-pools/' + IPPoolObj.id);

        for (let child of pool_json.children){

          for (let ippooladdress of child.IpAddressPool.children){
            let RangeObj: Range

            if ('IpAddressPoolSubnet' in ippooladdress){
              RangeObj = new Range(ippooladdress.IpAddressPoolSubnet.cidr)
              RangeObj.allocation_ranges = []  

              if ('allocation_ranges' in ippooladdress.IpAddressPoolSubnet && ippooladdress.IpAddressPoolSubnet.allocation_ranges.length > 0){
                for (let allocatedrange of ippooladdress.IpAddressPoolSubnet.allocation_ranges){
                  let IPBlockObj = new IPBlock(allocatedrange.start,allocatedrange.end )
                  RangeObj.allocation_ranges.push(IPBlockObj)
                }
              }
            }
            else{
              RangeObj = new Range('')
              RangeObj.allocation_ranges = []  
            }

            IPPoolObj.Range.push(RangeObj)
          }
        }
        TabIPPool.push(IPPoolObj)
      }
    }
    return TabIPPool
  }

  formatDataExport(TabIppool: any, separator: string){
    let Tabline = []
    for( let ippool of TabIppool){
      let TabRange = []
      let TabBlock = []
      for (let range of ippool.Range){
        TabRange.push(range.cidr)
        if('allocation_ranges' in range){
          for (let block of range.allocation_ranges){
            let blockstring = block.start + '-' + block.end
            TabBlock.push(blockstring)
          }
        }
      }
      Tabline.push({
        'name': ippool.name,
        'id': ippool.id,
        'range': TabRange.join(separator),
        'block': TabBlock.join(separator),
        'diffstatus': ippool.diffstatus
      })
    }
    return Tabline
  }

  async getData(separator: string): Promise<any> {
    // Get Data for audit
    return await this.getIPPool()
    }
}
