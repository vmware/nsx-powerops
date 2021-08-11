export class Rule {
    public scope: string[] = []
    public policy: Policy
    public id: string = ""
    public sources: string[] = []
    public destinations: string[] = []
    public services: string[] = []
    public profile: string[] = []
    public action: string = ""
    public direction: string = ""
    public state: string = ""
    public ip: string = ""
    public logged: boolean = false
    public diffstatus: string = ""
    public hitcount: string = "0"

    constructor(
        public name: string,
    ) {
    }
  }

  export class Policy{
      public scope: string[] = []
      public path: string = ""
      public sequence_nb: any = ""
      public category: string = ""
      public stateful: boolean = false
      public id: string = ""
      public diffstatus: string = ""

      constructor(
        public name: string
      ){}
  }

  export class Category{

    constructor(
      public name: string = "",
      public loading: boolean = false,
      public index: number,
      public policies: Policy[] = []
    ){}
}
