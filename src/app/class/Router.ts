import { EdgeCluster } from "./Node"

export class Router {
    public type: string = ""
    public id: string = ""
    public cluster: EdgeCluster
    public cluster_name: string = ""
    public cluster_id: string = ""
    public hamode: string = ""
    public failover: string = ""
    public relocation: boolean
    public table: Route[]
    public description: string = ""
    public members: Node[]
    public diffstatus: string = ""

    constructor(
        public name: string,
    ) {}
}

export class Route {
    public type: string = ""
    public admin_distance: any = ""
    public node_name: string = ""
    public node_id: string = ""
    public node_status: string = ""
    public router: string = ""
    public router_id: string = ""
    public router_type: string = ""
    public router_ha: string = ""
    public diffstatus: string = ""

    constructor (
        public network: string,
        public gateway: string
    ){}
}