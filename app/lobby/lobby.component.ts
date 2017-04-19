/**
 * Created by zh99998 on 16/9/2.
 */
import { ChangeDetectorRef, Component, ElementRef, OnInit, ViewChild } from '@angular/core';
import { shell } from 'electron';
import { URLSearchParams } from '@angular/http';
import { Category, Cube } from '../cube';
import { CubesService } from '../cubes.service';
import { LoginService } from '../login.service';
import { SettingsService } from '../settings.sevices';
import { ActivatedRoute, Router } from '@angular/router';
import * as ReconnectingWebSocket from 'reconnecting-websocket';

// import 'typeahead.js';
// import Options = Twitter.Typeahead.Options;

@Component({

  selector: 'lobby',
  templateUrl: './lobby.component.html',
  styleUrls: ['./lobby.component.css'],

})
export class LobbyComponent implements OnInit {

  readonly tags = ['installed', 'recommend', 'test', 'mysterious', 'touhou', 'touhou_pc98', 'runtime_installed'];

  currentApp: Cube;
  private apps: Map<string, Cube>;

  resizing: HTMLElement | undefined;
  offset: number;

  @ViewChild('search')
  search: ElementRef;

  private messages: WebSocket;

  constructor(private appsService: CubesService, private loginService: LoginService,
              private settingsService: SettingsService, private ref: ChangeDetectorRef,
              private route: ActivatedRoute, private router: Router) {
  }

  async ngOnInit() {
    try {
      this.apps = await this.appsService.loadCubes();
    } catch (error) {
      console.error(error);
      // if (confirm('获取程序列表失败,是否重试?')) {
      //   location.reload();
      // } else {
      //   window.close();
      // }
      return;
    }

    await this.router.navigate(['lobby', this.appsService.lastVisited ? this.appsService.lastVisited.id : 'ygopro']);

    await this.appsService.migrate();
    for (let app of this.apps.values()) {
      await this.appsService.update(app);
    }

    // 特化个 YGOPRO 国际服聊天室。其他的暂时没需求。
    if (!this.settingsService.getLocale().startsWith('zh')) {
      this.apps.get('ygopro')!.conference = 'ygopro-international';
    }
    // this.ref.detectChanges();

    let url = new URL('wss://api.moecube.com:3100');
    let params: URLSearchParams = url['searchParams'];
    params.set('user_id', this.loginService.user.email);
    // 不知道是不是 ReconnectingWebsocket 的类型定义文件写的有问题
    this.messages = new (<any>ReconnectingWebSocket)(url);
    this.messages.onmessage = async (event) => {
      let data = JSON.parse(event.data);
      console.log(data);
      this.apps = await this.appsService.loadCubes();
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
    //             .filter((app: Cube) => [Category.game, Category.music, Category.book].includes(app.category))
    //             .filter((app: Cube) => app.id.includes(query) || app.name.toLowerCase().includes(query))
    //             .map((app: Cube) => app.name);
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
        let main_height = event.clientY - document.getElementById('navbar')!.clientHeight;
        // console.log(event.clientY);
        if (height > 150 && main_height > 180) {
          if (height < 230) {
            height = 230;
          }
          this.resizing.style.height = `${height}px`;
          if ($('#candy').attr('data-minormax') !== 'default') {
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

  select(app: Cube) {

    this.appsService.lastVisited = app;
  }


  get grouped_apps(): { [tag: string]: Cube[] } {
    let contains = ['game', 'music', 'book'].map((value) => Category[value]);
    let result = { runtime: [] };
    for (let app of this.apps.values()) {
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

  openExternal(url: string) {
    shell.openExternal(url);
  }
}
