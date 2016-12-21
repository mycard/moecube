/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit, ElementRef, ViewChild} from "@angular/core";
import {AppsService} from "./apps.service";
import {LoginService} from "./login.service";
import {App, Category} from "./app";
import {URLSearchParams} from "@angular/http";
import {shell} from "electron";
import {SettingsService} from "./settings.sevices";
import WebViewElement = Electron.WebViewElement;

@Component({
    moduleId: module.id,
    selector: 'lobby',
    templateUrl: 'lobby.component.html',
    styleUrls: ['lobby.component.css'],

})
export class LobbyComponent implements OnInit {
    @ViewChild('candy')
    candy?: ElementRef;
    candy_url: URL;
    currentApp: App;
    private apps: Map<string,App>;

    constructor(private appsService: AppsService, private loginService: LoginService, private settingsService: SettingsService) {
    }

    async ngOnInit() {
        this.apps = await this.appsService.loadApps();
        if (this.apps.size > 0) {
            this.chooseApp(this.appsService.lastVisited || this.apps.get("ygopro")!);

            // 初始化聊天室
            let url = new URL('candy.html', location.href);
            let params: URLSearchParams = url['searchParams']; // TypeScrpt 缺了 url.searchParams 的定义
            params.set('jid', this.loginService.user.username + '@mycard.moe');
            params.set('password', this.loginService.user.external_id.toString());
            params.set('nickname', this.loginService.user.username);
            switch (this.settingsService.getLocale()) {
                case 'zh-CN':
                    params.set('language', 'cn');
                    break;
                default:
                    params.set('language', 'en');
            }
            if (this.currentApp.conference) {
                params.set('autojoin', this.currentApp.conference + '@conference.mycard.moe');
            }
            this.candy_url = url;
            await this.appsService.migrate();
            for (let app of this.apps.values()) {
                await  this.appsService.update(app);
            }
        } else {
            if (confirm("获取程序列表失败,是否重试?")) {
                location.reload();
            } else {
                window.close();
            }
        }
    }

    chooseApp(app: App) {
        this.currentApp = app;
        this.appsService.lastVisited = app;
        if (this.candy && this.currentApp.conference) {
            (<WebViewElement>this.candy.nativeElement).send('join', this.currentApp.conference + '@conference.mycard.moe');
        }
    }

    get grouped_apps() {
        let contains = ["game", "music", "book"].map((value) => Category[value]);
        let result = {runtime: []};
        for (let app of this.apps.values()) {
            let tag: string;
            if (contains.includes(app.category)) {
                if (app.isInstalled()) {
                    tag = 'installed';
                } else {
                    tag = app.tags[0];
                }
            } else {
                if (app.isInstalled()) {
                    tag = 'runtime_installed';
                } else {
                    tag = 'runtime';
                }

            }
            if (!result[tag]) {
                result[tag] = []
            }
            result[tag].push(app)
        }
        return result
    }

    openExternal(url: string) {
        shell.openExternal(url);
    }
}
