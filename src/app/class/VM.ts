import { Tag } from "./Tags"

export class VM {
    public tags: Tag[] = []
    public id: string = ""
    public host: string = ""
    public groups: string[] = []
    public ports: Interface[] = []
    public rules: any[] = []
    public segments: string[] = []
    public status: string = ""
    public diffstatus: string = ""

    constructor(
        public name: string,
    ) {}
  }

export class Interface{
    public mac: string = ""
    public ip: any = ""
    public vif_id: string = ""
    public segment_name: string = ""
    public segment_port: string = ""
    public status: string = ""
    public section_list: any[] = []

    constructor(
        public name: string,
    ) {}
}