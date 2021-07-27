import { Component, Input, OnInit } from '@angular/core';

@Component({
  selector: 'app-diffresult',
  templateUrl: './diffresult.component.html',
  styleUrls: ['./diffresult.component.css']
})
export class DiffresultComponent implements OnInit {
  @Input() DiffTab: any;
  @Input() HeaderDiff: any;
  @Input() Name: string
  error = true
  constructor() { }

  ngOnInit(): void {

    if (this.Name === 'Groups'){
      for(let grp of this.DiffTab){
        grp.criteria = grp.expression
      }
    }
  }

    // To check type of variable in HTML
    typeOf(value: any) {
      return typeof value;
    }
  
    isArray(obj : any ) {
      return Array.isArray(obj)
   }
}
