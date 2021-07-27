import { Injectable } from '@angular/core';
import { SessionService } from '../services/session.service';
import { LoginSession } from '../class/loginSession';
import {Alarm} from '../class/Alarm'


@Injectable({
  providedIn: 'root'
})
export class AlarmsService {
  public mysession: LoginSession;
  Name= 'Alarms'
  Header= ['Feature Name', 'Event Type', 'Node Name', 'Node Resource Type', 'Entity ID', 'Severity', 'Time', 'Status', 'Description', 'Recommended Action', 'Diff Status' ]
  HeaderDiff = [
    { header: 'Feature Name', col: 'feature_name'},
    { header: 'Event Type', col: 'event_type'},
    { header: 'Node Name', col: 'node_name'},
    { header: 'Node Resource Type', col: 'node_resource_type'},
    { header: 'Entity ID', col: 'entity_id'},
    { header: 'Severity', col: 'severity'},
    { header: 'Time', col: 'time'},
    { header: 'Status', col: 'status'},
    { header: 'Description', col: 'description'},
    { header: 'Recommended Action', col: 'recommended_action'},
  ]

  ConditionalFormating = {
    sheet: this.Name,
    column:   [
      {
      columnIndex:  this.Header.indexOf('Severity') + 1,
      rules: [{
        color: 'red',
        text: 'HIGH'
      },
      {
        color: 'orange',
        text: 'MEDIUM'
      },
      {
        color: 'red',
        text: 'CRITICAL'
      }]
      },
      {
      columnIndex:  this.Header.indexOf('Status') + 1,
      rules: [{
        color: 'green',
        text: 'RESOLVED'
      },
      {
        color: 'orange',
        text: 'OPEN'
      }]
      },
    ]
  }

  constructor(
    private session: SessionService,
    ) { 
    this.mysession = SessionService.getSession()
    }

  async getAlarms(){
    let TabAlarms: any[] = [];
    let alarms_json =  await this.session.getAPI(this.mysession, '/api/v1/alarms');
    if (alarms_json.result_count > 0){
      for (let alarm of alarms_json.results){
        let al = new Alarm(alarm.id)
        al.feature_name = alarm.feature_name,
        al.event_type = alarm.summary,
        al.node_name = alarm.node_display_name,
        al.node_resource_type = alarm.node_resource_type,
        al.entity_id = alarm.node_id,
        al.severity = alarm.severity,
        al.time = alarm.last_reported_time,
        al.formatted_time = new Date(alarm.last_reported_time).toLocaleString()
        al.status = alarm.status,
        al.description = alarm.description,
        al.recommended_action = alarm.recommended_action
        TabAlarms.push(al)
      }
    }
    return TabAlarms
  }

  formatDataExport(TabAlarm: any, separator: string){
    let Tabline = []
    for( let alarm of TabAlarm){
      Tabline.push({
        'feature_name': alarm.feature_name,
        'event_type': alarm.event_type,
        'node_name': alarm.node_name,
        'node_resource_type': alarm.node_resource_type,
        'entity_id': alarm.entity_id,
        'severity': alarm.severity,
        'time': alarm.formatted_time,
        'status': alarm.status,
        'description': alarm.description,
        'recommended_action': alarm.recommended_action,
        'diffstatus': alarm.diffstatus
      })
    }
    return Tabline
   }

  async getData(){
    // Get Data for audit
    let TabAlarms= await this.getAlarms()
    return TabAlarms
  }
}
