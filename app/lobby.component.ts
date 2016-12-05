/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit, ElementRef, ViewChild} from "@angular/core";
import {AppsService} from "./apps.service";
import {LoginService} from "./login.service";
import {App, Category} from "./app";
import {DownloadService} from "./download.service";
import {InstallService} from "./install.service";
import {Http, URLSearchParams} from "@angular/http";
import * as path from "path";
import {InstallOption} from "./install-option";
import {AppLocal} from "./app-local";
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

    constructor(private appsService: AppsService, private loginService: LoginService, private downloadService: DownloadService,
                private installService: InstallService, private http: Http) {
    }

    async ngOnInit() {
        this.apps = await this.appsService.loadApps();
        this.chooseApp(Array.from(this.apps.values()).find(app => app.isInstalled()) || <App>this.apps.get("ygopro"));

        // 初始化聊天室
        let url = new URL('candy/index.html', location.href);
        let params: URLSearchParams = url['searchParams']; // TypeScrpt 缺了 url.searchParams 的定义
        params.set('jid', this.loginService.user.username + '@mycard.moe');
        params.set('password', this.loginService.user.external_id.toString());
        params.set('nickname', this.loginService.user.username);
        params.set('autojoin', this.currentApp.conference + '@conference.mycard.moe');
        this.candy_url = url;
    }

    chooseApp(app: App) {
        this.currentApp = app;
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
}
