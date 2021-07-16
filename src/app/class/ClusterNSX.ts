export class ComputeMgr{
    public origin: string = ""
    public build: string = ""

    constructor(
        public id: string,
        public server: string
    ) {}
}

export class Usage{
    constructor(
        public name: string,
        public current: string,
        public max: string,
        public usage: string
    ) {}
}

export class ClusterNSX{
    public diffstatus: string = ""
    
    constructor(
        public id: string,
        public status: string,
        public services: Service[],
        public online_nodes: NSXManager[]
    ) {}
}

export class NSXManager{
    public mgmt_cluster_listen_ip_address: string = ""
    public status: string = ""
    public fqdn: string = ""
    public ip: string = ""
    public services: Service[]

    constructor(
        public id: string
    ) {}
}

export class Service{
    public id: string = ""
    public status: string = ""
    public members: NSXManager[]
    public diffstatus: string = ""

    constructor(
        public name: string
    ) {}
}