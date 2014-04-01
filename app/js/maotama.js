// Generated by CoffeeScript 1.7.1
(function() {
  var crypto, gui, menu, path, pre_load_photo, win,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  path = require('path');

  crypto = require('crypto');

  gui = require('nw.gui');

  win = gui.Window.get();

  if (__indexOf.call(gui.App.argv, "--dev") >= 0) {
    win.showDevTools();
  }

  menu = new gui.Menu();

  menu.append(new gui.MenuItem({
    label: '更换用户',
    click: function() {
      return angular.element("#signin").scope().sign_out();
    }
  }));

  menu.append(new gui.MenuItem({
    label: '退出',
    click: function() {
      return win.close();
    }
  }));

  window.tray = new gui.Tray({
    title: '毛玉',
    tooltip: '毛玉',
    icon: 'app/img/logo.png',
    menu: menu
  });

  $('#window_control_minimize').click(function() {
    return win.minimize();
  });

  $('#window_control_maximize').click(function() {
    return win.maximize();
  });

  $('#window_control_unmaximize').click(function() {
    return win.unmaximize();
  });

  $('#window_control_close').click(function() {
    return win.close();
  });

  win.on('maximize', function() {
    $('#window_control_maximize').hide();
    return $('#window_control_unmaximize').show();
  });

  win.on('unmaximize', function() {
    $('#window_control_maximize').show();
    return $('#window_control_unmaximize').hide();
  });

  $('.switch').bootstrapSwitch();

  $('#cloud_popover').popover();

  $('#hide_candy').click(function() {
    return $('body').removeClass('show_candy');
  });

  $('#show_candy').click(function() {
    return $('body').addClass('show_candy');
  });

  $('body').on('click', '#user_info', function() {
    return $('body').toggleClass('show_roster');
  });

  $('.main_wrapper').on('click', '#cloud_address', function() {
    return $('#cloud_address').select();
  });

  $('.main_wrapper').on('click', '#app_add', function() {
    var chooser;
    chooser = $('#app_add_file');
    chooser.attr('accept', "application/octet-stream");
    chooser.off('change');
    chooser.val(null);
    chooser.change(function(evt) {
      return angular.element(this).scope().add(chooser.val());
    });
    return chooser.trigger('click');
  });

  win.on('new-win-policy', function(frame, url, policy) {
    gui.Shell.openExternal(url);
    return policy.ignore();
  });

  pre_load_photo = function(jid, name, domain) {
    var hash;
    switch (domain) {
      case 'my-card.in':
        return "http://my-card.in/users/" + name + ".png";
      case 'public.talk.google.com':
        return 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';
      default:
        hash = crypto.createHash('md5').update(jid).digest('hex');
        return "http://en.gravatar.com/avatar/" + hash + "?s=48&d=404";
    }
  };

  require("nw_node-xmpp-bosh").start_bosh({
    host: "127.0.0.1"
  });

  window.addEventListener('message', function(event) {
    var barefrom, binval, candy, domain, element, from, jid, msg, name, photo, photo_hash, pres, show, stanza, status, type;
    msg = event.data;
    switch (msg.type) {
      case 'vcard':
        stanza = $(msg.stanza);
        photo = stanza.find('photo');
        if (photo.length === 0) {
          return;
        }
        from = stanza.attr('from');
        type = photo.find('type').text();
        binval = photo.find('binval').text();
        return $(".xmpp[data-jid=\"" + from + "\"] > .photo").attr('src', "data:" + type + ";base64," + binval);
      case 'roster':
        return $('#roster').empty().append((function() {
          var _i, _len, _ref, _ref1, _results;
          _ref = $(msg.stanza).find('query[xmlns="jabber:iq:roster"] > item');
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            element = _ref[_i];
            jid = element.getAttribute('jid');
            name = (_ref1 = element.getAttribute('name')) != null ? _ref1 : jid.split('@', 2)[0];
            domain = jid.split('/')[0].split('@', 2)[1];
            _results.push($('<li/>', {
              "class": 'xmpp',
              'data-jid': jid,
              'data-name': name,
              'data-subcription': element.getAttribute('subcription'),
              'data-presence-type': 'unavailable'
            }).append([
              $('<img/>', {
                src: pre_load_photo(jid, name, domain),
                "class": 'photo',
                onerror: "this.src='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='"
              }), $('<span/>', {
                text: name
              })
            ]));
          }
          return _results;
        })());
      case 'roster_set':
        return $(msg.stanza).find('query[xmlns="jabber:iq:roster"] > item').each(function(index, element) {
          var _ref;
          jid = element.getAttribute('jid');
          name = (_ref = element.getAttribute('name')) != null ? _ref : jid.split('@', 2)[0];
          domain = jid.split('/')[0].split('@', 2)[1];
          if ($(".xmpp[data-jid=\"" + jid + "\"]").length === 0) {
            return $('#roster').prepend($('<li/>', {
              "class": 'xmpp',
              'data-jid': jid,
              'data-name': name,
              'data-subcription': element.getAttribute('subcription'),
              'data-presence-type': 'unavailable'
            }).append([
              $('<img/>', {
                src: pre_load_photo(jid, name, domain),
                "class": 'photo',
                onerror: "this.src='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='"
              }), $('<span/>', {
                text: name
              })
            ]));
          } else {
            return $(".xmpp[data-jid=\"" + jid + "\"]").replaceWith($('<li/>', {
              "class": 'xmpp',
              'data-jid': jid,
              'data-name': name,
              'data-subcription': element.getAttribute('subcription'),
              'data-presence-type': 'unavailable'
            }).append([
              $('<img/>', {
                src: pre_load_photo(jid, name, domain),
                "class": 'photo',
                onerror: "this.src='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='"
              }), $('<span/>', {
                text: name
              })
            ]));
          }
        });
      case 'presence':
        stanza = $(msg.stanza);
        from = stanza.attr('from');
        type = stanza.attr('type');
        barefrom = from.split('/', 2)[0];
        switch (type) {
          case "subscribe":
            if ($(".xmpp[data-jid=\"" + barefrom + "\"]").length !== 0) {
              candy = $('#candy')[0];
              return candy.contentWindow.postMessage({
                type: 'subscribed',
                jid: barefrom
              }, candy.src);
            } else {
              return noty({
                text: "" + barefrom + " 想要将您添加为好友, 同意吗?",
                layout: 'topRight',
                buttons: [
                  {
                    addClass: "btn btn-primary",
                    text: "同意",
                    onClick: function($noty) {
                      candy = $('#candy')[0];
                      candy.contentWindow.postMessage({
                        type: 'subscribed',
                        jid: barefrom
                      }, candy.src);
                      candy.contentWindow.postMessage({
                        type: 'subscribe',
                        jid: barefrom
                      }, candy.src);
                      return $noty.close();
                    }
                  }, {
                    addClass: "btn btn-danger",
                    text: "拒绝",
                    onClick: function($noty) {
                      candy = $('#candy')[0];
                      candy.contentWindow.postMessage({
                        type: 'unsubscribed',
                        jid: barefrom
                      }, candy.src);
                      return $noty.close();
                    }
                  }
                ]
              });
            }
            break;
          case "subscribed":
            return window.LOCAL_NW.desktopNotifications.notify(null, null, null, "" + barefrom + " 不再是您的好友了.");
          case "unsubscribed":
            return window.LOCAL_NW.desktopNotifications.notify(null, null, null, "" + barefrom + " 同意了您的添加好友请求.");
          default:
            photo_hash = stanza.find('x[xmlns="vcard-temp:x:update"] photo').text();
            if (photo_hash != null) {
              candy = $('#candy')[0];
              candy.contentWindow.postMessage({
                type: 'vcard',
                jid: barefrom
              }, candy.src);
            }
            pres = type || "available";
            show = stanza.find("show")[0];
            if (show) {
              pres = show.textContent;
            }
            status = stanza.find("status")[0];
            if (status) {
              pres += ":" + status.textContent;
            }
            return $(".xmpp[data-jid=\"" + barefrom + "\"]").attr('data-presence-type', type || 'available');
        }
    }
  });

}).call(this);

//# sourceMappingURL=maotama.map
