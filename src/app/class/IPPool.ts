export class IPPool {
    public Range: Range[]
    public diffstatus: string = ""

    constructor(
        public name: string,
        public id: string
    ) {}
}

export class Range {
    public allocation_ranges: IPBlock[]

    constructor(
        public cidr: string,
    ) {}
}

export class IPBlock {
    constructor(
        public start: string,
        public end: string
    ) {}
}
