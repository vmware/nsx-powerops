import { TransportNode } from './TransportNode'

export class Tunnel {
    public encap: string = ""
    public remote_node_display_name: string = ""
    public remote_node_id: string = ""
    public remote_ip: string = ""
    public local_ip: string = ""
    public egress_int: string = ""
    public status: string = ""
    public node: TransportNode;
    public diffstatus: string = ""

    constructor(
        public name: string,
    ) {}
}
