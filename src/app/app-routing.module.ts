import { NgModule } from '@angular/core';
import { RouterModule, Routes, RouteReuseStrategy } from '@angular/router';
import { HomeComponent } from './home/home.component';
import { LoginComponent } from './login/login.component';
import { LrSummaryComponent } from './lr-summary/lr-summary.component';
import { NsxSegmentsComponent } from './nsx-segments/nsx-segments.component';
import { LrPortsComponent } from './lr-ports/lr-ports.component';
import { BgpSessionsComponent } from './bgp-sessions/bgp-sessions.component';
import { ManagerInfosComponent } from './manager-infos/manager-infos.component';
import { TransportZonesComponent } from './transport-zones/transport-zones.component';
import { NsxServicesComponent } from './nsx-services/nsx-services.component';
import { TunnelsComponent } from './tunnels/tunnels.component';
import { SecurityGroupsComponent } from './security-groups/security-groups.component';
import { SecurityPoliciesComponent } from './security-policies/security-policies.component';
import { SecurityRulesComponent } from './security-rules/security-rules.component';
import { AlarmsComponent } from './alarms/alarms.component';
import { PageNotFoundComponent } from './page-not-found/page-not-found.component';
import { NsxUsageComponent } from './nsx-usage/nsx-usage.component';
import { TnStatusComponent } from './tn-status/tn-status.component';
import { NsxSummaryComponent } from './nsx-summary/nsx-summary.component';
import { AuditComponent } from './audit/audit.component';
import { TransportnodesComponent } from './transportnodes/transportnodes.component';
import { NetworkComponent } from './network/network.component';
import { VmsComponent } from './vms/vms.component';
import { RoutingtablesComponent} from './routingtables/routingtables.component';
import { LoadbalcingComponent} from './loadbalcing/loadbalcing.component';
import { IppoolComponent} from './ippool/ippool.component';


const routes: Routes = [
  { path: 'home', component: HomeComponent,
  children: [
    { path: 'nsx-segments', component: NsxSegmentsComponent},
    { path: 'lr-summary', component: LrSummaryComponent},
    { path: 'lr-ports', component: LrPortsComponent},
    { path: 'bgp-sessions', component: BgpSessionsComponent},
    { path: 'manager-infos', component: ManagerInfosComponent},
    { path: 'transport-zones', component: TransportZonesComponent},
    { path: 'nsx-services', component: NsxServicesComponent},
    { path: 'tunnels', component: TunnelsComponent},
    { path: 'security-groups', component: SecurityGroupsComponent},
    { path: 'security-policies', component: SecurityPoliciesComponent},
    { path: 'security-rules', component: SecurityRulesComponent},
    { path: 'alarms', component: AlarmsComponent},
    { path: 'nsx-usage', component: NsxUsageComponent },
    { path: 'tn-status', component: TnStatusComponent },
    { path: 'nsx-summary', component: NsxSummaryComponent },
    { path: 'audit', component: AuditComponent },
    { path: 'transport-nodes', component: TransportnodesComponent},
    { path: 'network', component: NetworkComponent},
    { path: 'vms', component: VmsComponent},
    { path: 'routingtables', component: RoutingtablesComponent},
    { path: 'loadbalancing', component: LoadbalcingComponent},
    { path: 'ippools', component: IppoolComponent}
  ]
},

  { path: 'login', component: LoginComponent },
  { path: '', redirectTo: 'home/network', pathMatch: 'full' },
  { path: '**', component: PageNotFoundComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule],
})
export class AppRoutingModule { }
