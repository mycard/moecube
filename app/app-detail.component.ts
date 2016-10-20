import {Component} from '@angular/core';
import {AppsService} from './apps.service'
import {RoutingService} from './routing.service'
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

    fs = window['System']._nodeRequire('fs');
    electron = window['System']._nodeRequire('electron');
    spawn = window['System']._nodeRequire('child_process').spawn;
    path = window['System']._nodeRequire('path');

    constructor(private appsService: AppsService, private routingService: RoutingService) {
    }

    _currentApp;
    get currentApp(): App {
        return this.appsService.searchApp(this.routingService.app);
    }

    _name;
    get name() {
        if (this.currentApp) {
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
        if (this.currentApp) {
            if (this.currentApp.news.length > 0) {
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
        let contains = ["optional", "language", "emulator"];

        if (this.currentApp) {
            if (this.currentApp.references[process.platform] && this.currentApp.references[process.platform].length > 0) {
                let refs = this.currentApp.references[process.platform];
                refs = refs.filter((ref)=> {
                    return contains.includes(ref.type);
                });
                refs = refs.map((ref)=> {
                    let tmp = Object.create(ref);
                    switch (tmp.type) {
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


    checkInstall(id): boolean {
        if (this.appsService.searchApp(id)) {
            let local = this.appsService.searchApp(id).local;
            if (local && local.path) {
                return true;
            }
        }
        return false;
    }

    install(id) {
        let uri = this.appsService.searchApp(id).download[process.platform];
        $('#install-modal').modal('hide');
        if (uri) {
            this.appsService.download(id, uri);
        } else {
            console.log("lost download uri!");
        }

    }

    uninstall(id: string) {
        id = this.currentApp.id;
        this.appsService.uninstall(id);
    }


    installSubmit(theForm) {
        console.log(theForm);
        this.install(this.routingService.app);
        for (let mod in this.appsService.installConfig.mods) {
            if (this.appsService.installConfig.mods[mod]) {
                this.install(mod);
            }
        }
    }

    selectDir() {
        let dir = this.electron.remote.dialog.showOpenDialog({properties: ['openFile', 'openDirectory']});
        console.log(dir);
        this.appsService.installConfig.installDir = dir[0];
        return dir[0];
    }

    startApp(id) {
        let execute = this.path.join(this.appsService.searchApp(id).local.path, this.appsService.searchApp(id).actions[process.platform]["main"].execute);
        let args = this.appsService.searchApp(id).actions[process.platform]["main"].args;
        let env = this.appsService.searchApp(id).actions[process.platform]["main"].env;
        let opt = {
            cwd: this.appsService.searchApp(id).local.path,
            env: env
        };

        let open = '';
        let openId = this.appsService.searchApp(id).actions[process.platform]["main"].open;
        if (openId) {
            this.appsService.searchApp(openId).actions[process.platform]["main"].execute;
            if (this.checkInstall(openId)) {
                open = this.path.join(this.appsService.searchApp(openId).local.path, this.appsService.searchApp(openId).actions[process.platform]["main"].execute);
                args.push(execute);
            } else {
                console.error('open app not found');
            }
        } else {
            //没有需要通过open启动依赖,直接启动程序
            open = execute;
        }

        let handle = this.spawn(open, args, opt);

        handle.stdout.on('data', (data) => {
            console.log(`stdout: ${data}`);
        });

        handle.stderr.on('data', (data) => {
            console.log(`stderr: ${data}`);
        });

        handle.on('close', (code) => {
            console.log(`child process exited with code ${code}`);
            this.electron.remote.getCurrentWindow().restore();
        });

        this.electron.remote.getCurrentWindow().minimize();

    }


}
