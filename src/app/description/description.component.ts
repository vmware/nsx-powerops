import { Component, Input, OnInit } from '@angular/core';
import { HomeComponent} from '../home/home.component'


@Component({
  selector: 'app-description',
  templateUrl: './description.component.html',
  styleUrls: ['./description.component.css']
})
export class DescriptionComponent implements OnInit {
  @Input() Menu: string;

  Description: any;

  constructor(
    public doc: HomeComponent
  ) { }

  ngOnInit(): void {
    // Get Documentation
    for (let item of this.doc.Documentation){
      if( item.name === this.Menu){
        this.Description = item
      }
    }
  }

}
