/**
 * Created by zh99998 on 16/9/2.
 */
import {Component} from '@angular/core';
import {LoginService} from './login.service';
import * as crypto from 'crypto';
import * as querystring from 'querystring';
import * as url from 'url';
import {shell} from 'electron';

@Component({
    moduleId: module.id,
    selector: 'login',
    templateUrl: 'login.component.html',
    styleUrls: ['login.component.css'],
})
export class LoginComponent {
    url: string;
    return_sso_url = 'https://mycard.moe/login_callback'; // 这个url不会真的被使用，可以填写不存在的

    constructor (private loginService: LoginService) {

        let payload = new Buffer(querystring.stringify({
            // nonce: nonce,
            return_sso_url: this.return_sso_url
        })).toString('base64');

        let request = querystring.stringify({
            'sso': payload,
            'sig': crypto.createHmac('sha256', 'zsZv6LXHDwwtUAGa').update(payload).digest('hex')
        });
        this.url = 'https://ygobbs.com/session/sso_provider?' + request;

        if (this.loginService.logging_out) {
            this.url = 'https://ygobbs.com/logout?' + querystring.stringify({'redirect': this.url});
        }
    }

    return_sso (return_url: string) {
        if (!return_url.startsWith(this.return_sso_url)) {
            return;
        }
        let token = querystring.parse(url.parse(return_url).query).sso;
        let user = querystring.parse(new Buffer(token, 'base64').toString());

        this.loginService.login(user);
    }

    openExternal (url: string) {
        shell.openExternal(url);
    }
}
