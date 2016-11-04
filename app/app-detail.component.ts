import {Component, OnInit, Input, ChangeDetectorRef} from "@angular/core";
import {AppsService} from "./apps.service";
import {InstallConfig} from "./install-config";
import {SettingsService} from "./settings.sevices";
import {App} from "./app";
import {DownloadService} from "./download.service";
import {clipboard, remote, ipcRenderer} from "electron";
import * as path from "path";
import * as child_process from "child_process";
import {InstallService} from "./install.service";

declare var Notification;
declare var $;

@Component({
    selector: 'app-detail',
    templateUrl: 'app/app-detail.component.html',
    styleUrls: ['app/app-detail.component.css'],
})
export class AppDetailComponent implements OnInit {
    @Input()
    currentApp: App;
    platform = process.platform;

    installConfig: InstallConfig;

    constructor(private appsService: AppsService, private settingsService: SettingsService,
                private  downloadService: DownloadService, private installService: InstallService,
                private ref: ChangeDetectorRef) {
    }

    ngOnInit() {
        // this.updateInstallConfig();
        ipcRenderer.on('download-message-reply', (event, arg)=> {
            console.log(arg);
        });
        ipcRenderer.send("download-message", "ping")
    }

    updateInstallConfig() {
        this.installConfig = new InstallConfig(this.currentApp);
        this.installConfig.installLibrary = this.settingsService.getDefaultLibrary().path;
        this.installConfig.references = [];
        for (let reference of this.currentApp.references.values()) {
            this.installConfig.references.push(new InstallConfig(reference))
        }
    }

    get libraries(): string[] {
        return this.settingsService.getLibraries().map((item)=>item.path);
    }

    get news() {
        return this.currentApp.news;
    }

    get friends() {
        return false;
    }

    get achievement() {
        return false;
    }

    get mods() {
        // let contains = ["optional", "language", "emulator"];
        //
        // let currentApp = this.appsService.currentApp;
        // if (currentApp) {
        //     if (currentApp.references[process.platform] && currentApp.references[process.platform].length > 0) {
        //         let refs = currentApp.references[process.platform];
        //         refs = refs.filter((ref)=> {
        //             return contains.includes(ref.type);
        //         });
        //         refs = refs.map((ref)=> {
        //             let tmp = Object.create(ref);
        //             switch (tmp.type) {
        //                 case "optional":
        //                     tmp.type = "选项";
        //                     break;
        //                 case "language":
        //                     tmp.type = "语言";
        //                     break;
        //                 default:
        //                     break;
        //             }
        //             //console.log(tmp.type);
        //             return tmp;
        //         });
        //         return refs;

        //return this.currentApp.references[process.platform];
        // }
        // }
        return [];
    }

    uninstalling: boolean;

    uninstall(id: string) {
        if (confirm("确认删除？")) {
            this.uninstalling = true;
            // this.appsService.uninstall(id).then(()=> {
            //         this.uninstalling = false;
            //     }
            // );
        }
    }

    async install() {
        $('#install-modal').modal('hide');

        let currentApp = this.currentApp;
        let options = this.installConfig;

        let dependencies = currentApp.findDependencies();
        let apps = dependencies.concat(currentApp).filter((app)=>!app.isInstalled());

        for (let reference of options.references) {
            if (reference.install) {
                apps.push(reference.app);
                apps.push(...reference.app.findDependencies())
            }
        }

        let downloadPath = path.join(this.installConfig.installLibrary, "downloading");
        try {
            let downloadApps = await this.downloadService.addUris(apps, downloadPath);
            this.downloadService.getProgress(currentApp)
                .subscribe((progress)=> {
                        currentApp.status.status = "downloading";
                        currentApp.status.progress = progress.progress;
                        currentApp.status.total = progress.total;
                        this.ref.detectChanges();
                    },
                    (error)=> {
                    },
                    ()=> {
                        currentApp.status.status = "waiting";
                        this.ref.detectChanges();

                    });
            await Promise.all(downloadApps.map((app)=> {
                return this.downloadService.getComplete(app)
                    .then((completeApp: App)=> {
                        return this.installService.add(completeApp, options);
                    });
            }));
            currentApp.status.status = "ready";
        } catch (e) {
            new Notification(currentApp.name, {body: "下载失败"});
        }


    }

    selectDir() {
        let dir = remote.dialog.showOpenDialog({properties: ['openFile', 'openDirectory']});
        console.log(dir);
        // this.appsService.installConfig.installDir = dir[0];
        return dir[0];
    }

    startApp(app: App) {
        let execute = path.join(app.local.path, app.actions.get("main").execute);
        let args = app.actions.get("main").args;
        let env = app.actions.get("main").env;
        let opt = {
            cwd: app.local.path,
            env: env
        };

        let open = '';
        let openApp = app.actions.get("main").open;
        if (openApp) {
            open = path.join(openApp.local.path, openApp.actions.get("main").execute);
            args.push(execute);
        } else {
            //没有需要通过open启动依赖,直接启动程序
            open = execute;
        }

        let handle = child_process.spawn(open, args, opt);

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
