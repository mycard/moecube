import {Component, OnInit, Input, ChangeDetectorRef} from "@angular/core";
import {AppsService} from "./apps.service";
import {InstallConfig} from "./install-config";
import {SettingsService} from "./settings.sevices";
import {App} from "./app";
import {DownloadService} from "./download.service";
import {clipboard, remote} from "electron";
import * as path from "path";
import {InstallService} from "./install.service";

declare var Notification;
declare var $;

@Component({
    moduleId: module.id,
    selector: 'app-detail',
    templateUrl: 'app-detail.component.html',
    styleUrls: ['app-detail.component.css'],
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
    }

    updateInstallConfig(app: App) {
        this.installConfig = new InstallConfig(app);
        this.installConfig.installLibrary = this.settingsService.getDefaultLibrary().path;
        this.installConfig.references = [];
        for (let reference of app.references.values()) {
            this.installConfig.references.push(new InstallConfig(reference))
        }
    }

    get libraries(): string[] {
        return this.settingsService.getLibraries().map((item) => item.path);
    }

    get news() {
        return this.currentApp.news;
    }

    get mods(): App[] {
        return this.appsService.findChildren(this.currentApp);
    }

    async installMod(mod: App) {
        this.updateInstallConfig(mod);
        await this.install(mod);

    }

    async uninstall(app: App) {
        if (confirm("确认删除？")) {
            await this.installService.uninstall(app);
            app.status.status = "init";
        }
    }

    async install(targetApp: App) {
        $('#install-modal').modal('hide');

        let options = this.installConfig;

        let dependencies = targetApp.findDependencies();
        let apps = dependencies.concat(targetApp).filter((app) => {
            return !app.isInstalled()
        });
        if (options) {
            for (let reference of options.references) {
                if (reference.install && !reference.app.isInstalled()) {
                    apps.push(reference.app);
                    apps.push(...reference.app.findDependencies().filter((app) => {
                        return !app.isInstalled()
                    }))
                }
            }
        }

        let downloadPath = path.join(this.installConfig.installLibrary, "downloading");
        try {
            let downloadApps = await this.downloadService.addUris(apps, downloadPath);
            for (let app of apps) {
                this.downloadService.getProgress(app)
                    .subscribe((progress) => {
                            app.status.status = "downloading";
                            app.status.progress = progress.progress;
                            app.status.total = progress.total;
                            this.ref.detectChanges();
                        },
                        (error) => {
                        },
                        () => {
                            // 避免安装过快
                            if (app.status.status === "downloading") {
                                app.status.status = "waiting";
                                this.ref.detectChanges();
                            }
                        });

            }
            await Promise.all(downloadApps.map((app) => {
                return this.downloadService.getComplete(app)
                    .then((completeApp: App) => {
                        return this.installService.add(completeApp, options);
                    });
            }));
            for (let app of apps) {
                new Promise(async(resolve, reject) => {
                    await this.installService.getComplete(app);
                    app.status.status = 'ready';
                    resolve();
                })
            }
            await this.installService.getComplete(targetApp);
            targetApp.status.status = "ready";
            this.ref.detectChanges();
        } catch (e) {
            new Notification(targetApp.name, {body: "下载失败"});
        }
    }

    selectDir() {
        let dir = remote.dialog.showOpenDialog({properties: ['openFile', 'openDirectory']});
        console.log(dir);
        // this.appsService.installConfig.installDir = dir[0];
        return dir[0];
    }

    runApp(app: App) {
        this.appsService.runApp(app);
    }

    custom(app: App) {
        this.appsService.runApp(app, 'custom');
    }

    copy(text) {
        clipboard.writeText(text);
    }

}
