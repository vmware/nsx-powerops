import { Component, OnInit } from '@angular/core';
import { TNstatusService } from '../services/tnstatus.service'
import { HomeComponent} from '../home/home.component'

@Component({
  selector: 'app-tn-status',
  templateUrl: './tn-status.component.html',
  styleUrls: ['./tn-status.component.css']
})


export class TnStatusComponent implements OnInit {
  TabEdge: any;
  TabEdgeCluster: any;
  TabTN: any;
  TabCompute: any;

  constructor(
    private TN: TNstatusService,
    public doc: HomeComponent
    ) { }

    async ngOnInit(): Promise<void>{

      this.TabTN = await this.TN.getTNStatus()
      this.TabEdge = await this.TN.getEdgeStatus()
      this.TabEdgeCluster = await this.TN.getEdgeClusterStatus()
      this.TabCompute = await this.TN.getCompute()
  }
 
}
