import { Component, OnInit } from '@angular/core';
import { NsxusageService} from '../services/nsxusage.service'
import { blocksGroupIcon, ClarityIcons, shieldIcon, switchIcon } from '@cds/core/icon';

@Component({
  selector: 'app-nsx-usage',
  templateUrl: './nsx-usage.component.html',
  styleUrls: ['./nsx-usage.component.css']
})
export class NsxUsageComponent implements OnInit {
  TabSecurity: any;
  loading_tabsecu = true;
  TabNetwork: any;
  loading_tabusage = true;
  TabInventory: any;
  loading_tabinv = true

  constructor(
    private nsxusage: NsxusageService
    ) {  }

    async ngOnInit(): Promise<void>{
      ClarityIcons.addIcons(switchIcon, shieldIcon, blocksGroupIcon);

      let Tab = await this.nsxusage.getUsage()
      this.TabInventory = Tab[0]
      this.loading_tabinv = false
      this.TabNetwork = Tab[1]
      this.loading_tabusage = false
      this.TabSecurity = Tab[2]
      this.loading_tabsecu = false
  }

}

