import { Component, OnInit } from '@angular/core';
import { angleIcon, ClarityIcons, cogIcon, userIcon, vmBugIcon } from '@cds/core/icon';
import { Router } from '@angular/router';
import { LoginSession } from '../class/loginSession';
import { SessionService } from '../services/session.service';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.css']
})
export class HeaderComponent implements OnInit {
  public mysession: LoginSession;
  constructor(public router: Router, private session: SessionService) { 
    this.mysession = SessionService.getSession()
  }

  ngOnInit(): void {
    ClarityIcons.addIcons(vmBugIcon, cogIcon, angleIcon, userIcon);
    
  }

  logOut() {
    SessionService.logOut()
    this.router.navigate(['/login']);
  }
}
