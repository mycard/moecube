import * as Candy from 'candy';
import * as MeDoes from 'candy-shop/me-does/candy.js';
import * as ModifyRole from 'candy-shop/modify-role/candy.js';
import * as NameComplete from 'candy-shop/namecomplete/candy.js';
import * as Notifications from 'candy-shop/notifications/candy.js';
import * as NotifyMe from 'candy-shop/notifyme/candy.js';
import * as Refocus from 'candy-shop/refocus/candy.js';
import {Base64, Mustache} from 'candy/libs.bundle.js';
import * as jQuery from 'jquery';

declare const Zone;
// import 'zone.js';

declare const requestIdleCallback: Function;
const $: any = jQuery;
let shadow: ShadowRoot;

export {Candy};
export const CandyShop = {MeDoes, ModifyRole, NameComplete, Notifications, NotifyMe, Refocus};

export function CandyFix(element: ShadowRoot, jid: string, password: string, nickname: string) {
  shadow = element;
  Candy.View.Template.Login.form = `
    <form method="post" id="login-form" class="login-form">
        <input type="hidden" id="nickname" name="nickname" value="${nickname}"/>
        {{#displayUsername}}
            <input type="hidden" id="username" name="username" value="${jid}"/>
            {{#displayDomain}}
                <span class="at-symbol">@</span>
                <select id="domain" name="domain">{{#domains}}<option value="{{domain}}">{{domain}}</option>{{/domains}}</select>
            {{/displayDomain}}
        {{/displayUsername}}
        {{#presetJid}}<input type="hidden" id="username" name="username" value="{{presetJid}}"/>{{/presetJid}}
        {{#displayPassword}}<input type="hidden" id="password" name="password" value="${password}"/>{{/displayPassword}}
        <input type="submit" class="button" value="{{_loginSubmit}}" />
    </form>`;
}

Base64.encode = (data: string) => Buffer.from(data).toString('base64');
Base64.decode = (data: string) => Buffer.from(data, 'base64').toString();

$.fn.init = new Proxy($.fn.init, {
  construct(target, argumentsList, newTarget) {
    // tslint:disable-next-line
    let [selector, context, root] = argumentsList;
    if (Zone.current.name === 'candy') {
      if (selector === 'body') {
        selector = shadow;
      } else if (selector === document) {
        selector = shadow.getElementById('candy');
      } else if (!context) {
        context = shadow;
      }
    }
    return new target(selector, context, root);
  }
});

$.contains = new Proxy(jQuery.contains, {
  apply(target, thisArg, argumentsList) {
    // tslint:disable-next-line
    let [context, elem] = argumentsList;
    if (Zone.current.name === 'candy') {
      if (context === document) {
        context = shadow;
      }
    }
    return target.call(thisArg, context, elem);
  }
});

Candy.Util.getPosLeftAccordingToWindowBounds = new Proxy(Candy.Util.getPosLeftAccordingToWindowBounds, {
  apply(target, thisArg, argumentsList) {
    argumentsList[1] -= this.element.nativeElement.shadowRoot.host.getBoundingClientRect().left;
    return target.apply(thisArg, argumentsList);
  }
});
Candy.Util.getPosTopAccordingToWindowBounds = new Proxy(Candy.Util.getPosTopAccordingToWindowBounds, {
  apply(target, thisArg, argumentsList) {
    argumentsList[1] -= this.element.nativeElement.shadowRoot.host.getBoundingClientRect().top;
    return target.apply(thisArg, argumentsList);
  }
});

// 性能优化：禁用加入动画
Candy.View.Pane.Roster.joinAnimation = function () {
};

// 性能优化：禁用用户排序
Candy.View.Pane.Roster._insertUser = function (roomJid: string, roomId: string, user: any, userId: string, currentUser: any) {
  const contact = user.getContact();
  const html = Mustache.to_html(Candy.View.Template.Roster.user, {
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
  const rosterPane = Candy.View.Pane.Room.getPane(roomJid, '.roster-pane');
  rosterPane.append(html);
};

// 性能优化：将未读消息计数的的 jQuery show() 改为直接置 style
Candy.View.Pane.Chat.increaseUnreadMessages = function (roomJid: string) {
  const unreadElem = this.getTab(roomJid).find('.unread');
  unreadElem.text(unreadElem.text() !== '' ? parseInt(unreadElem.text(), 10) + 1 : 1);
  unreadElem[0].style.display = 'inherit';
  // only increase window unread messages in private chats
  if (Candy.View.Pane.Chat.rooms[roomJid].type === 'chat' || Candy.View.getOptions().updateWindowOnAllMessages === true) {
    Candy.View.Pane.Window.increaseUnreadMessages();
  }
};

// 性能优化：将收到消息时的滚动放进requestIdleCallback

Candy.View.Pane.Message.show = function (roomJid: any, name: any, message: any, xhtmlMessage: any, timestamp: any,
                                         from: any, carbon: any, stanza: any) {
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
  const messagePane = Candy.View.Pane.Room.getPane(roomJid, '.message-pane');
  let enableScroll;
  if (stanza && stanza.children('delay').length > 0) {
    enableScroll = true;
  } else {
    enableScroll =
      messagePane.scrollTop() + messagePane.outerHeight() === messagePane.prop('scrollHeight') || !$(messagePane).is(':visible');
  }
  Candy.View.Pane.Chat.rooms[roomJid].enableScroll = enableScroll;
  const evtData: any = {
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
  const renderEvtData = {
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
  const html = Mustache.to_html(renderEvtData.template, renderEvtData.templateData);
  Candy.View.Pane.Room.appendToMessagePane(roomJid, html);
  const elem = Candy.View.Pane.Room.getPane(roomJid, '.message-pane').children().last();
  // click on username opens private chat
  elem.find('a.label').click(function (event: any) {
    event.preventDefault();
    // Check if user is online and not myCandy.View.Pane
    const room = Candy.Core.getRoom(roomJid);
    if (room &&
      name !== Candy.View.Pane.Room.getUser(Candy.View.getCurrent().roomJid).getNick() &&
      room.getRoster().get(roomJid + '/' + name)) {
      if (Candy.View.Pane.PrivateRoom.open(roomJid + '/' + name, name, true) === false) {
        return false;
      }
    }
  });
  if (!carbon) {
    const notifyEvtData = {
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
