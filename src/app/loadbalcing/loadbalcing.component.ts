import { Component, OnInit } from '@angular/core';

@Component({
  selector: 'app-loadbalcing',
  templateUrl: './loadbalcing.component.html',
  styleUrls: ['./loadbalcing.component.css']
})
export class LoadbalcingComponent implements OnInit {

  VARIABLE: any
  STRING: string
  ARRAY: string[]

  constructor() { }

  ngOnInit(): void {
    let param = 'param'
    this.myfunction(param)

  }

  myfunction(myparam: string) {
    this.STRING = myparam
}

  
}
