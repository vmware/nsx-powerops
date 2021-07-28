import { Component, Input, OnDestroy, OnInit } from '@angular/core';
import { GroupsService } from '../services/groups.service'
import { ExportService} from '../services/export.service';
import { ClarityIcons, downloadCloudIcon, fileGroupIcon } from '@cds/core/icon';
import * as _ from 'lodash';

@Component({
  selector: 'app-security-groups',
  templateUrl: './security-groups.component.html',
  styleUrls: ['./security-groups.component.css']
})
export class SecurityGroupsComponent implements OnInit, OnDestroy {
  @Input() DiffTab: any = []
  loading = true
  loadingdiff = true
  isCompared = false;
  error = false
  error_message = ""
  exportxls = false

  TabGroups: any[] = [];
  TabforDiff: any[] = []

  Name = this.group.Name
  Header = this.group.Header
  HeaderDiff = this.group.HeaderDiff
  
  NbGroups = 0
  Value = 0
  GroupName = ""

  constructor(
    public group: GroupsService,
    private myexport: ExportService,
    ) {}

  async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(downloadCloudIcon, fileGroupIcon );

    let domain_id = "default";
    this.TabGroups = await this.group.getAllGroups(domain_id)
    this.loading = false
    this.TabforDiff = await this.getAllGroupsDetailed()
    this.loadingdiff = false
  }
 
  ngOnDestroy(): void{
  }

  onDetailOpen($event: any){
    if ($event !== null){
      this.group.getDetail($event)
    }
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


  async getAllGroupsDetailed(){
     
    let TabExport = []
    for (let gp of this.TabGroups){
      // get detail for each group
      await this.group.getDetail(gp).then( (grpobj: any) => {
        this.GroupName = gp.name
        TabExport.push(grpobj)
      })
    }
    return TabExport
  }

  // Export XLS file
  async Export(type: string, Tab:any, PrefixName: any){
    let Export: any

    switch(type){
      case 'XLS': {
        Export = this.group.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata])
        break;
      }
      case 'CSV': {
        Export = this.group.formatDataExport(Tab, '/')
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
        Export = this.group.formatDataExport(this.TabforDiff, ', ')
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
