/**
 * Created by zh99998 on 16/9/2.
 */

let shadow: ShadowRoot;
const jQueryOriginal = window['jQuery'];
const jQueryShadow = require('../jquery-shadow.js');
jQueryShadow.fn.init = new Proxy(jQueryShadow.fn.init, {
    construct(target, argumentsList, newTarget) {
        let [selector, context, root] = argumentsList;
        if (shadow) {
            if (selector === 'body') {
                selector = shadow;
            } else if (selector === document) {
                selector = shadow.querySelector('#candy');
            } else if (!context) {
                context = shadow;
            }
        }
        return new target(selector, context, root);
    }
});

window['jQuery'] = jQueryShadow;

import {Component, ViewEncapsulation, OnInit, Input, OnChanges, SimpleChanges, ElementRef} from '@angular/core';
import {LoginService} from './login.service';
import {SettingsService} from './settings.sevices';
import {App} from './app';
import 'node_modules/candy/libs.min.js';
import 'node_modules/candy/candy.min.js';
import 'node_modules/candy-shop/notifyme/candy.js';
import 'node_modules/candy-shop/namecomplete/candy.js';
import 'node_modules/candy-shop/modify-role/candy.js';
import 'node_modules/candy-shop/me-does/candy.js';
import 'node_modules/candy-shop/notifications/candy.js';
import 'node_modules/candy-shop/refocus/candy.js';
import 'electron-cookies';

window['jQuery'] = jQueryOriginal;

declare const Candy: any, CandyShop: any, Base64: any;

Candy.Util.getPosLeftAccordingToWindowBounds = new Proxy(Candy.Util.getPosLeftAccordingToWindowBounds, {
    apply(target, thisArg, argumentsList) {
        argumentsList[1] -= shadow.host.getBoundingClientRect().left;
        return target.apply(thisArg, argumentsList);
    }
});
Candy.Util.getPosTopAccordingToWindowBounds = new Proxy(Candy.Util.getPosTopAccordingToWindowBounds, {
    apply(target, thisArg, argumentsList) {
        argumentsList[1] -= shadow.host.getBoundingClientRect().top;
        return target.apply(thisArg, argumentsList);
    }
});


@Component({
    moduleId: module.id,
    selector: 'candy',
    templateUrl: 'candy.component.html',
    styleUrls: ['candy.component.css'],
    encapsulation: ViewEncapsulation.Native
})
export class CandyComponent implements OnInit, OnChanges {
    @Input()
    currentApp: App;
    jid: string;
    password: string;
    nickname: string;

    constructor (private loginService: LoginService, private settingsService: SettingsService, private element: ElementRef) {
    }

    ngOnInit () {

        this.jid = this.loginService.user.username + '@mycard.moe';
        this.password = this.loginService.user.external_id.toString();
        this.nickname = this.loginService.user.username;

        shadow = this.element.nativeElement.shadowRoot;

        // 很 Tricky 的加载 Candy 的 css，这里涉及图片等资源的相对路径引用问题，如果丢给 Angular 去加载，会让相对路径找不到
        const element = document.createElement('style');
        element.innerHTML = `
            @import "node_modules/candy/libs.min.css";
            @import "node_modules/candy/res/default.css";
            @import "node_modules/candy-shop/notifyme/candy.css";
            @import "node_modules/candy-shop/namecomplete/candy.css";
            @import "node_modules/candy-shop/modify-role/candy.css"
        `;
        shadow.insertBefore(element, shadow.firstChild);

        // Candy fix
        Base64.encode = (data: string) => Buffer.from(data).toString('base64');
        Base64.decode = (data: string) => Buffer.from(data, 'base64').toString();

        Candy.View.Template.Login.form = `
            <form method="post" id="login-form" class="login-form">
                <input type="hidden" id="nickname" name="nickname" value="' + this.nickname + '"/>
                {{#displayUsername}}
                    <input type="hidden" id="username" name="username" value="' + this.jid + '"/>
                    {{#displayDomain}}
                        <span class="at-symbol">@</span>
                        <select id="domain" name="domain">{{#domains}}<option value="{{domain}}">{{domain}}</option>{{/domains}}</select>
                    {{/displayDomain}}
                {{/displayUsername}}
                {{#presetJid}}<input type="hidden" id="username" name="username" value="{{presetJid}}"/>{{/presetJid}}
                {{#displayPassword}}<input type="hidden" id="password" name="password" value="' + this.password + '"/>{{/displayPassword}}
                <input type="submit" class="button" value="{{_loginSubmit}}" />
            </form>
            `;

        Candy.Util.setCookie('candy-nostatusmessages', '1', 365);

        Candy.init('wss://chat.mycard.moe:5280/websocket', {
            core: {
                debug: false,
                autojoin: this.currentApp.conference && [this.currentApp.conference + '@conference.mycard.moe'],
                resource: 'mycard-' + Math.random().toString().split('.')[1]
            },
            view: {
                assets: 'node_modules/candy/res/',
                language: this.settingsService.getLocale().startsWith('zh') ? 'cn' : 'en',
                enableXHTML: true,
            }
        });

        CandyShop.NotifyMe.init();
        CandyShop.NameComplete.init();
        CandyShop.ModifyRole.init();
        CandyShop.MeDoes.init();
        CandyShop.Notifications.init();
        CandyShop.Refocus.init();

        Candy.Core.connect(this.jid, this.password, this.nickname);
    }

    ngOnChanges (changes: SimpleChanges): void {
        if (!Candy.Core.getConnection()) {
            return;
        }
        let conference = changes['currentApp'].currentValue.conference;
        if (!conference) {
            return;
        }
        conference += '@conference.mycard.moe';

        try {
            if (Candy.View.Pane.Chat.rooms[conference]) {
                Candy.View.Pane.Room.show(conference);
            } else {
                Candy.Core.Action.Jabber.Room.Join(conference);
            }
        } catch (error) {

        }
    }
}
