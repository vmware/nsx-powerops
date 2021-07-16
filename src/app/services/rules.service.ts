import { Injectable } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { HttpClient} from '@angular/common/http';
import { Rule, Policy, Category } from '../class/Rules';
import { ToolsService } from '../services/tools.service';

@Injectable({
  providedIn: 'root'
})
export class RulesService {
  public mysession: LoginSession;
  public policy: Policy
  Name = "DFW_Rules"
  Header = [
    'Security Policy', 
    'Security Policy Applied to', 
    'Category',
    'Rule Name', 
    'Rule ID',
    'Source', 
    'Destination',
    'Services',
    'Profiles',
    'Rule Applied to',
    'Action',
    'Direction',
    'Disabled', 
    'IP Protocol',
    'Logged',
    'Diff Status'
  ]

  ConditionalFormating = {
    sheet: this.Name,
    column: [{
    columnIndex:  this.Header.indexOf('Action') + 1,
    rules: [{
      color: 'orange',
      text: 'DROP'
    },
    {
      color: 'red',
      text: 'REJECT'
    },
    {
      color: 'green',
      text: 'ALLOW'
    }]
    }]
  }


  constructor(
    private session: SessionService,
    private tools: ToolsService,
    public http: HttpClient
    ) { 
    this.mysession = SessionService.getSession()
  }

  async getPoliciesbyCat(): Promise<any>{
    // get Categories where there are somes rules
    let cat_json = await this.session.getAPI(this.mysession, '/policy/api/v1/search/groupBy?query=resource_type:SecurityPolicy&group_by_field=category&stats_fields=_meta.rule_count');
    // Get Policies
    let policies = await this.session.getAPI(this.mysession, '/policy/api/v1/infra/domains/default/security-policies');

    let result = await Promise.all([cat_json, policies])

    // Treatment categories
    let TabCat = []
    if (cat_json.result_count >0){
      for(let cat of cat_json.results){
        // Index for each categories
        let index: number
        if (cat.group_by_field_value == 'Ethernet'){ index = 1 }
        if (cat.group_by_field_value == 'Emergency'){ index = 2 }
        if (cat.group_by_field_value == 'Infrastructure'){ index = 3 }
        if (cat.group_by_field_value == 'Environment'){ index = 4 }
        if (cat.group_by_field_value == 'Application'){ index = 5 }

        let CatObj = new Category(cat.group_by_field_value, true, index, [])
        TabCat.push(CatObj)
      }
    }

    if (result[1].result_count > 0){
      for(let policy of policies.results){
        for(let cat of TabCat){
          if(policy.category == cat.name){
            let PolicyObj = new Policy(policy.display_name)
            PolicyObj.category = policy.category
            PolicyObj.scope = this.getListNameFromPath(policy.scope)
            PolicyObj.stateful = policy.stateful
            PolicyObj.id = policy.id
            PolicyObj.path = policy.path
            PolicyObj.sequence_nb = policy.sequence_number

            cat.policies.push(PolicyObj)
          }
        }
      }
    }
    return TabCat
  }

  getListNameFromPath(LIST: any){
    let returnlist = []
    for(let  element of LIST){
      if ('ANY' in LIST){
        returnlist = ['ANY']
      }
      else{
        let lenList = element.split('/').length
        returnlist.push(element.split('/')[lenList - 1])
      }
    }
    return returnlist
  }

  async getRulesbyPolicy(policy: Policy): Promise<any>{
    let TabRules = []
    const rules_json =  await this.session.getAPI(this.mysession, '/policy/api/v1/infra/domains/default/security-policies/' + policy.id + '/rules');

    if (rules_json.result_count > 0){
      for (let rule of rules_json.results){
        let RuleObj = new Rule(rule.display_name)
        RuleObj.scope = this.getListNameFromPath(rule.scope)
        RuleObj.policy = policy
        RuleObj.sources = this.getListNameFromPath(rule.source_groups)
        RuleObj.destinations = this.getListNameFromPath(rule.destination_groups)
        RuleObj.services = this.getListNameFromPath(rule.services)
        RuleObj.profile = this.getListNameFromPath(rule.profiles)
        RuleObj.scope = this.getListNameFromPath(rule.scope)
        RuleObj.action = rule.action
        RuleObj.direction = rule.direction
        RuleObj.state = rule.disabled
        RuleObj.logged = rule.logged
        RuleObj.id = rule.rule_id

        if ('ip_protocol' in rule){
          RuleObj.ip = rule.ip_protocol
        }

        TabRules.push(RuleObj)
      }
    }
    return TabRules
  }  


  formatDataExport(Tab: any, separator: string){
    let Tabline = []
    for( let rule of this.tools.FormatData(Tab, separator)){
      Tabline.push({
        'policy_name': rule.policy.name,
        'policy_scope': rule.policy.scope.join(separator),
        'category': rule.policy.category,
        'rule_name': rule.name,
        'id': rule.id,
        'sources': rule.sources,
        'destinations': rule.destinations,
        'services': rule.services,
        'profile': rule.profile,
        'rule_scope': rule.scope,
        'action': rule.action,
        'direction': rule.direction,
        'state': rule.state,
        'ip': rule.ip,
        'logged': rule.logged,
        'diffstatus': rule.diffstatus
      })
    }
    return Tabline
   }

  async getData(separator: string): Promise<any>{
    let TabCat: any[] = []
    TabCat = await this.getPoliciesbyCat()
    let TabRules: any[] = []

    for(let cat of TabCat){
      //get rules for each policy
      for(let policy of cat.policies){
        TabRules = TabRules.concat(await this.getRulesbyPolicy(policy))
      }
    }

    return TabRules
 }
}
