/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit} from "@angular/core";
import {AppsService} from "./apps.service";
import {LoginService} from "./login.service";
import {App, Category} from "./app";
import {DownloadService} from "./download.service";
import {InstallService} from "./install.service";
import {Http} from "@angular/http";
import * as path from 'path';
import {InstallConfig} from "./install-config";

@Component({
    selector: 'lobby',
    templateUrl: 'app/lobby.component.html',
    styleUrls: ['app/lobby.component.css'],

})
export class LobbyComponent implements OnInit {
    candy_url: string;
    currentApp: App;
    private apps: Map<string,App>;

    constructor(private appsService: AppsService, private loginService: LoginService, private downloadService: DownloadService,
                private installService: InstallService, private http: Http) {
        this.candy_url = './candy/index.html?jid=' + this.loginService.user.username + '@mycard.moe&password=' + this.loginService.user.external_id + '&nickname=' + this.loginService.user.username + '&autojoin=ygopro_china_north@conference.mycard.moe'
    }

    ngOnInit() {
        this.appsService.loadApps()
            .then((apps)=> {
                this.apps = apps;
                this.currentApp = this.apps.get("th06");
                this.updateApp();
            })

    }

    async updateApp() {
        let updateServer = "https://thief.mycard.moe/update/metalinks/";
        let checksumServer = "https://thief.mycard.moe/checksums/";
        for (let app of this.apps.values()) {
            if (app.isInstalled() && app.version != app.local.version) {
                let checksumMap = await this.installService.getChecksumFile(app);
                let filesMap = app.local.files;
                let deleteList = [];
                let addList = [];
                let changeList = [];
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
                let metalink = await this.http.post(updateServer + app.id, changeList).map((response)=>response.text())
                    .toPromise();
                let meta = new DOMParser().parseFromString(metalink, "text/xml");
                let filename = meta.getElementsByTagName('file')[0].getAttribute('name');
                let dir = path.join(path.dirname(app.local.path), "downloading");
                let a = await this.downloadService.addMetalink(metalink, dir);

                await new Promise((resolve, reject)=> {
                    a.subscribe((status)=> {
                        console.log(status);
                    }, (err)=> {
                        reject()
                    }, ()=> {
                        resolve();
                    });
                });

                for (let file of deleteList) {
                    await this.installService.deleteFile(file);
                }
                app.local.version=app.version;
                app.local.files = checksumMap;
                localStorage.setItem(app.id, JSON.stringify(app.local));
                await this.installService.extract(path.join(dir, filename), app.local.path);
                let children = this.appsService.findChildren(app);
                for (let child of children) {
                    if (child.isInstalled()) {
                        await this.installService.uninstall(child, false);
                        this.installService.add(child, new InstallConfig(child, path.dirname((app.local.path))));
                        await this.installService.getComplete(child);
                        console.log("282828")
                    }
                }

            }
        }
    }

    chooseApp(app: App) {
        this.currentApp = app;
    }

    get grouped_apps() {
        let contains = ["game", "music", "book"].map((value)=>Category[value]);
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


