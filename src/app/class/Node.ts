import { Route } from "./Router"

export class EdgeCluster {
    public deployment_type: string = ""
    public description: string = ""
    public id: string = ""
    public resource_type: string = ""
    public member_node_type: string = ""
    public members: Node[] = []
    public diffstatus: string = ""

    constructor(
        public name: string,
    ) {}
}

export class Node {
    public description: string = ""
    public id: string = ""
    public maintenance: string = ""
    public type: string = ""
    public member_index: any = ""
    public lcp_connectivity_status: string = ""
    public mpa_connectivity_status: string = ""
    public mpa_connectivity_status_details: string = ""
    public host_node_deployment_status: string = ""
    public control_node_ip: string = ""
    public status: string = ""
    public table: Route[] = []
    public diffstatus: string = ""

    constructor(
        public name: string,
    ) {}
}