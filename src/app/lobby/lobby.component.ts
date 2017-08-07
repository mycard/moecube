import {ChangeDetectorRef, Component, ElementRef, OnInit, ViewChild} from '@angular/core';
import {shell} from 'electron';
import * as $ from 'jquery';
import {App, Category} from '../app';
import {AppsService} from '../apps.service';
import {LoginService} from '../login.service';
import {SettingsService} from '../settings.service';

const ReconnectingWebSocket = require('reconnecting-websocket');
declare const Zone;

@Component({
  selector: 'mycard-lobby',
  templateUrl: './lobby.component.html',
  styleUrls: ['./lobby.component.css']
})
export class LobbyComponent implements OnInit {

  currentApp: App;
  apps: Map<string, App>;

  resizing: HTMLElement | undefined;
  offset: number;

  @ViewChild('search')
  search: ElementRef;

  private messages: WebSocket;

  constructor(private appsService: AppsService, private loginService: LoginService,
              private settingsService: SettingsService, private ref: ChangeDetectorRef) {
  }

  get grouped_apps(): any {
    const contains = ['game', 'music', 'book'].map((value) => Category[value]);
    const result = {runtime: []};
    for (const app of this.apps.values()) {
      let tag: string;
      if (contains.includes(app.category)) {
        if (app.isInstalled()) {
          tag = 'installed';
        } else {
          tag = app.tags ? app.tags[0] : 'test';
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

  async ngOnInit() {
    this.apps = await this.appsService.loadApps();
    if (this.apps.size > 0) {
      this.chooseApp(this.appsService.lastVisited || this.apps.get('ygopro')!);
      await this.appsService.migrate();
      for (const app of this.apps.values()) {
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
      this.apps.get('ygopro')!.conference = 'ygopro-international';
    }
    this.ref.detectChanges();

    const url = new URL('wss://api.moecube.com:3100');
    const params: URLSearchParams = url.searchParams;
    params.set('user_id', this.loginService.user.email);
    this.messages = new ReconnectingWebSocket(url);
    this.messages.onmessage = async (event) => {
      const data = JSON.parse(event.data);
      console.log(data);
      this.apps = await this.appsService.loadApps();
      this.currentApp = this.apps.get(this.currentApp.id)!;
    };


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
        const main_height = event.clientY - document.getElementById('navbar')!.clientHeight;
        // console.log(event.clientY);

        Zone.current.fork({
          name: 'candy'
        }).run(() => {
          if (height > 150 && main_height > 180) {
            if (height < 230) {
              height = 230;
            }
            this.resizing.style.height = `${height}px`;
            if ($('#candy', document).attr('data-minormax') !== 'default') {
              $('#candy').attr('data-minormax', 'default');
              $('#mobile-roster-icon').css('display', 'block');
              $('#chat-toolbar').css('display', 'block');
              $('#chat-rooms').css('display', 'block');
              $('#context-menu').css('display', 'block');
              $('#mobile-roster-icon').css('display', 'block');
              $('#minimize').show();
              $('#unminimize').hide();
              $('#restore').hide();
              $('#maximize').show();
            }
          } else if (height <= 150) {
            $('#candy').attr('data-minormax', 'min');
            this.resizing.style.height = '31px';
            $('#mobile-roster-icon').css('display', 'none');
            $('#chat-toolbar').css('display', 'none');
            $('#chat-rooms').css('display', 'none');
            $('#context-menu').css('display', 'none');
            $('#mobile-roster-icon').css('display', 'none');
            $('#minimize').hide();
            $('#unminimize').show();
            $('#restore').hide();
            $('#maximize').show();
          } else if (main_height <= 180) {
            $('#candy').attr('data-minormax', 'max');
            this.resizing.style.height = 'calc( 100% - 180px )';
            $('#minimize').show();
            $('#unminimize').hide();
            $('#restore').show();
            $('#maximize').hide();
          }
        });
      }
    });
    document.addEventListener('mouseup', (event: MouseEvent) => {
      document.body.classList.remove('resizing');
      this.resizing = undefined;
    });
  }

  mousedown(event: MouseEvent) {
    // console.log(()
    document.body.classList.add('resizing');
    this.resizing = <HTMLElement>(<HTMLElement>event.target).parentNode;
    if (this.resizing.classList.contains('resize-right')) {
      this.offset = this.resizing.offsetWidth - event.clientX;
    } else {
      this.offset = this.resizing.offsetHeight + event.clientY;
    }
  }

  chooseApp(app: App) {
    this.currentApp = app;
    this.appsService.lastVisited = app;
  }

  openExternal(url: string) {
    shell.openExternal(url);
  }
}

