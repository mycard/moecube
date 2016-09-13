import { Component } from '@angular/core';
import { AppsService } from './apps.service'
import { RoutingService } from './routing.service'
import {App} from "./app";

declare var process;
declare var $;

@Component({
    selector: 'app-detail',
    templateUrl: 'app/app-detail.component.html',
    styleUrls: ['app/app-detail.component.css'],
})
export class AppDetailComponent {
    platform = process.platform;

    electron = window['System']._nodeRequire('electron');

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
        } else {
            console.log("lost download uri!");

        }
    }


    installSubmit(theForm) {
        console.log(theForm);
        this.install(this.routingService.app);
        for(let mod in this.appsService.installConfig.mods) {
            if(this.appsService.installConfig.mods[mod]) {
                this.install(mod);
            }
        }

        $("#install-modal").modal("hide");
    }

    selectDir() {
        let dir = this.electron.remote.dialog.showOpenDialog({properties: ['openFile', 'openDirectory']});
        console.log(dir);
        this.appsService.installConfig.installDir = dir[0];
        return dir[0];
    }
    openDir(id) {
        this.appsService.data.map((v)=>{
            if(v.id == id) {
                this.electron.remote.shell.showItemInFolder(v.local.path);
            }

        });

    }

}
