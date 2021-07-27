export class Menu {
    constructor(
        public id: string,
        public route: string,
        public description: string,
        public headerdiff: any[],
        public isActive: boolean
    ) {
    }
  }