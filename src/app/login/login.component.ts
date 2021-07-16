import { Component, OnInit, Inject } from '@angular/core';
import { DOCUMENT, PlatformLocation } from '@angular/common';
import { Router } from '@angular/router';
import { FormGroup, Validators, FormControl } from '@angular/forms';
import { HttpClient, HttpHeaders} from '@angular/common/http';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';
import { ClarityIcons, exclamationCircleIcon } from '@cds/core/icon';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})

export class LoginComponent implements OnInit {
  // public mysession = new LoginSession('', '', '',false)
  public mysession: LoginSession
  form: FormGroup;
  alert: boolean = false;

  constructor(
    @Inject(DOCUMENT) private document: Document, 
    private plaformLocation: PlatformLocation,
    public router: Router,
    public http: HttpClient,
    private sessionService: SessionService
    ) { }

  ngOnInit() {
    this.mysession = new LoginSession('', '', '',false)
    this.form =  new FormGroup({
      nsxmanager: new FormControl(this.mysession.nsxmanager, Validators.required),
      username: new FormControl(this.mysession.username, Validators.required),
      password: new FormControl(this.mysession.password, Validators.required),
      disclaimer: new FormControl(this.mysession.disclaimer, Validators.required)
    });

    ClarityIcons.addIcons(exclamationCircleIcon);
    if (this.sessionService.isLogged()) {
      this.router.navigate(['home/network'])
    }
  }

  onSubmit(): void{
    this.alert = false
    this.form.setValue(
      {
        "nsxmanager": this.mysession.nsxmanager,
        "password": this.mysession.password,
        "username": this.mysession.username,
        "disclaimer": this.mysession.disclaimer
    }
    )

    this.form.updateValueAndValidity()
    if (this.form.valid && this.mysession.disclaimer) {
      let body = 'j_username=' + this.mysession.username +'&j_password=' + this.mysession.password
      this.alert = false

      const httpOptions = new HttpHeaders({
          'Content-Type':  'application/json',
          'Access-Control-Allow-Origin': '*',
          'Accept': '*/*',
          'NSX': this.mysession.nsxmanager,
          'Access-Control-Allow-Methods': 'OPTIONS, HEAD, GET, POST, PUT, DELETE',
          'Access-Control-Allow-Headers': 'Content-Type,Access-Control-Allow-Origin,Access-Control-Allow-Methods, Authorization'
        })
      
      this.http.post('http://' + this.plaformLocation.hostname + ':8080' + '/api/session/create', body, {'headers': httpOptions, 'observe': "response"}).toPromise().then(
          result => {
            this.sessionService.logOn(this.mysession);
            this.router.navigate(['home/network'])
            },
            error => { 
              this.alert = true
              console.error(error) }
            );
    }
    else{
      this.alert = true
    }
  }
}
/*
export class Session {
  constructor(public nsxmanager: string, public username: string, public password: string){}
}
*/