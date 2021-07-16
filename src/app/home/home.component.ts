import { Component, OnInit } from '@angular/core';
import { userIcon, ClarityIcons, flameIcon, certificateIcon, angleIcon, downloadCloudIcon, firewallIcon, clusterIcon, networkSwitchIcon, shieldIcon, dashboardIcon, detailsIcon, resourcePoolIcon, organizationIcon, libraryIcon } from '@cds/core/icon';
import { xlsFileIcon } from '@cds/core/icon/shapes/xls-file';
import { Menu } from '../class/MenuClass';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { map } from 'rxjs/operators';


@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})


export class HomeComponent implements OnInit {
    public Documentation: any
    private urlDoc: string = '/assets/documentation.json'

    public TabLoadbalancing = [
      new Menu('lb', 'loadbalancing', 'Load Balancing', false),
    ]

    public TabFabric = [
      new Menu('ManagerInfos', 'manager-infos', 'Manager Infos', false),
      new Menu('Nodes', 'transport-nodes', 'Host/Edge Nodes', false),
      new Menu('TransportZones', 'transport-zones', 'Transport Zones', false),
      new Menu('Tunnels', 'tunnels', 'Tunnels', false),
      new Menu('IPpools', 'ippools', 'IP Pools', false),
      new Menu('Alarms', 'alarms', 'Monitoring & Alarms', false),

    ]

  public TabNetwork = [
    new Menu('Segments', 'nsx-segments', 'Segments', false),
    new Menu('LogicalRouters', 'lr-summary', 'Logical Router Summary', false),
    new Menu('LogicalPorts', 'lr-ports', 'Logical Router Ports', false),
    new Menu('BGP', 'bgp-sessions', 'T0 BGP sessions', false),
    new Menu('RoutingTables', 'routingtables', 'Routing Tables', false),
  ]

  public TabSecurity = [
    new Menu('Groups', 'security-groups', 'Security Groups Infos', false),
    new Menu('Rules', 'security-rules', 'Distributed Firewall Rules', false),
    new Menu('Services', 'nsx-services', 'Services', false),
    new Menu('Policies', 'security-policies', 'Security Policies', false),
    new Menu('VMs', 'vms', 'Virtual Machines', false),
  ]

  constructor(
    public http: HttpClient,
    ) { }

  async ngOnInit(): Promise<void> {
    ClarityIcons.addIcons(organizationIcon, userIcon, flameIcon, certificateIcon, angleIcon, downloadCloudIcon, xlsFileIcon, firewallIcon, clusterIcon, networkSwitchIcon, shieldIcon, dashboardIcon, detailsIcon, resourcePoolIcon, libraryIcon);
    
    // Read Documentation file
    this.Documentation = await this.http.get<any>(this.urlDoc).pipe(map((data) => data)).toPromise()
    .then((response) => {
      return response
    })
    .catch((error: HttpErrorResponse) => {
      console.error(error.status, error.statusText)
      return {'result_count': 0, 'results': []}
    })
   }  
}
