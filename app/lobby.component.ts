/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit, ElementRef, ViewChild} from "@angular/core";
import {AppsService} from "./apps.service";
import {LoginService, User} from "./login.service";
import {App, Category} from "./app";
import {DownloadService} from "./download.service";
import {InstallService} from "./install.service";
import {Http, URLSearchParams} from "@angular/http";
import * as path from 'path';
import {InstallConfig} from "./install-config";
import {AppLocal} from "./app-local";
import {UrlResolver} from "@angular/compiler";
import WebViewElement = Electron.WebViewElement;

@Component({
    selector: 'lobby',
    templateUrl: 'app/lobby.component.html',
    styleUrls: ['app/lobby.component.css'],

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

        // 尝试更新应用
        this.updateApp();
    }

    chooseApp(app: App) {
        this.currentApp = app;
        if (this.candy && this.currentApp.conference) {
            (<WebViewElement>this.candy.nativeElement).send('join', this.currentApp.conference + '@conference.mycard.moe');
        }
    }

    async updateApp() {
        let updateServer = "https://thief.mycard.moe/update/metalinks/";
        let checksumServer = "https://thief.mycard.moe/checksums/";
        for (let app of this.apps.values()) {
            if (app.isInstalled() && app.version != (<AppLocal>app.local).version) {
                let checksumMap = await this.installService.getChecksumFile(app);
                let filesMap = (<AppLocal>app.local).files;
                let deleteList: string[] = [];
                let addList: string[] = [];
                let changeList: string[] = [];
                for (let [file,checksum] of filesMap) {
                    let t = checksumMap.get(file);
                    if (!t) {
                        deleteList.push(file);
                    } else if (t !== checksum) {
                        changeList.push(file);
                    }
                }
                for (let file of checksumMap.keys()) {
                    if (!filesMap.has(file)) {
                        changeList.push(file);
                    }
                }
                let metalink = await this.http.post(updateServer + app.id, changeList).map((response) => response.text())
                    .toPromise();
                let meta = new DOMParser().parseFromString(metalink, "text/xml");
                let filename = meta.getElementsByTagName('file')[0].getAttribute('name');
                let dir = path.join(path.dirname((<AppLocal>app.local).path), "downloading");
                let a = await this.downloadService.addMetalink(metalink, dir);

                await new Promise((resolve, reject) => {
                    a.subscribe((status) => {
                        console.log(status);
                    }, (err) => {
                        reject()
                    }, () => {
                        resolve();
                    });
                });

                for (let file of deleteList) {
                    await this.installService.deleteFile(file);
                }
                (<AppLocal>app.local).version = app.version;
                (<AppLocal>app.local).files = checksumMap;
                localStorage.setItem(app.id, JSON.stringify(app.local));
                await this.installService.extract(path.join(dir, filename), (<AppLocal>app.local).path);
                let children = this.appsService.findChildren(app);
                for (let child of children) {
                    if (child.isInstalled()) {
                        await this.installService.uninstall(child, false);
                        this.installService.add(child, new InstallConfig(child, path.dirname(((<AppLocal>app.local).path))));
                        await this.installService.getComplete(child);
                        console.log("282828")
                    }
                }

            }
        }
    }


    get grouped_apps() {
        let contains = ["game", "music", "book"].map((value) => Category[value]);
        let result = {};
        for (let app of this.apps.values()) {
            if (contains.includes(app.category)) {
                let tag;
                if (app.isInstalled()) {
                    tag = 'installed';
                } else {
                    tag = app.tags[0];
                }
                if (!result[tag]) {
                    result[tag] = []
                }
                result[tag].push(app)
            }
        }
        return result
    }
}
