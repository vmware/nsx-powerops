export class Segment {
    public state: string = ""
    public id: string = ""
    public vni: string = ""
    public diffstatus: string = ""
    public connectivity: string = ""
    // public multicast: boolean = false
    public type: string = ""
    public connectedto: string = ""
    public routertype: string = ""
    public replication_mode: string = ""
    public subnets: any[] = []
    public resource_type: string = ""
    public uplink_policy: string = ""
    public vlan: any[] = []
    public tz: TZ

    constructor(
        public name: string,
    ) {}
}

export class TZ {
    constructor(
        public name?: string,
        public type?: string
    ) {}
}
