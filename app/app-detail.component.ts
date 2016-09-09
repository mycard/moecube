import { Component } from '@angular/core';
import { AppsService } from './apps.service'
import { RoutingService } from './routing.service'
import {App} from "./app";

declare var process;

@Component({
    selector: 'app-detail',
    templateUrl: 'app/app-detail.component.html',
    styleUrls: ['app/app-detail.component.css'],
})
export class AppDetailComponent {
    platform = process.platform;

    constructor(private appsService: AppsService, private routingService: RoutingService ) {
    }
    _currentApp;
    get currentApp(): App {
        return this.searchApp(this.routingService.app);
    }

    _name;
    get name() {
        if(this.currentApp) {
            return this.currentApp.name[this.currentApp.locales[0]];
        }
        return "Loading";
    };

    _isInstalled;
    get isInstalled() {
        return this.checkInstall(this.routingService.app);
    }


    _news;
    get news() {
        if(this.currentApp) {
            if(this.currentApp.news.length > 0) {
                return this.currentApp.news;
            }
        }
    }

    _friends;
    get friends() {
        return false;
    }

    _achievement;
    get achievement() {
        return false;
    }

    _mods;
    get mods() {
        let contains = ["optional", "language"];

        if(this.currentApp) {
            if(this.currentApp.references[process.platform] && this.currentApp.references[process.platform].length > 0) {
                let refs = this.currentApp.references[process.platform];
                refs = refs.filter((ref)=>{
                    return contains.includes(ref.type);
                });
                refs = refs.map((ref)=>{
                    let tmp = Object.create(ref);
                    switch(tmp.type) {
                        case "optional":
                            tmp.type = "选项";
                            break;
                        case "language":
                            tmp.type = "语言";
                            break;
                        default:
                            break;
                    }
                    //console.log(tmp.type);
                    return tmp;
                });
                return refs;

                //return this.currentApp.references[process.platform];
            }
        }
    }


    searchApp(id): App {
        let data = this.appsService.data;
        let tmp;
        if(data) {
            tmp = data.find((v)=>v.id === id);
            return tmp;
        }
    }

    checkInstall(id): boolean {
        if(this.searchApp(id)) {
            if(this.searchApp(id).local.path) {
                return true;
            }
        }
        return false;
    }

    install(id) {
        let uri = this.searchApp(id).download;
        if(uri) {
            this.appsService.download(id, uri);
        }


    }

    model;

}
