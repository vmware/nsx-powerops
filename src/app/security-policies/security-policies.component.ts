import { Component, Input, OnInit } from '@angular/core';
import {PoliciesService} from '../services/policies.service'
import { ExportService } from '../services/export.service';
import { ClarityIcons, fileGroupIcon, uploadIcon } from '@cds/core/icon';
import * as _ from 'lodash';

@Component({
  selector: 'app-security-policies',
  templateUrl: './security-policies.component.html',
  styleUrls: ['./security-policies.component.css']
})
export class SecurityPoliciesComponent implements OnInit {
  @Input() DiffTab: any = []
  loading = true
  isCompared = false;
  error = false
  error_message = ""

  TabPolicies: any;
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
    private policies: PoliciesService,
    private myexport: ExportService,
    ) { }

    async ngOnInit(): Promise<void>{
      ClarityIcons.addIcons(uploadIcon, fileGroupIcon);
      this.TabPolicies = await this.policies.getPolicies()
      this.loading = false
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

  Export(type: string, Tab:any, PrefixName: any){
    let Export: any

    switch(type){
      case 'XLS': {
        Export = this.policies.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata])
        break;
      }
      case 'CSV': {
        Export = this.policies.formatDataExport(Tab, '/')
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
        Export = this.policies.formatDataExport(Tab, ', ')
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
