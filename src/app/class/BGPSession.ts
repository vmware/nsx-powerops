export class BGPSession {
    public prefix_in: any = ""
    public prefix_out: any = ""
    public status: string = ""
    public bgp_status: boolean
    public ecmp: boolean
    public serial: any = ""
    public ibgp: any = ""
    public diffstatus: string = ""
    public type: string = ""

    constructor(
        public t0_name: string,
        public source_ip: string,
        public local_as: any,
        public remote_ip: string,
        public remote_as: any
    ) {}
}