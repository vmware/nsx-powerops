export class Service {
    public description: string = ""
    public id: string = ""
    public resource_type: string = ""
    public tags: any[]
    public createdby: string = ""
    public diffstatus: string = ""

    constructor(
        public name: string,
        public entries: Entry[]
    ) {
    }
  }

export class Entry{
    public id: string = ""
    public sources: any = ""
    public protocol: string = ""
    public destinations: any = ""
    public ether_type: any = ""
    public protocol_number: any = ""

    constructor(
        public name: string
    ){}
}