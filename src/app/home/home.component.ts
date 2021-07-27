import { Component, OnInit } from '@angular/core';
import { userIcon, ClarityIcons, flameIcon, certificateIcon, angleIcon, downloadCloudIcon, firewallIcon, clusterIcon, networkSwitchIcon, shieldIcon, dashboardIcon, detailsIcon, resourcePoolIcon, organizationIcon, libraryIcon } from '@cds/core/icon';
import { xlsFileIcon } from '@cds/core/icon/shapes/xls-file';
import { Menu } from '../class/MenuClass';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { map } from 'rxjs/operators';
import { NsxSegmentsComponent } from '../nsx-segments/nsx-segments.component';
import { LrSummaryComponent } from '../lr-summary/lr-summary.component';
import { LrPortsComponent } from '../lr-ports/lr-ports.component';
import { BgpSessionsComponent } from '../bgp-sessions/bgp-sessions.component';
import { RoutingtablesComponent } from '../routingtables/routingtables.component';
import { ManagerInfosComponent } from '../manager-infos/manager-infos.component';
import { TransportZonesComponent } from '../transport-zones/transport-zones.component';
import { NsxServicesComponent } from '../nsx-services/nsx-services.component';
import { TunnelsComponent } from '../tunnels/tunnels.component';
import { SecurityGroupsComponent } from '../security-groups/security-groups.component';
import { SecurityPoliciesComponent } from '../security-policies/security-policies.component';
import { SecurityRulesComponent } from '../security-rules/security-rules.component';
import { TransportnodesComponent } from '../transportnodes/transportnodes.component';
import { AlarmsComponent } from '../alarms/alarms.component';
import { VmsComponent} from '../vms/vms.component'
import { IppoolComponent } from '../ippool/ippool.component'
import { LoadbalcingComponent } from '../loadbalcing/loadbalcing.component'

import { SegmentsService } from '../services/segments.service';
import { LrsummaryService } from '../services/lrsummary.service';
import { LrportsService } from '../services/lrports.service';
import { BgpService } from '../services/bgp.service';
import { RoutingtablesService } from '../services/routingtables.service';
import { ManagerinfosService } from '../services/managerinfos.service';
import { TransportzoneService } from '../services/transportzone.service';
import { NsxservicesService } from '../services/nsxservices.service';
import { TunnelsService } from '../services/tunnels.service';
import { GroupsService } from '../services/groups.service';
import { PoliciesService } from '../services/policies.service';
import { RulesService } from '../services/rules.service';
import { AlarmsService } from '../services/alarms.service';
import { TransportnodesService} from '../services/transportnodes.service'
import { VmsService} from '../services/vms.service'
import { IppoolService } from '../services/ippool.service'

@Component({
  selector: 'app-home',
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.css']
})


export class HomeComponent implements OnInit {
    public Documentation: any
    private urlDoc: string = '/assets/documentation.json'

    public TabLoadbalancing = [
      new Menu('lb', 'loadbalancing', 'Load Balancing', [], false),
    ]

    public TabFabric = [
      new Menu('ManagerInfos', 'manager-infos', 'Manager Infos', this.managerinfos.HeaderDiff, false),
      new Menu('Nodes', 'transport-nodes', 'Host/Edge Nodes', this.tn.HeaderDiff, false),
      new Menu('TransportZones', 'transport-zones', 'Transport Zones', this.tz.HeaderDiff, false),
      new Menu('Tunnels', 'tunnels', 'Tunnels', this.tunnels.HeaderDiff, false),
      new Menu('IPpools', 'ippools', 'IP Pools', this.ippools.HeaderDiff, false),
      new Menu('Alarms', 'alarms', 'Monitoring & Alarms', this.alarms.HeaderDiff, false),

    ]

  public TabNetwork = [
    new Menu('Segments', 'nsx-segments', 'Segments', this.segments.HeaderDiff, false),
    new Menu('LogicalRouters', 'lr-summary', 'Logical Router Summary', this.lrsummary.HeaderDiff, false),
    new Menu('LogicalPorts', 'lr-ports', 'Logical Router Ports', this.lrports.HeaderDiff, false),
    new Menu('BGP', 'bgp-sessions', 'T0 BGP sessions', this.bgp.HeaderDiff, false),
    new Menu('RoutingTables', 'routingtables', 'Routing Tables', this.routingtables.HeaderDiff, false),
  ]

  public TabSecurity = [
    new Menu('Groups', 'security-groups', 'Security Groups Infos', this.groups.HeaderDiff, false),
    new Menu('Rules', 'security-rules', 'Distributed Firewall Rules', this.rules.HeaderDiff, false),
    new Menu('Services', 'nsx-services', 'Services', this.nsxservices.HeaderDiff, false),
    new Menu('Policies', 'security-policies', 'Security Policies', this.policies.HeaderDiff, false),
    new Menu('VMs', 'vms', 'Virtual Machines', this.vms.HeaderDiff, false),
  ]

  constructor(
    public http: HttpClient,
    private segments: SegmentsService,
    private vms: VmsService,
    private lrsummary: LrsummaryService,
    private lrports: LrportsService,
    private bgp: BgpService,
    private routingtables: RoutingtablesService,
    private managerinfos: ManagerinfosService,
    private tz: TransportzoneService,
    private nsxservices: NsxservicesService,
    private tunnels: TunnelsService,
    private groups: GroupsService,
    private policies: PoliciesService,
    private rules: RulesService,
    private alarms: AlarmsService,
    private tn: TransportnodesService,
    private ippools: IppoolService,
    // private loadbalancing: Lo

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
