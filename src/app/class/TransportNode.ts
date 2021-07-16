import { TransportZone } from './TransportZone'

export class TransportNode{
    public type: string = ""
    public hostswitch: HostSwitch[]
    public TZ: TransportZone[]
    public MTU: any = ""
    public ipaddresses: string[]
    public hostname: string  = ""
    public full_version: string = ""
    public managementIp: string = ""
    public powerState: string = ""
    public inMaintenanceMode: string = ""
    public serialNumber: string = ""
    public connectionState: string = ""
    public host_node_deployment_status: string = ""
    public lcp_status: string = ""
    public mpa_status: string = ""
    public status: string = ""
    public external_id: string = ""
    public id: string = ""
    public diffstatus: string = ""

    constructor(
        public name: string
    ) {}
}

export class HostSwitch{
    public type: string = ""
    public pnics: Interface[]
    public TZ: TransportZone[]
    public profile: Profile
    public uplinks: Interface[]

    constructor(
        public id: string,
        public name: string,
        public mode: string
    ) {}
}

export class Interface{
    constructor(
        public device_name: string,
        public uplink_name: string,
    ) {}
}

export class Teaming{
    public active_list: Interface[]
    public secondary_list: Interface[]

    constructor(
        public policy: string,
    ) {}
}

export class Profile{
    public description: string = ""
    public id: string = ""
    public mtu: any = ""
    public resource_type: string = ""
    public teaming: Teaming
    public encap: string = ""
    public transport_vlan: string = ""

    constructor(
        public name: string,
    ) {}
}