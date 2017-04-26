import { Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewEncapsulation } from '@angular/core';
import 'node_modules/candy/libs.min.js';
import 'node_modules/candy/candy.min.js';
import 'node_modules/candy-shop/me-does/candy.js';
import 'node_modules/candy-shop/modify-role/candy.js';
import 'node_modules/candy-shop/namecomplete/candy.js';
import 'node_modules/candy-shop/notifications/candy.js';
import 'node_modules/candy-shop/notifyme/candy.js';
import 'node_modules/candy-shop/refocus/candy.js';
import * as uuid from 'uuid';
import { Cube } from '../cube';
import { LoginService } from '../login.service';
import { SettingsService } from '../settings.sevices';
// import * as jqueryShadow from '../../jquery-shadow.js';
// import 'electron-cookies';
/**
 * Created by zh99998 on 16/9/2.
 */

let shadow: ShadowRoot;

const $ = require('../../jquery-shadow.js');
$.fn.init = new Proxy($.fn.init, {
  construct(target, argumentsList, newTarget) {
    let [selector, context, root] = argumentsList;
    if (shadow) {
      if (selector === 'body') {
        selector = shadow;
      } else if (selector === document) {
        selector = $('#candy');
      } else if (!context) {
        context = shadow;
      }
    }
    return new target(selector, context, root);
  }
});

window['jQuery'] = $;

delete window['jQuery'];

// Candy fix

declare const Candy: any, CandyShop: any, Base64: any;

Base64.encode = (data: string) => Buffer.from(data).toString('base64');
Base64.decode = (data: string) => Buffer.from(data, 'base64').toString();

Candy.Util.getPosLeftAccordingToWindowBounds = new Proxy(Candy.Util.getPosLeftAccordingToWindowBounds, {
  apply(target, thisArg, argumentsList) {
    argumentsList[1] -= shadow.host.getBoundingClientRect().left;
    return target.apply(thisArg, argumentsList);
  }
});
Candy.Util.getPosTopAccordingToWindowBounds = new Proxy(Candy.Util.getPosTopAccordingToWindowBounds, {
  apply(target, thisArg, argumentsList) {
    argumentsList[1] -= shadow.host.getBoundingClientRect().top;
    return target.apply(thisArg, argumentsList);
  }
});

// 性能优化：禁用加入动画
Candy.View.Pane.Roster.joinAnimation = function () {
};

// 性能优化：禁用用户排序
declare const Mustache: any;
Candy.View.Pane.Roster._insertUser = function (roomJid: string, roomId: string, user: any, userId: string, currentUser: any) {
  let contact = user.getContact();
  let html = Mustache.to_html(Candy.View.Template.Roster.user, {
    roomId: roomId,
    userId: userId,
    userJid: user.getJid(),
    realJid: user.getRealJid(),
    status: user.getStatus(),
    contact_status: contact ? contact.getStatus() : 'unavailable',
    nick: user.getNick(),
    displayNick: Candy.Util.crop(user.getNick(), Candy.View.getOptions().crop.roster.nickname),
    role: user.getRole(),
    affiliation: user.getAffiliation(),
    me: currentUser !== undefined && user.getNick() === currentUser.getNick(),
    tooltipRole: $.i18n._('tooltipRole'),
    tooltipIgnored: $.i18n._('tooltipIgnored')
  });
  let rosterPane = Candy.View.Pane.Room.getPane(roomJid, '.roster-pane');
  rosterPane.append(html);
};

// 性能优化：将未读消息计数的的 jQuery show() 改为直接置 style
Candy.View.Pane.Chat.increaseUnreadMessages = function (roomJid: string) {
  let unreadElem = this.getTab(roomJid).find('.unread');
  unreadElem.text(unreadElem.text() !== '' ? parseInt(unreadElem.text(), 10) + 1 : 1);
  unreadElem[0].style.display = 'inherit';
  // only increase window unread messages in private chats
  if (Candy.View.Pane.Chat.rooms[roomJid].type === 'chat' || Candy.View.getOptions().updateWindowOnAllMessages === true) {
    Candy.View.Pane.Window.increaseUnreadMessages();
  }
};

// 性能优化：将收到消息时的滚动放进requestIdleCallback
declare const requestIdleCallback: Function;
Candy.View.Pane.Message.show = function (roomJid: any, name: any, message: any, xhtmlMessage: any,
                                         timestamp: any, from: any, carbon: any, stanza: any) {
  message = Candy.Util.Parser.all(message.substring(0, Candy.View.getOptions().crop.message.body));
  if (Candy.View.getOptions().enableXHTML === true && xhtmlMessage) {
    xhtmlMessage = Candy.Util.parseAndCropXhtml(xhtmlMessage, Candy.View.getOptions().crop.message.body);
  }
  timestamp = timestamp || new Date();
  // Assume we have an ISO-8601 date string and convert it to a Date object
  if (!timestamp.toDateString) {
    timestamp = Candy.Util.iso8601toDate(timestamp);
  }
  // Before we add the new message, check to see if we should be automatically scrolling or not.
  let messagePane = Candy.View.Pane.Room.getPane(roomJid, '.message-pane');
  let enableScroll;
  if (stanza && stanza.children('delay').length > 0) {
    enableScroll = true;
  } else {
    enableScroll =
      messagePane.scrollTop() + messagePane.outerHeight() === messagePane.prop('scrollHeight') || !$(messagePane).is(':visible');
  }
  Candy.View.Pane.Chat.rooms[roomJid].enableScroll = enableScroll;
  let evtData: any = {
    roomJid: roomJid,
    name: name,
    message: message,
    xhtmlMessage: xhtmlMessage,
    from: from,
    stanza: stanza
  };
  if ($(Candy).triggerHandler('candy:view.message.before-show', evtData) === false) {
    return;
  }
  message = evtData.message;
  xhtmlMessage = evtData.xhtmlMessage;
  if (xhtmlMessage !== undefined && xhtmlMessage.length > 0) {
    message = xhtmlMessage;
  }
  if (!message) {
    return;
  }
  let renderEvtData = {
    template: Candy.View.Template.Message.item,
    templateData: {
      name: name,
      displayName: Candy.Util.crop(name, Candy.View.getOptions().crop.message.nickname),
      message: message,
      time: Candy.Util.localizedTime(timestamp),
      timestamp: timestamp.toISOString(),
      roomjid: roomJid,
      from: from
    },
    stanza: stanza
  };
  $(Candy).triggerHandler('candy:view.message.before-render', renderEvtData);
  let html = Mustache.to_html(renderEvtData.template, renderEvtData.templateData);
  Candy.View.Pane.Room.appendToMessagePane(roomJid, html);
  let elem = Candy.View.Pane.Room.getPane(roomJid, '.message-pane').children().last();
  // click on username opens private chat
  elem.find('a.label').click(function (event: any) {
    event.preventDefault();
    // Check if user is online and not myCandy.View.Pane
    let room = Candy.Core.getRoom(roomJid);
    if (room &&
      name !== Candy.View.Pane.Room.getUser(Candy.View.getCurrent().roomJid).getNick() &&
      room.getRoster().get(roomJid + '/' + name)) {
      if (Candy.View.Pane.PrivateRoom.open(roomJid + '/' + name, name, true) === false) {
        return false;
      }
    }
  });
  if (!carbon) {
    let notifyEvtData = {
      name: name,
      displayName: Candy.Util.crop(name, Candy.View.getOptions().crop.message.nickname),
      roomJid: roomJid,
      message: message,
      time: Candy.Util.localizedTime(timestamp),
      timestamp: timestamp.toISOString()
    };
    $(Candy).triggerHandler('candy:view.message.notify', notifyEvtData);
    // Check to see if in-core notifications are disabled
    if (!Candy.Core.getOptions().disableCoreNotifications) {
      if (Candy.View.getCurrent().roomJid !== roomJid || !Candy.View.Pane.Window.hasFocus()) {
        Candy.View.Pane.Chat.increaseUnreadMessages(roomJid);
        if (!Candy.View.Pane.Window.hasFocus()) {
          // Notify the user about a new private message OR on all messages if configured
          if (Candy.View.Pane.Chat.rooms[roomJid].type === 'chat' || Candy.View.getOptions().updateWindowOnAllMessages === true) {
            Candy.View.Pane.Chat.Toolbar.playSound();
          }
        }
      }
    }
    if (Candy.View.getCurrent().roomJid === roomJid) {
      requestIdleCallback(function () {
        Candy.View.Pane.Room.scrollToBottom(roomJid);
      });
    }
  }
  evtData.element = elem;
  $(Candy).triggerHandler('candy:view.message.after-show', evtData);
};

document['__defineGetter__']('cookie', () => 'candy-nostatusmessages');
document['__defineSetter__']('cookie', () => true);

declare const Strophe: any;
declare const $iq: any;

@Component({
  selector: 'candy',
  templateUrl: './candy.component.html',
  styleUrls: ['./candy.component.css'],
  encapsulation: ViewEncapsulation.Native
})
export class CandyComponent implements OnInit, OnChanges {
  @Input()
  currentCube: Cube;
  jid: string;
  password: string;
  nickname: string;
  // ismin_window:Boolean=false;
  // ismax_window:Boolean=false;
  height_default_window = '230px';

  constructor(private loginService: LoginService, private settingsService: SettingsService, private element: ElementRef) {
  }

  ngOnInit() {

    this.jid = this.loginService.user.username + '@mycard.moe';
    this.password = this.loginService.user.external_id.toString();
    this.nickname = this.loginService.user.username;

    shadow = this.element.nativeElement.shadowRoot;

    // 很 Tricky 的加载 Candy 的 css，这里涉及图片等资源的相对路径引用问题，如果丢给 Angular 去加载，会让相对路径找不到
    const element = document.createElement('style');
    element.innerHTML = `
            @import "node_modules/font-awesome/css/font-awesome.min.css";
            @import "node_modules/candy/libs.min.css";
            @import "node_modules/candy/res/default.css";
            @import "node_modules/candy-shop/notifyme/candy.css";
            @import "node_modules/candy-shop/namecomplete/candy.css";
            @import "node_modules/candy-shop/modify-role/candy.css";
        `;
    shadow.insertBefore(element, shadow.firstChild);

    Candy.View.Template.Login.form = `
            <form method="post" id="login-form" class="login-form">
                <input type="hidden" id="nickname" name="nickname" value="${this.nickname}"/>
                {{#displayUsername}}
                    <input type="hidden" id="username" name="username" value="${this.jid}"/>
                    {{#displayDomain}}
                        <span class="at-symbol">@</span>
                        <select id="domain" name="domain">{{#domains}}<option value="{{domain}}">{{domain}}</option>{{/domains}}</select>
                    {{/displayDomain}}
                {{/displayUsername}}
                {{#presetJid}}<input type="hidden" id="username" name="username" value="{{presetJid}}"/>{{/presetJid}}
                {{#displayPassword}}<input type="hidden" id="password" name="password" value="${this.password}"/>{{/displayPassword}}
                <input type="submit" class="button" value="{{_loginSubmit}}" />
            </form>
            `;

    Candy.Util.setCookie('candy-nostatusmessages', '1', 365);

    Candy.init('wss://chat.moecube.com:5280/websocket', {
      core: {
        debug: false,
        autojoin: this.currentCube.conference && [this.currentCube.conference + '@conference.mycard.moe'],
        resource: uuid.v1()
      },
      view: {
        assets: 'node_modules/candy/res/',
        language: this.settingsService.getLocale().startsWith('zh') ? 'cn' : 'en',
        enableXHTML: true,
      }
    });

    CandyShop.NotifyMe.init();
    CandyShop.NameComplete.init();
    CandyShop.ModifyRole.init();
    CandyShop.MeDoes.init();
    CandyShop.Notifications.init();
    CandyShop.Refocus.init();

    Candy.Core.connect(this.jid, this.password, this.nickname);

    // $(Candy).on('candy:core:roster:loaded', (event: JQueryEventObject, data: any) => {
    //     this.roster = Object.values(data.roster.getAll());
    // });
    // $(Candy).on('candy:core:roster:fetched', (event: JQueryEventObject, data: any) => {
    //     this.roster = Object.values(data.roster.getAll());
    // });
    // $(Candy).on('candy:core:roster:removed', (event: JQueryEventObject, data: any) => {
    //     this.roster = Object.values(Candy.Core.getRoster().getAll());
    // });
    // $(Candy).on('candy:core:roster:added', (event: JQueryEventObject, data: any) => {
    //     this.roster = Object.values(Candy.Core.getRoster().getAll());
    // });
    // $(Candy).on('candy:core:roster:updated', (event: JQueryEventObject, data: any) => {
    //     this.roster = Object.values(Candy.Core.getRoster().getAll());
    // });
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (!Candy.Core.getConnection()) {
      return;
    }
    let conference = changes['currentCube'].currentValue.conference;
    if (!conference) {
      return;
    }
    conference += '@conference.moecube.com';

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
    $('#candy').attr('data-minormax', 'min');
    document.getElementById('candy-wrapper')!.style.height = '31px';
    $('#mobile-roster-icon').css('display', 'none');
    $('#chat-toolbar').css('display', 'none');
    $('#chat-rooms').css('display', 'none');
    $('#context-menu').css('display', 'none');
    $('#mobile-roster-icon').css('display', 'none');

    $('#minimize').hide();
    $('#unminimize').show();
    $('#restore').hide();
    $('#maximize').show();
  }

  restore(): void {
    $('#candy').attr('data-minormax', 'default');
    document.getElementById('candy-wrapper')!.style!.height = this.height_default_window;
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

  maximize(): void {
    $('#candy').attr('data-minormax', 'max');
    document.getElementById('candy-wrapper')!.style!.height = 'calc( 100% - 180px )';
    $('#mobile-roster-icon').css('display', 'block');
    $('#chat-toolbar').css('display', 'block');
    $('#chat-rooms').css('display', 'block');
    $('#context-menu').css('display', 'block');
    $('#mobile-roster-icon').css('display', 'block');

    $('#minimize').show();
    $('#unminimize').hide();
    $('#restore').show();
    $('#maximize').hide();
  }

}






