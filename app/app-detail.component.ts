import {Component, OnInit, Input, ChangeDetectorRef} from "@angular/core";
import {AppsService} from "./apps.service";
import {InstallOption} from "./install-option";
import {SettingsService} from "./settings.sevices";
import {App} from "./app";
import {DownloadService} from "./download.service";
import {clipboard, remote} from "electron";
import * as path from "path";
import {InstallService} from "./install.service";

declare const Notification: any;
declare const $: any;

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

    installOption: InstallOption;

    references: App[];
    referencesInstall: {[id: string]: boolean};

    constructor(private appsService: AppsService, private settingsService: SettingsService,
                private  downloadService: DownloadService, private installService: InstallService,
                private ref: ChangeDetectorRef) {
    }

    ngOnInit() {
    }

    updateInstallOption(app: App) {
        this.installOption = new InstallOption(app);
        this.installOption.installLibrary = this.settingsService.getDefaultLibrary().path;
        this.references = Array.from(app.references.values());
        console.log(this.references);
        this.referencesInstall = {};
        for (let reference of this.references) {
            this.referencesInstall[reference.id] = true;
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
        this.updateInstallOption(mod);
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

        let options = this.installOption;

        try {
            await this.appsService.install(targetApp, options);
            if (this.references.length > 0) {
                for (let [id,isInstalled] of Object.entries(this.referencesInstall)) {
                    if (isInstalled) {
                        let reference = targetApp.references.get(id)!;
                        await  this.appsService.install(reference, options);
                    }
                }
            }
        } catch (e) {
            console.error(e);
            new Notification(targetApp.name, {body: "下载失败"});
        }
    }

    selectDir() {
        let dir = remote.dialog.showOpenDialog({properties: ['openFile', 'openDirectory']});
        console.log(dir);
        // this.appsService.installOption.installDir = dir[0];
        return dir[0];
    }

    runApp(app: App) {
        this.appsService.runApp(app);
    }

    custom(app: App) {
        this.appsService.runApp(app, 'custom');
    }

    copy(text: string) {
        clipboard.writeText(text);
    }

}
