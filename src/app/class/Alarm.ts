export class Alarm {
    public recommended_action: string = ""
    public description: string = ""
    public status: string = ""
    public formatted_time: string = ""
    public time: any = ""
    public severity: string = ""
    public entity_id: string = ""
    public node_resource_type: string = ""
    public node_name: string = ""
    public event_type: string = ""
    public feature_name: string = ""
    public diffstatus: string = ""

    constructor(
        public id: string,
    ) {}
}