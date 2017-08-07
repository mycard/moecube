import {Component, OnInit} from '@angular/core';
import {shell} from 'electron';
import {LoginService} from '../login.service';

@Component({
  selector: 'mycard-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnInit {

  shell = shell;

  constructor(public loginService: LoginService) {
  }

  ngOnInit() {
  }

}
