export class Port {
    public id: string = ""
    public attachment_type: string = ""
    public attachment_id: string = ""
    public router_name: string = ""
    public router_id: string = ""
    public segment_name: string = ""
    public segment_id: string = ""
    public state: string = ""
    public status: string = ""
    public createdby: string = ""
    public diffstatus: string  = ""

    constructor(
        public name: string,
    ) {}
}