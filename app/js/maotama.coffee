path = require 'path'
crypto = require 'crypto'

gui = require 'nw.gui'

win = gui.Window.get();
win.showDevTools() if "--dev" in gui.App.argv

menu = new gui.Menu();
menu.append new gui.MenuItem
  label: '更换用户'
  click: ()->
    angular.element("#signin").scope().sign_out()
menu.append new gui.MenuItem
  label: '退出'
  click: ()->
    win.close()

window.tray = new gui.Tray
  title: '毛玉'
  tooltip: '毛玉'
  icon: 'app/img/logo.png'
  menu: menu

$('#window_control_minimize').click ->
  win.minimize()
$('#window_control_maximize').click ->
  win.maximize()
$('#window_control_unmaximize').click ->
  win.unmaximize()
$('#window_control_close').click ->
  win.close()
win.on 'maximize', ->
  $('#window_control_maximize').hide()
  $('#window_control_unmaximize').show()
win.on 'unmaximize', ->
  $('#window_control_maximize').show()
  $('#window_control_unmaximize').hide()

$('.switch').bootstrapSwitch();
$('#cloud_popover').popover()

$('#hide_candy').click ->
  $('body').removeClass('show_candy')
$('#show_candy').click ->
  $('body').addClass('show_candy')


$('body').on 'click', '#user_info', ->
  $('body').toggleClass('show_roster')

$('.main_wrapper').on 'click', '#cloud_address', ->
  $('#cloud_address').select();
$('.main_wrapper').on 'click','#app_add', ->
  chooser = $('#app_add_file');
  chooser.attr 'accept', "application/octet-stream"
  chooser.off('change')
  chooser.val(null)
  chooser.change (evt)->
    angular.element(this).scope().add(chooser.val())
  chooser.trigger('click');

win.on 'new-win-policy', (frame, url, policy)->
  gui.Shell.openExternal( url );
  policy.ignore()

$('body').on 'click', 'a[data-toggle="tab"]', (e)->
  e.preventDefault()
  $(this).tab('show')

#用户
pre_load_photo = (jid, name, domain)->
  switch domain
    when 'my-card.in'
      "http://my-card.in/users/#{name}.png"
    when 'public.talk.google.com'
      'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
    else
      hash = crypto.createHash('md5').update(jid).digest('hex')
      "http://en.gravatar.com/avatar/#{hash}?s=48&d=404"

#聊天
require("nw_node-xmpp-bosh").start_bosh
 host: "127.0.0.1"

window.addEventListener 'message', (event)->
  msg = event.data
  #console.log msg.stanza
  switch msg.type
    when 'vcard'
      stanza = $(msg.stanza)
      photo = stanza.find('photo')
      return if photo.length == 0
      from = stanza.attr('from');
      type = photo.find('type').text()
      binval = photo.find('binval').text()
      $(".xmpp[data-jid=\"#{from}\"] > .photo").attr('src', "data:#{type};base64,#{binval}")
    when 'roster'
      $('#roster').empty().append (for element in $(msg.stanza).find('query[xmlns="jabber:iq:roster"] > item')
        jid = element.getAttribute('jid')
        name = element.getAttribute('name') ? jid.split('@',2)[0]
        domain = jid.split('/')[0].split('@',2)[1]
        $('<li/>', class: 'xmpp', 'data-jid': jid, 'data-name': name, 'data-subcription': element.getAttribute('subcription'), 'data-presence-type': 'unavailable').append([
          $('<img/>', src: pre_load_photo(jid, name, domain), class: 'photo', onerror: "this.src='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='")
          $('<span/>', text: name)
        ]))
    when 'roster_set'
      $(msg.stanza).find('query[xmlns="jabber:iq:roster"] > item').each (index, element)->
        jid = element.getAttribute('jid')
        name = element.getAttribute('name') ? jid.split('@',2)[0]
        domain = jid.split('/')[0].split('@',2)[1]
        if $(".xmpp[data-jid=\"#{jid}\"]").length == 0
          $('#roster').prepend $('<li/>', class: 'xmpp', 'data-jid': jid, 'data-name': name, 'data-subcription': element.getAttribute('subcription'), 'data-presence-type': 'unavailable').append([
            $('<img/>', src: pre_load_photo(jid, name, domain), class: 'photo', onerror: "this.src='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='")
            $('<span/>', text: name)
          ])
        else
          $(".xmpp[data-jid=\"#{jid}\"]").replaceWith $('<li/>', class: 'xmpp', 'data-jid': jid, 'data-name': name, 'data-subcription': element.getAttribute('subcription'), 'data-presence-type': 'unavailable').append([
            $('<img/>', src: pre_load_photo(jid, name, domain), class: 'photo', onerror: "this.src='data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='")
            $('<span/>', text: name)
          ])


    when 'presence'
      stanza = $(msg.stanza)
      from = stanza.attr('from');
      type = stanza.attr('type')
      barefrom = from.split('/',2)[0];

      switch type
        when "subscribe"
          if $(".xmpp[data-jid=\"#{barefrom}\"]").length != 0 #自动同意已经在好友列表里的
            candy = $('#candy')[0]
            candy.contentWindow.postMessage type: 'subscribed', jid: barefrom, candy.src #同意好友申请
          else
            noty
              text: "#{barefrom} 想要将您添加为好友, 同意吗?"
              layout: 'topRight',
              buttons: [
                addClass: "btn btn-primary"
                text: "同意"
                onClick: ($noty) ->
                  candy = $('#candy')[0]
                  candy.contentWindow.postMessage type: 'subscribed', jid: barefrom, candy.src #同意好友申请
                  candy.contentWindow.postMessage type: 'subscribe', jid: barefrom, candy.src #添加对方为好友
                  $noty.close()
              ,
                addClass: "btn btn-danger"
                text: "拒绝"
                onClick: ($noty) ->
                  candy = $('#candy')[0]
                  candy.contentWindow.postMessage type: 'unsubscribed', jid: barefrom, candy.src
                  $noty.close()
              ]
        when "subscribed"
          window.LOCAL_NW.desktopNotifications.notify(null,null,null,"#{barefrom} 不再是您的好友了.");
        when "unsubscribed"
          window.LOCAL_NW.desktopNotifications.notify(null,null,null,"#{barefrom} 同意了您的添加好友请求.");
        else
          photo_hash = stanza.find('x[xmlns="vcard-temp:x:update"] photo').text()
          if photo_hash?
            candy = $('#candy')[0]
            candy.contentWindow.postMessage type: 'vcard', jid: barefrom, candy.src

          pres = type or "available"
          show = stanza.find("show")[0]
          pres = show.textContent  if show
          status = stanza.find("status")[0]
          pres += ":" + status.textContent  if status
          #roster.add new Candy.Core.ChatUser(barefrom, pres)
          $(".xmpp[data-jid=\"#{barefrom}\"]").attr('data-presence-type', type or 'available')
#main
