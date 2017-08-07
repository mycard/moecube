/**
 * Created by zh99998 on 2016/10/25.
 */
import {Injectable} from '@angular/core';
import * as crypto from 'crypto';
import {fromPairs} from 'lodash';

export interface User {
  admin: boolean;
  avatar_url: string;
  email: string;
  external_id: number;
  moderator: boolean;
  name: string;
  username: string;
}

@Injectable()
export class LoginService {
  user: User;
  logged_in = false;
  logging_out = false;

  readonly return_sso_url = 'https://mycard.moe/login_callback'; // 这个url不会真的被使用，可以填写不存在的

  constructor() {
    const data = localStorage.getItem('login');
    if (data) {
      this.user = JSON.parse(data);
      this.logged_in = true;
    }
  }

  logout() {
    this.logging_out = true;
    this.logged_in = false;
    localStorage.removeItem('login');
  }

  loginUrl() {
    const params = new URLSearchParams();
    params.set('return_sso_url', this.return_sso_url);
    const payload = Buffer.from(params.toString()).toString('base64');

    const url = new URL('https://accounts.moecube.com');
    url.searchParams.set('sso', payload);
    url.searchParams.set('sig', crypto.createHmac('sha256', 'zsZv6LXHDwwtUAGa').update(payload).digest('hex'));
    return url.toString();
  }

  logoutUrl() {
    const url = new URL('https://accounts.moecube.com/logout');
    url.searchParams.set('redirect', 'https://mycard.moe/logout_callback');
    return url.toString();
  }

  return_sso(return_url: string) {
    if (return_url === 'https://mycard.moe/logout_callback') {
      return location.reload();
    }
    if (!return_url.startsWith(this.return_sso_url)) {
      return;
    }
    const token = new URL(return_url)['searchParams'].get('sso');
    if (!token) {
      return;
    }
    this.handleLogin(token);
  }

  handleLogin(token: string) {
    this.user = <any>fromPairs(Array.from(new URLSearchParams(Buffer.from(token, 'base64').toString())));
    this.logged_in = true;
    localStorage.setItem('login', JSON.stringify(this.user));
  }
}
