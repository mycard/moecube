/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit} from '@angular/core';
import {AppsService} from './apps.service';
import {LoginService} from './login.service';
import {App, Category} from './app';
import {shell} from 'electron';
import {SettingsService} from './settings.sevices';

@Component({
    moduleId: module.id,
    selector: 'lobby',
    templateUrl: 'lobby.component.html',
    styleUrls: ['lobby.component.css'],

})
export class LobbyComponent implements OnInit {

    currentApp: App;
    private apps: Map<string, App>;

    resizing: HTMLElement | undefined;
    offset: number;

    constructor (private appsService: AppsService, private loginService: LoginService, private settingsService: SettingsService) {
    }

    async ngOnInit () {
        this.apps = await this.appsService.loadApps();
        if (this.apps.size > 0) {
            this.chooseApp(this.appsService.lastVisited || this.apps.get('ygopro')!);

            await this.appsService.migrate();
            for (let app of this.apps.values()) {
                await  this.appsService.update(app);
            }
        } else {
            if (confirm('获取程序列表失败,是否重试?')) {
                location.reload();
            } else {
                window.close();
            }
        }

        document.addEventListener('mousemove', (event: MouseEvent) => {
            if (!this.resizing) {
                return;
            }
            if (this.resizing.classList.contains('resize-right')) {
                let width = this.offset + event.clientX;
                if (width < 190) {
                    width = 190;
                }
                this.resizing.style.width = `${width}px`;
            } else {
                let height = this.offset - event.clientY;
                if (height < 236) {
                    height = 236;
                }
                this.resizing.style.height = `${height}px`;
            }
        });
        document.addEventListener('mouseup', (event: MouseEvent) => {
            this.resizing = undefined;
        });
    }

    mousedown (event: MouseEvent) {
        // console.log(()
        this.resizing = <HTMLElement>(<HTMLElement>event.target).parentNode;
        if (this.resizing.classList.contains('resize-right')) {
            this.offset = this.resizing.offsetWidth - event.clientX;
        } else {
            this.offset = this.resizing.offsetHeight + event.clientY;
        }
    }

    chooseApp (app: App) {
        this.currentApp = app;
        this.appsService.lastVisited = app;
    }

    get grouped_apps () {
        let contains = ['game', 'music', 'book'].map((value) => Category[value]);
        let result = {runtime: []};
        for (let app of this.apps.values()) {
            let tag: string;
            if (contains.includes(app.category)) {
                if (app.isInstalled()) {
                    tag = 'installed';
                } else {
                    tag = app.tags[0];
                }
            } else {
                if (app.isInstalled()) {
                    tag = 'runtime_installed';
                } else {
                    tag = 'runtime';
                }

            }
            if (!result[tag]) {
                result[tag] = [];
            }
            result[tag].push(app);
        }
        return result;
    }

    openExternal (url: string) {
        shell.openExternal(url);
    }
}
