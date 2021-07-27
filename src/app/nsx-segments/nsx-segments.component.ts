import { Component, Input, OnDestroy, OnInit } from '@angular/core';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { ExportService} from '../services/export.service';
import { SegmentsService} from '../services/segments.service'
import { ClarityIcons, fileGroupIcon, uploadIcon } from '@cds/core/icon';

import * as _ from "lodash";

@Component({
  selector: 'app-nsx-segments',
  templateUrl: './nsx-segments.component.html',
  styleUrls: ['./nsx-segments.component.css']
})
export class NsxSegmentsComponent implements OnInit, OnDestroy {
  @Input() DiffTab: any = []

  public mysession: LoginSession;
  TabSegments: any[] = [];
  Header = this.segment.Header
  HeaderDiff = this.segment.HeaderDiff
  Name = this.segment.Name

  loading = true
  error = false
  error_message = ""
  isCompared = false;

  constructor(
    private myexport: ExportService,
    private segment: SegmentsService,
    ) { 
    this.mysession = SessionService.getSession()
  }

   async ngOnInit(): Promise<void>{
    ClarityIcons.addIcons(uploadIcon, fileGroupIcon);
    // Get all segments and put them in an array of Object Segment
    this.TabSegments =  await this.segment.getSegments()
    this.loading = false
  }

  ngOnDestroy(): void{
  }

 getDiff(diffArrayOut: any){
   // Assign diff object in Array of HTML display
  this.DiffTab = _.values(diffArrayOut)
  this.isCompared = true
 }

  Export(type: string, Tab:any, PrefixName: any){
    let Export: any

    switch(type){
      case 'XLS': {
        Export = this.segment.formatDataExport(Tab, ', ')
        let Formatdata = {
          'header': this.Header,
          'data': Export,
          'name': this.Name
        }
        this.myexport.generateExcel(this.Name, [Formatdata], this.segment.ConditionalFormating)
        break;
      }
      case 'CSV': {
        Export = this.segment.formatDataExport(Tab, '/')
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
        Export = this.segment.formatDataExport(Tab, ', ')
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
