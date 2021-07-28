import { NgModule } from '@angular/core';
import { CdsModule } from '@cds/angular';
import {HttpClient, HttpClientModule, HttpClientJsonpModule} from '@angular/common/http'
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { BrowserModule } from '@angular/platform-browser';
import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';
import { ClarityModule } from '@clr/angular';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { LoginComponent } from './login/login.component';
import { HomeComponent } from './home/home.component';
import { HeaderComponent } from './header/header.component';
import { NsxSegmentsComponent } from './nsx-segments/nsx-segments.component';
import { LrSummaryComponent } from './lr-summary/lr-summary.component';
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
import {DOCUMENT} from '@angular/common';
import { VmsComponent } from './vms/vms.component';
import { RoutingtablesComponent } from './routingtables/routingtables.component';
import { LoadbalcingComponent } from './loadbalcing/loadbalcing.component';
import { IppoolComponent } from './ippool/ippool.component';
import { DiffComponent } from './diff/diff.component';
import { DescriptionComponent } from './description/description.component';
import '@cds/core/alert/register.js';
import { DiffresultComponent } from './diffresult/diffresult.component';


@NgModule({
  declarations: [
    AppComponent,
    LoginComponent,
    HomeComponent,
    HeaderComponent,
    NsxSegmentsComponent,
    LrSummaryComponent,
    LrPortsComponent,
    BgpSessionsComponent,
    ManagerInfosComponent,
    TransportZonesComponent,
    NsxServicesComponent,
    TunnelsComponent,
    SecurityGroupsComponent,
    SecurityPoliciesComponent,
    SecurityRulesComponent,
    AlarmsComponent,
    PageNotFoundComponent,
    NsxUsageComponent,
    TnStatusComponent,
    NsxSummaryComponent,
    AuditComponent,
    TransportnodesComponent,
    NetworkComponent,
    VmsComponent,
    RoutingtablesComponent,
    LoadbalcingComponent,
    IppoolComponent,
    DiffComponent,
    DescriptionComponent,
    DiffresultComponent
  ],
  imports: [
    BrowserModule,
    AppRoutingModule,
    ClarityModule,
    FormsModule, ReactiveFormsModule,
    BrowserAnimationsModule,
    HttpClientModule,
    HttpClientJsonpModule,
    CdsModule,
    ],
  providers: [
    HttpClient,
    Document
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
