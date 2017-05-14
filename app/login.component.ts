/**
 * Created by zh99998 on 16/9/2.
 */
import { Component } from '@angular/core';
import { LoginService } from './login.service';
import * as crypto from 'crypto';
import { shell } from 'electron';

@Component({
    moduleId: module.id,
    selector: 'login',
    templateUrl: 'login.component.html',
    styleUrls: ['login.component.css'],
})
export class LoginComponent {
    url: string;
    readonly return_sso_url = 'https://moecube.com/login_callback'; // 这个url不会真的被使用，可以填写不存在的

    constructor(private loginService: LoginService) {

        let params = new URLSearchParams();
        params.set('return_sso_url', this.return_sso_url);
        let payload = Buffer.from(params.toString()).toString('base64');

        let url = new URL('https://accounts.moecube.com');
        params = url['searchParams'];
        params.set('sso', payload);
        params.set('sig', crypto.createHmac('sha256', 'zsZv6LXHDwwtUAGa').update(payload).digest('hex'));

        this.url = url.toString();

        if (this.loginService.logging_out) {
            url = new URL('https://ygobbs.com/logout');
            params = url['searchParams'];
            // params.set('redirect', this.url);

            // 暂时 hack 一下登出，因为聊天室现在没办法重新初始化，于是登出后刷新页面。
            params.set('redirect', 'https://moecube.com/logout_callback');
            this.url = url.toString();
        }
    }

    return_sso(return_url: string) {
        if (return_url === 'https://moecube.com/logout_callback') {
            return location.reload();
        }
        if (!return_url.startsWith(this.return_sso_url)) {
            return;
        }
        let token = new URL(return_url)['searchParams'].get('sso');
        if (!token) {
            return;
        }
        let user = this.toObject(new URLSearchParams(Buffer.from(token, 'base64').toString()));
        this.loginService.login(user);
    }

    toObject(entries: Iterable<[string, any]>): any {
        let result = {};
        for (let [key, value] of entries) {
            result[key] = value;
        }
        return result;
    }

    openExternal(url: string) {
        shell.openExternal(url);
    }
}
