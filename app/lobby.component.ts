/**
 * Created by zh99998 on 16/9/2.
 */
import {Component, OnInit, ChangeDetectorRef, ElementRef, ViewChild} from '@angular/core';
import {AppsService} from './apps.service';
import {LoginService} from './login.service';
import {App, Category} from './app';
import {shell} from 'electron';
import {SettingsService} from './settings.sevices';
// import 'typeahead.js';
// import Options = Twitter.Typeahead.Options;

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

    @ViewChild('search')
    search: ElementRef;

    constructor (private appsService: AppsService, private loginService: LoginService,
                 private settingsService: SettingsService, private ref: ChangeDetectorRef) {
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
        // 特化个 YGOPRO 国际服聊天室。其他的暂时没需求。
        if (!this.settingsService.getLocale().startsWith('zh')) {
            this.apps.get('ygopro')!.conference = 'ygopro-international'
        }
        this.ref.detectChanges();

        // $(this.search.nativeElement).typeahead(<any>{
        //     minLength: 1,
        //     highlight: true
        // }, {
        //     name: 'apps',
        //     source: (query, syncResults) => {
        //         query = query.toLowerCase();
        //         let result = Array.from(this.apps.values())
        //             .filter((app: App) => [Category.game, Category.music, Category.book].includes(app.category))
        //             .filter((app: App) => app.id.includes(query) || app.name.toLowerCase().includes(query))
        //             .map((app: App) => app.name);
        //         console.log(result);
        //         syncResults(result);
        //     }
        // });

        document.addEventListener('mousemove', (event: MouseEvent) => {
            if (!this.resizing) {
                return;
            }
            if (this.resizing.classList.contains('resize-right')) {
                let width = this.offset + event.clientX;
                if (width < 190) {
                    width = 190;
                }
                if (width > 400) {
                    width = 400;
                }
                this.resizing.style.width = `${width}px`;
            } else {
                let height = this.offset - event.clientY;
                if (height < 236) {
                    height = 236;
                }
                if (height > 540) {
                    height = 540;
                }
                this.resizing.style.height = `${height}px`;
            }
        });
        document.addEventListener('mouseup', (event: MouseEvent) => {
            document.body.classList.remove('resizing');
            this.resizing = undefined;
        });
    }

    mousedown (event: MouseEvent) {
        // console.log(()
        document.body.classList.add('resizing');
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
