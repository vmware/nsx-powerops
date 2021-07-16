import { Component,  OnInit } from '@angular/core';
import { RulesService} from '../services/rules.service'
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { ExportService} from '../services/export.service';
import { ClrLoadingState } from '@clr/angular';
import { arrowIcon, ClarityIcons, fileGroupIcon, twoWayArrowsIcon, uploadIcon  } from '@cds/core/icon';
import * as _ from 'lodash';

@Component({
  selector: 'app-security-rules',
  templateUrl: './security-rules.component.html',
  styleUrls: ['./security-rules.component.css']
})
export class SecurityRulesComponent implements OnInit {
  public mysession: LoginSession;

  TabRules: any[] = [];
  TabPolicies: any[] = [];
  TabResult: any[] = [];
  TabCat: any[] = [];
  CatAllLoading = true
  error = false
  error_message = ""
  isCompared = false;
  DiffTab: any = []

  public loading: ClrLoadingState = ClrLoadingState.DEFAULT;

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

  HeaderDiff = [
    { header: 'Rule Name', col: 'name'},
    { header: 'Rule ID', col: 'id'},
    { header: 'Source', col: 'sources'},
    { header: 'Destination', col: 'destinations'},
    { header: 'Services', col: 'services'},
    { header: 'Action', col: 'action'},
    { header: 'Direction', col: 'direction'},
  ]

  constructor(
    private rules: RulesService,
    private myexport: ExportService,
    ) {
      this.mysession = SessionService.getSession()
     }

    async ngOnInit(): Promise<void>{
      ClarityIcons.addIcons(arrowIcon, twoWayArrowsIcon, uploadIcon, fileGroupIcon);
      this.TabCat = await this.rules.getPoliciesbyCat()
      // Sort Tab for having this: Ethernet, Emergency, Infrastructure, Environment, Application, Diff
      this.TabCat.sort(function(a, b) {
        // Compare the 2 index
        if (a.index < b.index) return -1;
        if (a.index > b.index) return 1;
        return 0;
      });

      for(let cat of this.TabCat){
        //get rules for each policy
        for(let policy of cat.policies){
          this.TabRules = this.TabRules.concat(await this.rules.getRulesbyPolicy(policy))
        }
        cat.loading = false
        if(cat.name == 'Application'){
          this.CatAllLoading = false
        }
      }
  }

  getDiff(diffArrayOut: any){
    this.DiffTab = _.values(diffArrayOut)
    this.isCompared = true
   }

  Export(type: string, Tab:any, PrefixName: any){
    let Export: any

    switch(type){
      case 'XLS': {
        Export = this.rules.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.rules.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.rules.formatDataExport(Tab, '/')
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
        Export = this.rules.formatDataExport(Tab, ', ')
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