import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { Group, Expression } from '../class/Group';
import { Tag } from '../class/Tags';
import { ToolsService } from '../services/tools.service';

@Injectable({
  providedIn: 'root'
})
export class GroupsService {
  public mysession: LoginSession;
  Name = "Groups"
  Header = ['Group Name', 'Tags', 'Scope', 'Criteria Type', 'Criteria', 'IP addresses', 'Virtual Machines', 'Segments', 'Segments Ports', 'Diff Status']
  Groups_json: any

  constructor(
    private session: SessionService,
    private tools: ToolsService
    ) { 
    this.mysession = SessionService.getSession()
  }

  formatDataExport(TabGrp: any, separator: string){
    let TabLine = []
    for(let grp of TabGrp){
      TabLine.push(this.formatGrp(grp, separator))
    }
    return TabLine
  }

  formatGrp(Grp: any, separator: string){
    let Tabtags = []
    let Tabscope = []
    if (Grp.hasOwnProperty('tags')){
      for(let tag of Grp.tags){
        Tabtags.push(tag.tag)
        Tabscope.push(tag.scope)
      }
    }
    let Tabcriteria = []
    if (Grp.hasOwnProperty('tmp_expression')){
      for (let crt of Grp.tmp_expression){
        if (crt.resource_type === 'Condition'){
          if (crt.key === 'tag'){
            Tabcriteria.push(crt.member_type + " with " + crt.key + " " + crt.operator + " " + crt.value.tag +":" +crt.value.scope)
          }
          else{
            Tabcriteria.push(crt.member_type + " with " + crt.key + " " + crt.operator + " " + crt.value)
          }
        }
        else if(crt.resource_type === 'PathExpression') {
          Tabcriteria.push(crt.member_type + " equal to " + crt.value.join(separator))
        }
        else if(crt.resource_type === 'ConjunctionOperator') {
          Tabcriteria.push(crt.value)
        }
        else if(crt.resource_type === 'ExternalIDExpression') {
          Tabcriteria.push(crt.member_type + " equal to " + crt.value.join(separator))
        }
        else{
          Tabcriteria.push(Grp.criteria)
        }
      }
    }
    let line = {
      'name': Grp.name,
      'tags': Tabtags.join(separator),
      'scope': Tabscope.join(separator),
      'type_criteria': Grp.type_criteria.join(separator),
      'criteria': Tabcriteria.join(separator),
      'ip': Grp.ip.join(separator),
      'vm': Grp.vm.join(separator),
      'segment': Grp.segment.join(separator),
      'segment_port': Grp.segment_port.join(separator),
      'diffstatus': Grp.diffstatus
    }
    return line
  }

  async getAllGroups(domain_id: string): Promise<any>{
    let TabGroup = []
    this.Groups_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/domains/' + domain_id + '/groups');
    if (this.Groups_json.result_count > 0){
      for(let gp of this.Groups_json.results){
        let GrpObj = new Group(gp.display_name)
        GrpObj.path = gp.path
        GrpObj.expression = gp.expression 

        if ('tags' in gp){
          for (let tag of gp.tags){  
            let TagObj = new Tag(tag.tag)
            TagObj.scope = tag.scope
            GrpObj.tags.push(TagObj)
          }
        }
        //Criteria Treatment
         let criteria: any = []
         for(let dictcriteria of gp.expression){
           criteria = await this.getCriteria(dictcriteria, GrpObj)
         }

        TabGroup.push(GrpObj) 
      }
    }
    return TabGroup
  }
  
  async getCriteria(DictExpression: any, GrpObj: any): Promise<any>{

    switch(DictExpression.resource_type){
      case 'ConjunctionOperator': {
        let exp = new Expression('ConjunctionOperator')
        exp.value = DictExpression.conjunction_operator
        GrpObj.tmp_expression.push(exp)
        break
      }
      case 'ExternalIDExpression':{
        GrpObj.type_criteria.push('ExternalID')
        let exp = new Expression('ExternalIDExpression')
        exp.member_type = DictExpression.member_type
        exp.value = []
        const vms_url = '/api/v1/fabric/virtual-machines';
        let vms_json =  await this.session.getAPI(this.mysession, vms_url);
        for(let item of DictExpression.external_ids){
          for(let vm of vms_json.results){
            if(vm.external_id === item){
              exp.value.push(vm.display_name)
            }
          }
        }
        GrpObj.tmp_expression.push(exp)
        break
      }
      case 'PathExpression':{
        GrpObj.type_criteria.push('Members')
        let exp = new Expression('PathExpression')
        exp.value = []
        let TabGrp = []
        for(let path of DictExpression['paths']){
          // Get name of the group
          let tmp = path.split("/")
          let Group_ID = tmp[tmp.length-1]
          exp.member_type = tmp[tmp.length-2]
          exp.value.push(Group_ID)
          // exp.operator = 'equals'
          for (let grp of this.Groups_json.results){
            if( Group_ID === grp.id){
              TabGrp.push(grp.display_name)
              exp.value.push(grp.display_name)
            }
          }
        }
        GrpObj.tmp_expression.push(exp)
        break
      }
      case 'NestedExpression':{
        GrpObj.type_criteria.push('Nested')
        let exp = new Expression('NestedExpression')

        for (let expression of DictExpression['expressions']){
          let ct = this.getCriteria(expression, GrpObj)
        }
        GrpObj.tmp_expression.push(exp)
        break
       }
      case 'MACAddressExpression':{
        GrpObj.type_criteria.push('MAC Address')
        let exp = new Expression('MACAddressExpression')
        exp.value = DictExpression['mac_addresses']
        GrpObj.criteria = DictExpression['mac_addresses']
        GrpObj.tmp_expression.push(exp)
        break
      }
      case 'IPAddressExpression':{
        GrpObj.type_criteria.push('IP Address')
        let exp = new Expression('IPAddressExpression')
        exp.value = DictExpression['ip_addresses']
        GrpObj.criteria = DictExpression['ip_addresses']
        GrpObj.tmp_expression.push(exp)
        break
      }
      case 'Condition':{
        GrpObj.type_criteria.push('Condition')
        let exp = new Expression('Condition')
        exp.member_type = DictExpression.member_type
        exp.operator = DictExpression.operator.toLowerCase()
        exp.key = DictExpression.key.toLowerCase()
        if(exp.key == 'tag'){
          exp.value = new Tag(DictExpression.value.split('|')[0])
          exp.value.scope = DictExpression.value.split('|')[1]
        }
        else{
          exp.value = DictExpression.value
        }
        GrpObj.tmp_expression.push(exp)
        break
      }
    }
  }

  async getDetail(group: Group): Promise<any>{

    let GrpObj = group
    const ip_json =  this.session.getAPI(this.mysession, '/policy/api/v1' + GrpObj.path + '/members/ip-addresses');
    const VMList_Obj =  this.session.getAPI(this.mysession, '/policy/api/v1' + GrpObj.path + '/members/virtual-machines');
    const SegList_Obj =  this.session.getAPI(this.mysession,  '/policy/api/v1' + GrpObj.path + '/members/logical-switches');
    const SegPortList_Obj =  this.session.getAPI(this.mysession, '/policy/api/v1' + GrpObj.path + '/members/logical-ports');
    let result = await Promise.all([ip_json, VMList_Obj, SegList_Obj, SegPortList_Obj])

    // Create IP Address List for each group
    if (result[0].result_count > 0){ 
      GrpObj.ip = result[0].results 
    } 
    //Create Virtual Machine List for each group
    let VMList: any[] =[]
    if (result[1].result_count > 0){ 
      for (let vm of result[1].results){
        VMList.push(vm.display_name)
      }
      GrpObj.vm = VMList
    }
    //Create Segment List for each group
    if (result[2].result_count > 0){
      for (let seg of result[2].results){
        if (!GrpObj.segment.includes(seg.display_name)){
          GrpObj.segment.push(seg.display_name)
        }
      }
    }
    // Create Segment Port/vNIC List for each group
    let SegPortList: any[] = []
    if (result[3].result_count > 0){
      for (let segport of result[3].results){
        SegPortList.push(segport.display_name)
      }
      GrpObj.segment_port = SegPortList
    }
    return GrpObj
  }

  async getData(separator: string): Promise<any>{
    let VM: any
    let IP: any
    let domain_id = "default";
    // Get Data for audit
    let Tabline = []
    let TabGroups= await this.getAllGroups(domain_id);
    for (let gp of TabGroups){
      await this.getDetail(gp)
      Tabline.push(gp)
    }
    return Tabline
  }
}
