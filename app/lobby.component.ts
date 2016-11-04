/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit} from "@angular/core";
import {AppsService} from "./apps.service";
import {LoginService} from "./login.service";
import {App, Category} from "./app";
import {DownloadService} from "./download.service";
@Component({
    selector: 'lobby',
    templateUrl: 'app/lobby.component.html',
    styleUrls: ['app/lobby.component.css'],

})
export class LobbyComponent implements OnInit {
    candy_url: string;
    currentApp: App;
    private apps: Map<string,App>;

    constructor(private appsService: AppsService, private loginService: LoginService,private downloadService:DownloadService) {
        this.candy_url = './candy/index.html?jid=' + this.loginService.user.username + '@mycard.moe&password=' + this.loginService.user.external_id + '&nickname=' + this.loginService.user.username + '&autojoin=ygopro_china_north@conference.mycard.moe'
    }

    ngOnInit() {
        this.appsService.loadApps()
            .then((apps)=> {
                this.apps = apps;
                this.currentApp = this.apps.get("th06");
            })
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


