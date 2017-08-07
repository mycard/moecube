import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  Input,
  NgZone,
  OnChanges,
  OnInit,
  SimpleChanges,
  ViewEncapsulation
} from '@angular/core';
import * as crypto from 'crypto';
import * as $ from 'jquery';
import {App} from '../app';
import {LoginService} from '../login.service';
import {Candy, CandyFix, CandyShop} from './candy';

declare const Zone;

@Component({
  selector: 'mycard-candy',
  templateUrl: './candy.component.html',
  styleUrls: ['./candy.component.css'],
  encapsulation: ViewEncapsulation.Native,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CandyComponent implements OnInit, OnChanges {

  @Input()
  currentApp: App;
  jid: string;
  password: string;
  nickname: string;
  // ismin_window:Boolean=false;
  // ismax_window:Boolean=false;
  height_default_window = '230px';
  root = this.element.nativeElement.shadowRoot;

  constructor(private element: ElementRef, private _ngZone: NgZone, private loginService: LoginService) {
    this.jid = this.loginService.user.username + '@mycard.moe';
    this.password = this.loginService.user.external_id.toString();
    this.nickname = this.loginService.user.username;

  }

  ngOnInit() {
    console.log(this.root);

    this._ngZone.runOutsideAngular(() => {
      Zone.current.fork({
        name: 'candy'
      }).run(() => {
        CandyFix(this.element.nativeElement.shadowRoot, this.jid, this.password, this.nickname);
        Candy.init('wss://chat.mycard.moe:5280/websocket', {
          core: {
            autojoin: this.currentApp.conference && [this.currentApp.conference + '@conference.mycard.moe'],
            resource: 'mycard-' + crypto.randomBytes(4).toString('hex')
          },
          view: {
            assets: 'res/',
            language: 'cn',
            enableXHTML: true
          }
        });

        CandyShop.NotifyMe.init();
        CandyShop.NameComplete.init();
        CandyShop.ModifyRole.init();
        CandyShop.MeDoes.init();
        CandyShop.Notifications.init();
        CandyShop.Refocus.init();

        Candy.Core.connect(this.jid, this.password, this.nickname);
      });
    });

  }

  ngOnChanges(changes: SimpleChanges): void {
    if (!Candy.Core.getConnection()) {
      return;
    }
    let conference = changes['currentApp'].currentValue.conference;
    if (!conference) {
      return;
    }
    conference += '@conference.mycard.moe';

    try {
      if (Candy.View.Pane.Chat.rooms[conference]) {
        Candy.View.Pane.Room.show(conference);
      } else {
        Candy.Core.Action.Jabber.Room.Join(conference);
      }
    } catch (error) {

    }
  }

  minimize(): void {
    // let minimize:HTMLElement = $('#minimize')[0];
    // let maximized:HTMLElement = $('#maximized')[0];
    // let un_minimize:HTMLElement = $('#un_minimize')[0];
    // let un_maximized:HTMLElement = $('#un_maximized')[0];
    console.log(1)
    $('#candy', this.root).attr('data-minormax', 'min');
    document.getElementById('candy-wrapper')!.style.height = '31px';
    $('#mobile-roster-icon', this.root).css('display', 'none');
    $('#chat-toolbar', this.root).css('display', 'none');
    $('#chat-rooms', this.root).css('display', 'none');
    $('#context-menu', this.root).css('display', 'none');
    $('#mobile-roster-icon', this.root).css('display', 'none');

    $('#minimize', this.root).hide();
    $('#unminimize', this.root).show();
    $('#restore', this.root).hide();
    $('#maximize', this.root).show();
  }

  restore(): void {
    $('#candy', this.root).attr('data-minormax', 'default');
    document.getElementById('candy-wrapper')!.style!.height = this.height_default_window;
    $('#mobile-roster-icon', this.root).css('display', 'block');
    $('#chat-toolbar', this.root).css('display', 'block');
    $('#chat-rooms', this.root).css('display', 'block');
    $('#context-menu', this.root).css('display', 'block');
    $('#mobile-roster-icon', this.root).css('display', 'block');

    $('#minimize', this.root).show();
    $('#unminimize', this.root).hide();
    $('#restore', this.root).hide();
    $('#maximize', this.root).show();
  }

  maximize(): void {
    $('#candy', this.root).attr('data-minormax', 'max');
    document.getElementById('candy-wrapper')!.style!.height = 'calc( 100% - 180px )';
    $('#mobile-roster-icon', this.root).css('display', 'block');
    $('#chat-toolbar', this.root).css('display', 'block');
    $('#chat-rooms', this.root).css('display', 'block');
    $('#context-menu', this.root).css('display', 'block');
    $('#mobile-roster-icon', this.root).css('display', 'block');

    $('#minimize', this.root).show();
    $('#unminimize', this.root).hide();
    $('#restore', this.root).show();
    $('#maximize', this.root).hide();
  }

}
