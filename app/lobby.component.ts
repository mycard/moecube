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
                let main_height=event.clientY-document.getElementById('navbar')!.clientHeight;

                let minimized: HTMLElement = $('#minimized')[0];
                let maximized: HTMLElement = $('#maximized')[0];
                console.log(event.clientY);
                if (height > 150 && main_height>180) {
                    if (height < 230) {
                        height = 230;
                    }
                    this.resizing.style.height = `${height}px`;
                    if($('#candy').attr('data-minormax')!='default') {
                        $('#candy').attr('data-minormax', 'default');
                        $('#mobile-roster-icon').css('display', 'block');
                        $('#chat-toolbar').css('display', 'block');
                        $('#chat-rooms').css('display', 'block');
                        $('#context-menu').css('display', 'block');
                        $('#mobile-roster-icon').css('display', 'block');
                        $(minimized).removeClass('fa-clone');
                        $(minimized).addClass('fa-minus');
                        $(maximized).removeClass('fa-clone');
                        $(maximized).addClass('fa-expand');
                    }
                }else if(height<=150){
                    $('#candy').attr('data-minormax','min');
                    this.resizing.style.height='31px';
                    $('#mobile-roster-icon').css('display','none');
                    $('#chat-toolbar').css('display','none');
                    $('#chat-rooms').css('display','none');
                    $('#context-menu').css('display','none');
                    $('#mobile-roster-icon').css('display','none');
                    $(minimized).addClass('fa-clone');
                    $(minimized).removeClass('fa-minus');
                    $(maximized).removeClass('fa-clone');
                    $(maximized).addClass('fa-expand');
                }else if(main_height<=180){
                    $('#candy').attr('data-minormax','max');
                    this.resizing.style.height='calc( 100% - 180px )';
                    $(minimized).removeClass('fa-clone');
                    $(minimized).addClass('fa-minus');
                    $(maximized).removeClass('fa-expand');
                    $(maximized).addClass('fa-clone');
                }
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
