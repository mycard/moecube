import {Component, OnInit} from "@angular/core";
import {AppsService} from "./apps.service";
import {InstallConfig} from "./install-config";
import {SettingsService} from "./settings.sevices";
import {App} from "./app";
import {DownloadService} from "./download.service";

declare var System;
declare var $;

import * as readline from 'readline';
import * as os from 'os';
import {clipboard, remote} from 'electron';

const sudo = new (System._nodeRequire('electron-sudo').default)({name: 'MyCard'});

sudo.fork = function (modulePath, args, options) {
    return sudo.spawn(remote.app.getPath('exe'), ['-e', modulePath]).then((child)=> {
        readline.createInterface({input: child.stdout}).on('line', (line) => {
            child.emit('message', JSON.parse(line));
        });
        child.send = (message, sendHandle, options, callback)=> {
            child.stdin.write(JSON.stringify(message) + os.EOL);
            if (callback) {
                callback()
            }
        };
        return child
    })
};

@Component({
    selector: 'app-detail',
    templateUrl: 'app/app-detail.component.html',
    styleUrls: ['app/app-detail.component.css'],
    providers: [DownloadService]
})
export class AppDetailComponent implements OnInit {
    platform = process.platform;

    fs = window['System']._nodeRequire('fs');
    electron = window['System']._nodeRequire('electron');
    spawn = window['System']._nodeRequire('child_process').spawn;
    path = window['System']._nodeRequire('path');

    installConfig: InstallConfig;

    constructor(private appsService: AppsService, private settingsService: SettingsService,
                private  downloadService: DownloadService) {
    }

    ngOnInit() {
        this.updateInstallConfig();
    }

    updateInstallConfig() {
        this.installConfig = this.appsService.getInstallConfig(this.appsService.currentApp);
        this.installConfig.installPath = this.settingsService.getDefaultLibrary().path;
    }

    get name() {
        let currentApp = this.appsService.currentApp;
        if (currentApp) {
            return currentApp.name[this.settingsService.getLocale()];
        }
        return "Loading";
    };

    get isInstalled() {
        let currentApp = this.appsService.currentApp;
        return !!(currentApp.local && currentApp.local.path);

    }


    get news() {
        let currentApp = this.appsService.currentApp;
        if (currentApp) {
            return currentApp.news;
        }
    }

    get friends() {
        return false;
    }

    get achievement() {
        return false;
    }

    get mods() {
        let contains = ["optional", "language", "emulator"];

        let currentApp = this.appsService.currentApp;
        if (currentApp) {
            if (currentApp.references[process.platform] && currentApp.references[process.platform].length > 0) {
                let refs = currentApp.references[process.platform];
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

    uninstalling: boolean;

    uninstall(id: string) {
        if (confirm("确认删除？")) {
            this.uninstalling = true;
            this.appsService.uninstall(id).then(()=> {
                    this.uninstalling = false;
                }
            );
        }
    }


    install() {
        $('#install-modal').modal('hide');
        this.appsService.download();
    }

    selectDir() {
        let dir = remote.dialog.showOpenDialog({properties: ['openFile', 'openDirectory']});
        console.log(dir);
        this.appsService.installConfig.installDir = dir[0];
        return dir[0];
    }

    startApp(app: App) {
        let execute = this.path.join(app.local.path, app.actions.get("main").execute);
        let args = app.actions.get("main").args;
        let env = app.actions.get("main").env;
        let opt = {
            cwd: app.local.path,
            env: env
        };

        let open = '';
        let openApp = app.actions.get("main").open;
        if (openApp) {
            if (this.isInstalled) {
                open = this.path.join(openApp.local.path, openApp.actions.get("main").execute);
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
            remote.getCurrentWindow().restore();
        });

        remote.getCurrentWindow().minimize();

    }

    copy(text) {
        clipboard.writeText(text);
    }

}
