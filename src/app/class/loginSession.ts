
export class LoginSession {
    constructor(
        public username: string,
        public password: string,
        public nsxmanager: string,
        public disclaimer: boolean
    ) {
    }
  }