import { Component, Input, OnInit, OnDestroy, ViewChild, Output, ElementRef, EventEmitter} from '@angular/core';
import { FormControl, FormGroup,  Validators } from '@angular/forms';
import { ToolsService } from '../services/tools.service';
import { ExportService} from '../services/export.service';
import { DiffParam } from '../class/DiffParam';
import {ClrWizard} from "@clr/angular";
import * as yaml from 'yaml'

@Component({
  selector: 'app-diff',
  templateUrl: './diff.component.html',
  styleUrls: ['./diff.component.css']
})
export class DiffComponent implements OnInit, OnDestroy {
  mdOpen = false;
  stepFirstNextButtonEnable = true;
  stepSecondNextButtonEnable = true;
  @ViewChild("wizardReference") wizard: ClrWizard;
  @ViewChild("originalfile") FirstFile: ElementRef;
  @ViewChild("comparefile") CompareFile: ElementRef;

  @Input() Tab: any[];
  @Input() Name: string
  @Output() diffArrayOut: EventEmitter<any> = new EventEmitter(true)

  private wizardform: FormGroup;
  private DiffParam: DiffParam

  Object = Object;
  DisplayComparedObject: any
  DisplayFile: any
  SecondFileName: string = ""
  FirstFileName: string = ""
  DiffResult: any[] = []
  CompactedDiffResult: any = []

  error = false
  error_message = ""

  
  constructor(
    public myexport: ExportService,
    private tools: ToolsService
    ) {
      this.FirstFile = null
      this.CompareFile = null
    }

  ngOnInit(): void {
    this.DiffParam = new DiffParam('', [], '', [])
    this.wizardform = new FormGroup({
      originalfile: new FormControl(this.DiffParam.originalfile, Validators.required),
      originalcode: new FormControl(this.DiffParam.originalcode),
      comparefile: new FormControl(this.DiffParam.comparefile),
      comparecode: new FormControl(this.DiffParam.comparecode, Validators.required),
    });
  }

  StartWizard() {
    this.reset()
    this.mdOpen = true
    this.DisplayComparedObject = JSON.stringify(this.Tab, null, 2)
    if(this.DisplayComparedObject === '[]'){
      this.DisplayComparedObject = ""
    }
  }

  onFileChanged(event: any) {
    if (event.target.files.length > 0){
      const filedump = event.target.files[0];
      const reader = new FileReader();
      let result: any
      reader.onload = (e) => {
        
        switch (filedump.type) {
          case 'application/x-yaml': {
            result =  yaml.parse(reader.result.toString());
            this.DisplayFile = yaml.stringify(result, null)
            break;
          }
          case 'application/json': {
            result = JSON.parse(reader.result.toString());
            this.DisplayFile = JSON.stringify(result, null, 2)
            break;
          }
        }
        if (event.target.name == 'originalfile'){
          this.stepFirstNextButtonEnable = false
          this.wizardform.patchValue  ({
            originalfile: event.target.files[0] ,
            originalcode: result
          })
        }
        if (event.target.name == 'comparefile'){
          this.stepSecondNextButtonEnable = false
          this.wizardform.patchValue  ({
            comparefile: event.target.files[0],
            comparecode: result
          })
          this.DisplayComparedObject = this.DisplayFile
        }
      }
      reader.readAsText(filedump);
    }
    else{
      this.DisplayFile = ""
      this.DisplayComparedObject = ""
    }
  }

  clearFileSelection() {
    this.FirstFile.nativeElement.value = null;
    this.CompareFile.nativeElement.value = null;
}

  async onSubmit(){
    // Check if compare file is empty. If so put current Tab on comparecode
    if(this.wizardform.value.comparecode == null || this.wizardform.value.comparecode.length === 0 ){
      this.wizardform.patchValue  ({
        comparecode: this.Tab
      })
    }
    // this.DiffResult = []
    this.wizardform.updateValueAndValidity()
    if (this.wizardform.valid) {
      if (!this.wizardform.value.comparefile || this.wizardform.value.originalfile.name.split('.').pop() == this.wizardform.value.comparefile.name.split('.').pop() ){
          this.DiffResult = await this.tools.getDiffTab(this.wizardform.value.originalcode, this.wizardform.value.comparecode)
          // Filed the compacted Tab for Yaml and JSON export
          for (let key of Object.keys(this.DiffResult)){
            if (this.DiffResult[key].diffstatus !== 'Unchanged'){
              this.CompactedDiffResult.push(this.DiffResult[key])
            }
          }
          window.scrollTo(0, 0); // scroll the window to top
          this.diffArrayOut.emit(this.DiffResult)
      }
      else{
        this.error = true
        this.error_message = "Different kind of files between Original file and Destination file"
      }
      this.reset()
    }
  }

  reset(event?: any): void {
    this.mdOpen = false
    this.wizardform.reset();
    this.wizard.reset();
    this.DiffParam = { originalfile: null, originalcode: [], comparefile: null, comparecode: []}
    this.DisplayComparedObject = ""
    this.FirstFileName = ""
    this.SecondFileName = ""
    this.CompactedDiffResult = []
    this.DisplayFile = ""
    this.FirstFile.nativeElement.value = null
    this.CompareFile.nativeElement.value = null
  }

  onCancel(): void {
    this.wizardform.reset();
    this.wizard.close();
    this.wizard.reset();
    this.DisplayComparedObject = ""
    this.DisplayFile = ""
    this.FirstFile.nativeElement.value = null
    this.CompareFile.nativeElement.value = null
  }

  ngOnDestroy(): void{
    this.reset()
  }
}
