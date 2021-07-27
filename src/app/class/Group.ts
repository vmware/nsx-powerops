import { Tag } from "./Tags"

export class Group {
    public tags: Tag[] = []
    public path: string = ""
    public expression: Expression[] = []
    public type_criteria: string[] = []
    public criteria: any[] = []
    public ip: string[] = []
    public vm: any[] = []
    public segment: string[] = []
    public segment_port: string[] = []
    // public tmp_expression: Expression[] = []
    public diffstatus: string = ""

    constructor(
        public name: string,
    ) {}
}

export class Expression{
    public member_type: string = ""
    public key: string = ""
    public operator: string = ""
    public value: any = ""

    constructor(
        public resource_type: string
    ){}
}
