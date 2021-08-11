import { Component, OnInit, AfterViewInit, NgZone, OnDestroy} from '@angular/core';
import { SessionService } from '../services/session.service';
import { LoginSession } from '../class/loginSession';

// amCharts imports
import * as am4core from '@amcharts/amcharts4/core';
import * as am4plugins_forceDirected from "@amcharts/amcharts4/plugins/forceDirected";
import am4themes_animated from '@amcharts/amcharts4/themes/animated';

import { PlatformLocation } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { isArray } from 'lodash';

@Component({
  selector: 'app-network',
  templateUrl: './network.component.html',
  styleUrls: ['./network.component.css'],
})

export class NetworkComponent implements OnDestroy, AfterViewInit, OnInit {
  public mysession: LoginSession;

  private chart: any
  constructor(
    private zone: NgZone, 
    private session: SessionService,
    private plaformLocation: PlatformLocation,
    public http: HttpClient
    ){
    this.mysession = SessionService.getSession()
  }

  ngOnInit(): void{
  }

  getInfoNode(node: any, parenttype: any, upnode_ip?: any): any{
    // Icons
    let routert0 = "M18,14.87l5.11-5.14a1,1,0,1,0-1.42-1.41L19,11V3.33a1,1,0,0,0-2,0V11L14.31,8.32a1,1,0,1,0-1.42,1.41Z M18,21.13l-5.11,5.14a1,1,0,0,0,1.42,1.41L17,25v7.69a1,1,0,0,0,2,0V25l2.69,2.71a1,1,0,0,0,1.42-1.41Z M28.85,12.89a1,1,0,0,0-1.41,1.42L30.15,17H22.46a1,1,0,1,0,0,2h7.69l-2.71,2.69a1,1,0,0,0,1.41,1.42L34,18Z M5.85,19h7.69a1,1,0,0,0,0-2H5.85l2.71-2.69a1,1,0,1,0-1.41-1.42L2,18l5.14,5.11a1,1,0,1,0,1.41-1.42Z"
    let routert1 = "M18,14.87l5.11-5.14a1,1,0,1,0-1.42-1.41L19,11V3.33a1,1,0,0,0-2,0V11L14.31,8.32a1,1,0,1,0-1.42,1.41Z M18,21.13l-5.11,5.14a1,1,0,0,0,1.42,1.41L17,25v7.69a1,1,0,0,0,2,0V25l2.69,2.71a1,1,0,0,0,1.42-1.41Z M28.85,12.89a1,1,0,0,0-1.41,1.42L30.15,17H22.46a1,1,0,1,0,0,2h7.69l-2.71,2.69a1,1,0,0,0,1.41,1.42L34,18Z M5.85,19h7.69a1,1,0,0,0,0-2H5.85l2.71-2.69a1,1,0,1,0-1.41-1.42L2,18l5.14,5.11a1,1,0,1,0,1.41-1.42Z"
    let segment = "M1,12.6C1,12.5,1,12.4,1,12.3c0.2-0.7,0.5-1.3,1-1.8c1.3-1.3,2.6-2.7,3.9-4c0.7-0.7,1.5-1,2.5-1.1c1,0,1.9,0.8,1.9,1.8 c0,0.3,0,0.6,0,0.9c0,0.8,0.4,1.1,1.1,1.1c0.8,0,1.7,0,2.5,0c0.6,0,1.1,0.4,1.1,1c0,0.6-0.4,1-1,1c-1.1,0-2.1,0-3.2,0 c-1.3,0-2.3-1.1-2.4-2.4c0-0.1,0-0.3,0-0.4c0-0.3-0.1-0.5-0.4-0.6C7.8,7.6,7.6,7.6,7.3,7.8C7.2,7.9,7.2,8,7.1,8 c-1.2,1.2-2.4,2.4-3.6,3.6c-0.9,0.9-0.9,2,0,2.9c1.2,1.2,2.4,2.4,3.6,3.7c0.1,0.1,0.2,0.2,0.2,0.2c0.2,0.2,0.5,0.2,0.8,0.1 c0.3-0.1,0.4-0.4,0.4-0.7c0-0.3,0-0.5,0-0.8c0.2-1.2,1.1-2.1,2.4-2.1c3.2,0,6.3,0,9.5,0c0.1,0,0.2,0,0.3,0c0.6,0,1-0.4,1-1 c0-0.5,0-0.9,0.1-1.4c0.2-0.9,1-1.5,1.9-1.5c1,0,1.8,0.4,2.6,1.1c1.3,1.3,2.5,2.6,3.8,3.9c0.6,0.6,0.9,1.2,1,2c0,0,0,0.1,0.1,0.1 c0,0.3,0,0.6,0,1c-0.1,0.3-0.1,0.5-0.2,0.8c-0.2,0.5-0.5,1-0.9,1.4c-1.3,1.3-2.6,2.6-3.9,3.9c-0.7,0.7-1.6,1.1-2.6,1.1 c-1,0-1.9-0.8-1.9-1.9c0-0.3,0-0.6,0-0.9c0-0.7-0.4-1-1-1c-2.4,0-0.7,0-3.2,0c-0.8,0-1.2-0.7-1-1.3c0.2-0.4,0.5-0.6,0.9-0.6 c1.8,0-0.5,0,1.4,0c0.8,0,1.6,0,2.4,0c1.3,0,2.4,1.1,2.4,2.4c0,0.2,0,0.3,0,0.5c0,0.6,0.6,0.9,1.1,0.6c0.1-0.1,0.2-0.2,0.3-0.3 c1.2-1.2,2.4-2.4,3.6-3.7c0.9-0.9,0.9-1.9,0-2.8c-1.2-1.3-2.4-2.5-3.7-3.7c-0.2-0.2-0.4-0.3-0.7-0.3c-0.4,0-0.6,0.3-0.6,0.7 c0,0.3,0,0.5,0,0.8c-0.2,1.2-1.1,2-2.4,2c-3.2,0-6.5,0-9.7,0c-0.3,0-0.6,0.1-0.8,0.3c-0.1,0.2-0.2,0.4-0.2,0.7 c-0.1,0.4,0,0.9-0.1,1.3c-0.2,0.9-1,1.5-1.8,1.5c-1,0-1.8-0.4-2.5-1.1c-1.3-1.3-2.6-2.6-3.9-4c-0.5-0.6-0.9-1.2-1-2 c0,0,0-0.1-0.1-0.1C1,13.3,1,13,1,12.6z M17.9,9.3c0.5,0,0.9,0.4,0.9,1c0,0.5-0.4,1-1,1c-0.5,0-0.9-0.4-0.9-1C16.9,9.7,17.4,9.3,17.9,9.3z M13.6,20.7c0.7-0.1,1.2,0.5,1.1,1.1c-0.1,0.4-0.4,0.7-0.7,0.7c-0.7,0.1-1.2-0.5-1.1-1.1C12.9,21.1,13.2,20.8,13.6,20.7z"
    let vrf = "M27.14,33H10.62C5.67,33,1,28.19,1,23.1a10,10,0,0,1,8-9.75,10.19,10.19,0,0,1,20.33,1.06A10.07,10.07,0,0,1,29,16.66a8.29,8.29,0,0,1,6,8C35,29.1,31.33,33,27.14,33ZM19.09,6.23a8.24,8.24,0,0,0-8.19,8l0,.87-.86.1A7.94,7.94,0,0,0,3,23.1c0,4,3.77,7.9,7.62,7.9H27.14C30.21,31,33,28,33,24.65a6.31,6.31,0,0,0-5.37-6.26l-1.18-.18.39-1.13A8.18,8.18,0,0,0,19.09,6.23Z"
    
    let value = node.properties.level
    let ipaddress: any
    if (node.properties.hasOwnProperty("ip_address")){
      ipaddress = node.properties.ip_address
    }
    else if(node.properties.hasOwnProperty("ip_addresses")){
      let tmp_ip = []
      for(let ip of node.properties.ip_addresses ){
        tmp_ip.push(ip.label)
      }
      ipaddress = tmp_ip.join(', ')
    }
    let obj = {
      name: node.properties.display_name,
      value: Math.floor((150/(value + 2))),
      type: node.properties.resource_type,
      VM: 0,
      uplink: [],
      parentname: "",
      ip_address: ipaddress,
      sub_type: "",
      linkWidth: 3,
      color: "#C21D00",
      linkto: [],
      children: []
    }

    // T0 router
    if (!node.properties.resource_type.indexOf('Tier0')){
      // VRF Treatment
      if(node.properties.hasOwnProperty("parent_tier0")){
        obj.linkto.push(node.properties.parent_tier0)
        obj.type = 'VRF'
        obj.value = Math.floor(obj.value/2)
        obj.color = "#79C6E6"
        obj['path'] = vrf
      }
      else{
        obj['color'] = "#00648F"
        obj['path'] = routert0
        obj['parentname'] = 'out'
      }
      obj['HA'] = node.properties.ha_mode
      if ('child_count' in node){
        obj['linkWidth'] = node.child_count.Tier1 + 2
      }
      // uplink treatment
      if(node.properties.hasOwnProperty("uplink_ips")){
        obj.uplink.push({ nodedown: node.properties.uplink_ips.join(', ')})
      }
    }
    // T1 router
    if (!node.properties.resource_type.indexOf('Tier1')){
      obj['path'] = routert1
      if (node.properties.hasOwnProperty("hierarchy")){
        let tmp_parentarray = node.properties.hierarchy[0][0].split('/')
        obj.parentname = tmp_parentarray[tmp_parentarray.length-1]  
      }
      obj['HA'] = node.properties.failover_mode
      obj['color'] = "#3C8500"
      if ('child_count' in node){
        obj['linkWidth'] = node.child_count.Segment + 2
      }
      if(node.properties.hasOwnProperty("ip_address")){
        obj.uplink.push({ nodedown: node.properties.ip_address})
        if (upnode_ip && isArray(upnode_ip)){
          for (let int of upnode_ip){
            if (node.properties.display_name === int.node){
              obj.uplink.push({ nodeup: int.label})
            }
          }
        }
      }
    }
    // Segment
    if (!node.properties.resource_type.indexOf('Segment')){
      obj['path'] = segment
      if (node.properties.hasOwnProperty("hierarchy")){
        let tmp_parentarray = node.properties.hierarchy[0][0].split('/')
        obj.parentname = tmp_parentarray[tmp_parentarray.length-1]  

        if (node.properties.hierarchy[0].length > 1 && parenttype === 'Tier0' ){
          return null
        }
        for (let nd of node.properties.hierarchy[0]){
          let tmp_node_name = nd.split('/')
          tmp_node_name = tmp_node_name[tmp_node_name.length-1]
          obj.linkto.unshift(tmp_node_name)
        }
      }
      obj['sub_type'] = node.properties.sub_type
      if (node.properties.sub_type == 'OVERLAY' && 'child_count' in node){
        obj['VM'] = node.child_count.VirtualMachine
        obj['linkWidth'] = node.child_count.VirtualMachine + 2
      }
      obj['color'] = "#D69A00"
    }
    // Recursive for children
    if ('child_count' in node){
      let k: keyof typeof node.children;
      for (k in node.children){
        if( node.properties.resource_type === 'Tier0'){
          let item = this.getInfoNode(node.children[k], node.properties.resource_type, node.properties.ip_addresses)
          if (item != null){
            obj.children.push(item)
          }
        }
        else{
          let item = this.getInfoNode(node.children[k], node.properties.resource_type)
            obj.children.push(item)
        }
      }
    }
    return obj
  }
 
  async ngAfterViewInit(): Promise<void> {

    this.zone.runOutsideAngular( () => {
    // url for topology
    let topo_url = '/policy/api/v1/ui/network-topology'
    let body = {"include_service_summary":true}
    let body_json = JSON.stringify(body)
    let internet = "M10.1 44.4h-.3C4.6 42.9 1 38 1 32.4c0-5.3 3.2-9.9 8-11.6.3-4.3 2.1-8.4 5.1-11.4 3.2-3.3 7.5-5.1 12-5.1 6.5 0 12.4 3.8 15.4 9.8h2.7C52.4 14 59 20.9 59 29.4c0 6-3.4 11.5-8.7 14-.6.3-1.3 0-1.6-.6-.3-.6 0-1.3.6-1.6 4.4-2.1 7.3-6.7 7.3-11.8 0-7.1-5.6-12.9-12.4-12.9h-1.6c-.5 0-1.1 0-1.7.1l-.9.1-.4-.9c-2.4-5.6-7.7-9.1-13.5-9.1-3.9 0-7.5 1.6-10.3 4.4-2.8 2.8-4.4 6.6-4.4 10.6v.9l-.9.2C6.3 24 3.4 28 3.4 32.4c0 4.5 2.9 8.4 7 9.5.6.2 1 .9.8 1.5-.1.6-.5 1-1.1 1 M45.9 29.2c.1-.2.1-.5 0-.7v-.6l-15.7-9.3-15.6 9.3v18.5l15.6 9.3.3-.2c.2 0 .4-.1.5-.3l14.8-8.8V29.2zm-3.3-.4l-12.1 6.7-12.3-6.9 12.1-7.2 12.3 7.4zM17 30.6l12.7 7.1v14.9L17 45V30.6zm14.2 21.7V37.7l12.3-6.8V45l-12.3 7.3z"

    const httpOptions = new HttpHeaders({
        'Content-Type':  'application/json',
        'Access-Control-Allow-Origin': '*',
        'Accept': '*/*',
        'NSX': this.mysession.nsxmanager,
        'Authorization': 'Basic ' + btoa(this.mysession.username + ':' + this.mysession.password),
        'Access-Control-Allow-Methods': 'OPTIONS, HEAD, GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type,Access-Control-Allow-Origin,Access-Control-Allow-Methods, Authorization'
      })
    
    this.http.post('http://' + this.plaformLocation.hostname + ':8080' + topo_url, body_json, {'headers': httpOptions, 'observe': "response"}).toPromise().then(
        result => {
          // am4core.useTheme(am4themes_material);
          am4core.useTheme(am4themes_animated);

          let chart = am4core.create("network", am4plugins_forceDirected.ForceDirectedTree);
          let networkSeries = chart.series.push(new am4plugins_forceDirected.ForceDirectedSeries())
          let topo_data = []
          let DC_Node = { 
            name: "Internet/DC",
            type: "out",
            color: "#8C8C8C",
            linkWidth: 10,
            parentname: "",
            x: am4core.percent(50),
            y: am4core.percent(20),
            fixed: true,
            value: 150,
            path: internet,
            children: []
          }

          // treatment topology
          for (let node of result.body['results']){
            let detail = this.getInfoNode(node, 'out')
            if (node.properties.level === 0 && !node.properties.hasOwnProperty('parent_tier0')){
                DC_Node.children.push(detail)
            }
            else{
              // Remove VLAN Backed
              if (detail.sub_type != 'VLAN'){
                topo_data.push(detail)
              }
            }
          }
          topo_data.push(DC_Node)
          chart.data = topo_data
          networkSeries.nodes.template.outerCircle.filters.push(new am4core.DropShadowFilter());

          networkSeries.dataFields.value = "value";
          networkSeries.dataFields.name = "name";
          networkSeries.dataFields.id = "name";
          networkSeries.dataFields.children = "children";
          networkSeries.dataFields.fixed = "fixed";
          networkSeries.dataFields.color = "color";
          networkSeries.dataFields.linkWith = 'linkto'
          networkSeries.dataFields.category = 'type'

          networkSeries.nodes.template.fillOpacity = 1;
          // Label config
          networkSeries.nodes.template.label.text = "{name}"
          networkSeries.nodes.template.label.fontFamily = "Metropolis"
          networkSeries.nodes.template.label.fontSize = 12
          networkSeries.nodes.template.label.verticalCenter = "top";
          networkSeries.nodes.template.label.fill = am4core.color("#565656");
          networkSeries.nodes.template.label.dy = 20;
          networkSeries.nodes.template.propertyFields.x = "x"
          networkSeries.nodes.template.propertyFields.y = "y"
          // Configure circles colors
          networkSeries.nodes.template.circle.fill = am4core.color("#ffff");
          //Configure icons
          let icon = networkSeries.nodes.template.createChild(am4core.Sprite);
          icon.propertyFields.path = "path";
          icon.horizontalCenter = "middle";
          icon.verticalCenter = "middle";

          // Tooltips for each level
          networkSeries.nodes.template.adapter.add("tooltipText", function(text, target) {
            if (target.dataItem) {
              switch(target.dataItem.dataContext['type']) {
                case 'out':
                  return "{type}: {name}";
                case 'Tier0':
                  return "[bold]Name[/]: {name}\n\n[bold]Type[/]: {type}\n\n[bold]HA mode[/]: {HA}\n\n[bold]Uplink IPs[/]:\n{uplink.0.nodedown.join(', ')}";
                case 'VRF':
                  return "[bold]Name[/]: {name}\n\n[bold]Type[/]: {type}\n\n[bold]HA mode[/]: {HA}";
                case 'Tier1':
                  return "[bold]Name[/]: {name}\n\n[bold]Type[/]: {type}\n\n[bold]HA mode[/]: {HA}";
                case 'Segment':
                  return "[bold]{type}[/]: {name}\n\n[bold]IP[/]: {ip_address}\n\n[bold]Nb of VMs[/]: {VM}";
              }
            }
            return text;
          });

          networkSeries.fontSize = 11;
          networkSeries.fontFamily = "Metropolis"
          networkSeries.minRadius = 10;
          networkSeries.maxRadius = 60;
          networkSeries.links.template.propertyFields.strokeWidth = "linkWidth";
          networkSeries.links.template.strokeOpacity = 0.7;
          networkSeries.links.template.strength = 2 ;
          // Put tooltips only on links of T0 and T1
          networkSeries.links.template.adapter.add("tooltipText", function(text, target) {
            let source = target.source
            let dest = target.target
            if(dest.dataItem.dataContext['type'] == 'Tier1' ){
              networkSeries.links.template.interactionsEnabled = true;
              return "[bold]{parentname}[/]: {uplink.1.nodeup}\n[bold]{name}[/]: {uplink.0.nodedown}";
            }
            if(dest.dataItem.dataContext['type'] == 'Tier0' && source.dataItem.dataContext['type'] != 'Segment'){
              networkSeries.links.template.interactionsEnabled = true;
              return "[bold]{name}[/]: {uplink.0.nodedown}";
            }
          })
          // Small distance for link between VRF and T0
          networkSeries.links.template.adapter.add( "distance", function(text, target) {
            let source = target.source
            let dest = target.target
            if (source && source.dataItem.dataContext['type'] === "VRF" && dest.dataItem.dataContext['type'] === 'Tier0'){
              return 1.2
            }
            return 1.8
          })
          // Big Weight for link between VRF and T0
          networkSeries.links.template.adapter.add("strokeWidth", function(width: any, target) {
            let source = target.source;
            let dest = target.target;
            if (source && source.dataItem.dataContext['type'] === "VRF" && dest.dataItem.dataContext['type'] === 'Tier0') {
              return 40;
            }
            else{
              return source.dataItem.dataContext['linkWidth'];
            }
          });

          // Reduce Root Topology if data more than 10 + attract to the center
          if (topo_data.length > 10){
            // Workaround for svg not center if maxLevels = 1
            networkSeries.events.on("datavalidated", ()=>{
              networkSeries.dataItems.each(function(dataItem) {
                if (dataItem.level == 0) {
                  dataItem.hide();
                }
              })
            })
            networkSeries.manyBodyStrength = -20;
            networkSeries.centerStrength = 0.5;
          }
          else{
            networkSeries.manyBodyStrength = -10;
            networkSeries.centerStrength = 0.3;

          }

          // Hover treatment
          let hoverState = networkSeries.links.template.states.create("hover");
          hoverState.properties.strokeWidth = 10;
          hoverState.properties.strokeOpacity = 1;

          networkSeries.nodes.template.events.on("hit", function(event){
            networkSeries.manyBodyStrength = -20;

            let icon = networkSeries.nodes.template.createChild(am4core.Sprite);
            icon.propertyFields.path = "path";
            icon.horizontalCenter = "middle";
            icon.verticalCenter = "middle";
          })
          // networkSeries.nodes.template.events.on("over", function(event) {
          // event.target.dataItem.childLinks.each(function(link) {
          //   link.isHover = true;
          // })
          // if (event.target.dataItem.parentLink) {
          //   event.target.dataItem.parentLink.isHover = true;
          // }
          // })
      
          // networkSeries.nodes.template.events.on("out", function(event) {
          // event.target.dataItem.childLinks.each(function(link) {
          //   link.isHover = false;
          // })
          // if (event.target.dataItem.parentLink) {
          //   event.target.dataItem.parentLink.isHover = false;
          // }
          // })

          this.chart = chart;
        },
          error => { 
            console.error(error) }
      );
   })
}

  ngOnDestroy(): void {
    this.zone.runOutsideAngular(() => {
    //this.browserOnly(() => {
      if (this.chart) {
        this.chart.dispose();
      }
    });
  }
}
