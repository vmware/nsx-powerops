import {HostSwitch} from './TransportNode'

export class TransportZone {
    public host_switch_id: string = ""
    public host_switch_mode: string = ""
    public host_switch_name: string = ""
    public hostswitch: HostSwitch
    public default: boolean = false
    public nested: boolean = false
    public description: string = ""
    public uplink_teaming_policy_names: string[]
    public resource_type: string = ""
    public diffstatus: string = ""

    constructor(
        public id: string,
        public name: string,
        public type: string
    ) {}
}