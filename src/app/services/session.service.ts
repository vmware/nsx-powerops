import { Injectable, Inject } from '@angular/core';
import { DOCUMENT, PlatformLocation } from '@angular/common';
import { Router } from '@angular/router';
import { LoginSession } from '../class/loginSession';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class SessionService {

  static logOut() {
    localStorage.removeItem("login");
    localStorage.clear()
  }

  static getSession(): LoginSession {
    try {
        let test = <string>localStorage.getItem("login")
        return JSON.parse(test)
    } catch (error) {
        return new LoginSession("","","", false)
    }
  }
  constructor(
    @Inject(DOCUMENT) private document: Document, 
    private plaformLocation: PlatformLocation,
    private router: Router,
    public http: HttpClient) { }

  public logOn(session: LoginSession) {
    localStorage.setItem('login', JSON.stringify(session))
    
    this.router.navigate(['home']);
  }
  public isLogged(): boolean {
    return SessionService.getSession() != null
  }

  public postAPI(mysession: { nsxmanager: any; username: string; password: string; }, url: string, body: any) {
    const httpOptions = {
      headers: new HttpHeaders({
        'Content-Type':  'application/json',
        'Access-Control-Allow-Origin': '*',
        'Accept': '*/*',
        'NSX': mysession.nsxmanager,
        'Authorization': 'Basic ' + btoa(mysession.username + ':' + mysession.password),
        'Access-Control-Allow-Methods': 'OPTIONS, HEAD, GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Accept, Content-Type,Access-Control-Allow-Origin,Access-Control-Allow-Methods, Authorization'
        })
      };
      return this.http.post<any>('http://' + this.plaformLocation.hostname + ':8080' + url, httpOptions).toPromise()
  }


  public async getAPI(mysession: { nsxmanager: any; username: string; password: string; }, url: string): Promise<any> {
    const httpOptions = {
      headers: new HttpHeaders({
        'Content-Type':  'application/json',
        'Access-Control-Allow-Origin': '*',
        'Accept': '*/*',
        'NSX': mysession.nsxmanager,
        'Authorization': 'Basic ' + btoa(mysession.username + ':' + mysession.password),
        'Access-Control-Allow-Methods': 'OPTIONS, HEAD, GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Accept, Content-Type,Access-Control-Allow-Origin,Access-Control-Allow-Methods, Authorization'
        })
      };

      return this.http.get<any>('http://' + this.plaformLocation.hostname + ':8080' + url, httpOptions)
        .pipe(map((data) => data)).toPromise()
        .then((response) => {
          return response
        })
        .catch((error: HttpErrorResponse) => {
          console.error(error.status, error.statusText)
          return {'result_count': 0, 'results': []}
        })
      // With Proxy inside ng serve (proxy.conf.json)
      //return =  this.http.get<any>('http://' + 'localhost:4200' + url, httpOptions).toPromise();
  }
}