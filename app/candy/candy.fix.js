(function (self, $) {
    //取消按昵称排序
    Candy.View.Pane.Roster.update = function(roomJid, user, action, currentUser) {
        Candy.Core.log("[View:Pane:Roster] " + action);
        var roomId = self.Chat.rooms[roomJid].id, userId = Candy.Util.jidToId(user.getJid()), usercountDiff = -1, userElem = $("#user-" + roomId + "-" + userId);
        /** Event: candy:view.roster.before-update
         * Before updating the roster of a room
         *
         * Parameters:
         *   (String) roomJid - Room JID
         *   (Candy.Core.ChatUser) user - User
         *   (String) action - [join, leave, kick, ban]
         *   (jQuery.Element) element - User element
         */
        $(Candy).triggerHandler("candy:view.roster.before-update", {
            roomJid: roomJid,
            user: user,
            action: action,
            element: userElem
        });
        // a user joined the room
        if (action === "join") {
            usercountDiff = 1;
            var html = Mustache.to_html(Candy.View.Template.Roster.user, {
                roomId: roomId,
                userId: userId,
                userJid: user.getJid(),
                nick: user.getNick(),
                displayNick: Candy.Util.crop(user.getNick(), Candy.View.getOptions().crop.roster.nickname),
                role: user.getRole(),
                affiliation: user.getAffiliation(),
                me: currentUser !== undefined && user.getNick() === currentUser.getNick(),
                tooltipRole: $.i18n._("tooltipRole"),
                tooltipIgnored: $.i18n._("tooltipIgnored")
            });
            if (userElem.length < 1) {
                var userInserted = false, rosterPane = self.Room.getPane(roomJid, ".roster-pane");
                // there are already users in the roster
                /*if (rosterPane.children().length > 0) {
                    // insert alphabetically
                    var userSortCompare = user.getNick().toUpperCase();
                    rosterPane.children().each(function() {
                        var elem = $(this);
                        if (elem.attr("data-nick").toUpperCase() > userSortCompare) {
                            elem.before(html);
                            userInserted = true;
                            return false;
                        }
                        return true;
                    });
                }*/
                // first user in roster
                if (!userInserted) {
                    rosterPane.append(html);
                }
                self.Roster.showJoinAnimation(user, userId, roomId, roomJid, currentUser);
            } else {
                usercountDiff = 0;
                userElem.replaceWith(html);
                $("#user-" + roomId + "-" + userId).css({
                    opacity: 1
                }).show();
                // it's me, update the toolbar
                if (currentUser !== undefined && user.getNick() === currentUser.getNick() && self.Room.getUser(roomJid)) {
                    self.Chat.Toolbar.update(roomJid);
                }
            }
            // Presence of client
            if (currentUser !== undefined && currentUser.getNick() === user.getNick()) {
                self.Room.setUser(roomJid, user);
            } else {
                $("#user-" + roomId + "-" + userId).click(self.Roster.userClick);
            }
            $("#user-" + roomId + "-" + userId + " .context").click(function(e) {
                self.Chat.Context.show(e.currentTarget, roomJid, user);
                e.stopPropagation();
            });
            // check if current user is ignoring the user who has joined.
            if (currentUser !== undefined && currentUser.isInPrivacyList("ignore", user.getJid())) {
                Candy.View.Pane.Room.addIgnoreIcon(roomJid, user.getJid());
            }
        } else if (action === "leave") {
            self.Roster.leaveAnimation("user-" + roomId + "-" + userId);
            // always show leave message in private room, even if status messages have been disabled
            if (self.Chat.rooms[roomJid].type === "chat") {
                self.Chat.onInfoMessage(roomJid, $.i18n._("userLeftRoom", [ user.getNick() ]));
            } else {
                self.Chat.infoMessage(roomJid, $.i18n._("userLeftRoom", [ user.getNick() ]));
            }
        } else if (action === "nickchange") {
            usercountDiff = 0;
            self.Roster.changeNick(roomId, user);
            self.Room.changeDataUserJidIfUserIsMe(roomId, user);
            self.PrivateRoom.changeNick(roomJid, user);
            var infoMessage = $.i18n._("userChangedNick", [ user.getPreviousNick(), user.getNick() ]);
            self.Chat.onInfoMessage(roomJid, infoMessage);
        } else if (action === "kick") {
            self.Roster.leaveAnimation("user-" + roomId + "-" + userId);
            self.Chat.onInfoMessage(roomJid, $.i18n._("userHasBeenKickedFromRoom", [ user.getNick() ]));
        } else if (action === "ban") {
            self.Roster.leaveAnimation("user-" + roomId + "-" + userId);
            self.Chat.onInfoMessage(roomJid, $.i18n._("userHasBeenBannedFromRoom", [ user.getNick() ]));
        }
        // Update user count
        Candy.View.Pane.Chat.rooms[roomJid].usercount += usercountDiff;
        if (roomJid === Candy.View.getCurrent().roomJid) {
            Candy.View.Pane.Chat.Toolbar.updateUsercount(Candy.View.Pane.Chat.rooms[roomJid].usercount);
        }
        /** Event: candy:view.roster.after-update
         * After updating a room's roster
         *
         * Parameters:
         *   (String) roomJid - Room JID
         *   (Candy.Core.ChatUser) user - User
         *   (String) action - [join, leave, kick, ban]
         *   (jQuery.Element) element - User element
         */
        $(Candy).triggerHandler("candy:view.roster.after-update", {
            roomJid: roomJid,
            user: user,
            action: action,
            element: $("#user-" + roomId + "-" + userId)
        });
    }


    //取消加入动画
    self.Roster.joinAnimation = function (elementId) {
        $('#' + elementId).show().css({opacity: 1})
    }

    //声音改为wav格式
    self.Chat.Toolbar.onPlaySound = function() {
        try {
            if (self.Chat.Toolbar._supportsNativeAudio) {
                new Audio(Candy.View.getOptions().resources + "notify.wav").play();
            } else {
                var chatSoundPlayer = document.getElementById("chat-sound-player");
                chatSoundPlayer.SetVariable("method:stop", "");
                chatSoundPlayer.SetVariable("method:play", "");
            }
        } catch (e) {}
    }
})(Candy.View.Pane, jQuery);

(function (self, $) {
    //修正同一个用户不同resource对话
    self.Message = function(event, args) {
        if (args.message.type === "subject") {
            if (!Candy.View.Pane.Chat.rooms[args.roomJid]) {
                Candy.View.Pane.Room.init(args.roomJid, args.message.name);
                Candy.View.Pane.Room.show(args.roomJid);
            }
            Candy.View.Pane.Room.setSubject(args.roomJid, args.message.body);
        } else if (args.message.type === "info") {
            Candy.View.Pane.Chat.infoMessage(args.roomJid, args.message.body);
        } else {
            // Initialize room if it's a message for a new private user chat
            if (args.message.type === "chat" && !Candy.View.Pane.Chat.rooms[args.roomJid]) {
                args.roomJid = Strophe.getBareJidFromJid(args.roomJid);
                Candy.View.Pane.PrivateRoom.open(args.roomJid, args.message.name, false, args.message.isNoConferenceRoomJid);
            }
            Candy.View.Pane.Message.show(args.roomJid, args.message.name, args.message.body, args.timestamp);
        }
    };
})(Candy.View.Observer, jQuery);


(function (self, Strophe, $) {
    //将candy:core.chat.connection的触发提前，用于在获取vcard之前获取roster
    self.Strophe.Connect = function(status) {
        Candy.Core.setStropheStatus(status);
        /** Event: candy:core.chat.connection
         * Connection status updates
         *
         * Parameters:
         *   (Strophe.Status) status - Strophe status
         */
        $(Candy).triggerHandler("candy:core.chat.connection", {
            status: status
        });
        switch (status) {
            case Strophe.Status.CONNECTED:
                Candy.Core.log("[Connection] Connected");
                Candy.Core.Action.Jabber.GetJidIfAnonymous();

            /* falls through */
            case Strophe.Status.ATTACHED:
                Candy.Core.log("[Connection] Attached");
                Candy.Core.Action.Jabber.Presence();
                Candy.Core.Action.Jabber.Autojoin();
                Candy.Core.Action.Jabber.GetIgnoreList();
                break;

            case Strophe.Status.DISCONNECTED:
                Candy.Core.log("[Connection] Disconnected");
                break;

            case Strophe.Status.AUTHFAIL:
                Candy.Core.log("[Connection] Authentication failed");
                break;

            case Strophe.Status.CONNECTING:
                Candy.Core.log("[Connection] Connecting");
                break;

            case Strophe.Status.DISCONNECTING:
                Candy.Core.log("[Connection] Disconnecting");
                break;

            case Strophe.Status.AUTHENTICATING:
                Candy.Core.log("[Connection] Authenticating");
                break;

            case Strophe.Status.ERROR:
            case Strophe.Status.CONNFAIL:
                Candy.Core.log("[Connection] Failed (" + status + ")");
                break;

            default:
                Candy.Core.log("[Connection] What?!");
                break;
        }
    }
})(Candy.Core.Event || {}, Strophe, jQuery);

//父窗口焦點
Candy.View = function(self, $) {
    /** PrivateObject: _current
     * Object containing current container & roomJid which the client sees.
     */
    var _current = {
        container: null,
        roomJid: null
    }, /** PrivateObject: _options
     *
     * Options:
     *   (String) language - language to use
     *   (String) resources - path to resources directory (with trailing slash)
     *   (Object) messages - limit: clean up message pane when n is reached / remove: remove n messages after limit has been reached
     *   (Object) crop - crop if longer than defined: message.nickname=15, message.body=1000, roster.nickname=15
     */
        _options = {
        language: "en",
        resources: "res/",
        messages: {
            limit: 2e3,
            remove: 500
        },
        crop: {
            message: {
                nickname: 15,
                body: 1e3
            },
            roster: {
                nickname: 15
            }
        }
    }, /** PrivateFunction: _setupTranslation
     * Set dictionary using jQuery.i18n plugin.
     *
     * See: view/translation.js
     * See: libs/jquery-i18n/jquery.i18n.js
     *
     * Parameters:
     *   (String) language - Language identifier
     */
        _setupTranslation = function(language) {
        $.i18n.load(self.Translation[language]);
    }, /** PrivateFunction: _registerObservers
     * Register observers. Candy core will now notify the View on changes.
     */
        _registerObservers = function() {
        $(Candy).on("candy:core.chat.connection", self.Observer.Chat.Connection);
        $(Candy).on("candy:core.chat.message", self.Observer.Chat.Message);
        $(Candy).on("candy:core.login", self.Observer.Login);
        $(Candy).on("candy:core.autojoin-missing", self.Observer.AutojoinMissing);
        $(Candy).on("candy:core.presence", self.Observer.Presence.update);
        $(Candy).on("candy:core.presence.leave", self.Observer.Presence.update);
        $(Candy).on("candy:core.presence.room", self.Observer.Presence.update);
        $(Candy).on("candy:core.presence.error", self.Observer.PresenceError);
        $(Candy).on("candy:core.message", self.Observer.Message);
    }, /** PrivateFunction: _registerWindowHandlers
     * Register window focus / blur / resize handlers.
     *
     * jQuery.focus()/.blur() <= 1.5.1 do not work for IE < 9. Fortunately onfocusin/onfocusout will work for them.
     */
        _registerWindowHandlers = function() {
        if (Candy.Util.getIeVersion() < 9) {
            $(document).focusin(Candy.View.Pane.Window.onFocus).focusout(Candy.View.Pane.Window.onBlur);
        } else {
            $(window).focus(Candy.View.Pane.Window.onFocus).blur(Candy.View.Pane.Window.onBlur);
            $(parent).focus(Candy.View.Pane.Window.onFocus).blur(Candy.View.Pane.Window.onBlur);
        }
        $(window).resize(Candy.View.Pane.Chat.fitTabs);
    }, /** PrivateFunction: _initToolbar
     * Initialize toolbar.
     */
        _initToolbar = function() {
        self.Pane.Chat.Toolbar.init();
    }, /** PrivateFunction: _delegateTooltips
     * Delegate mouseenter on tooltipified element to <Candy.View.Pane.Chat.Tooltip.show>.
     */
        _delegateTooltips = function() {
        $("body").delegate("li[data-tooltip]", "mouseenter", Candy.View.Pane.Chat.Tooltip.show);
    };
    /** Function: init
     * Initialize chat view (setup DOM, register handlers & observers)
     *
     * Parameters:
     *   (jQuery.element) container - Container element of the whole chat view
     *   (Object) options - Options: see _options field (value passed here gets extended by the default value in _options field)
     */
    self.init = function(container, options) {
        $.extend(true, _options, options);
        _setupTranslation(_options.language);
        // Set path to emoticons
        Candy.Util.Parser.setEmoticonPath(this.getOptions().resources + "img/emoticons/");
        // Start DOMination...
        _current.container = container;
        _current.container.html(Mustache.to_html(Candy.View.Template.Chat.pane, {
            tooltipEmoticons: $.i18n._("tooltipEmoticons"),
            tooltipSound: $.i18n._("tooltipSound"),
            tooltipAutoscroll: $.i18n._("tooltipAutoscroll"),
            tooltipStatusmessage: $.i18n._("tooltipStatusmessage"),
            tooltipAdministration: $.i18n._("tooltipAdministration"),
            tooltipUsercount: $.i18n._("tooltipUsercount"),
            resourcesPath: this.getOptions().resources
        }, {
            tabs: Candy.View.Template.Chat.tabs,
            rooms: Candy.View.Template.Chat.rooms,
            modal: Candy.View.Template.Chat.modal,
            toolbar: Candy.View.Template.Chat.toolbar,
            soundcontrol: Candy.View.Template.Chat.soundcontrol
        }));
        // ... and let the elements dance.
        _registerWindowHandlers();
        _initToolbar();
        _registerObservers();
        _delegateTooltips();
    };
    /** Function: getCurrent
     * Get current container & roomJid in an object.
     *
     * Returns:
     *   Object containing container & roomJid
     */
    self.getCurrent = function() {
        return _current;
    };
    /** Function: getOptions
     * Gets options
     *
     * Returns:
     *   Object
     */
    self.getOptions = function() {
        return _options;
    };
    return self;
}(Candy.View || {}, jQuery);

//中文验证，看起来SHA1、MD5、PLAIN都对中文支持有问题。通过更换base64库可以修复PLAIN，然后在这里只允许PLAIN认证
Strophe.Connection.prototype._connect_cb = function(req, _callback, raw) {
    Strophe.info("_connect_cb was called");
    this.connected = true;
    var bodyWrap = this._proto._reqToData(req);
    if (!bodyWrap) {
        return;
    }
    if (this.xmlInput !== Strophe.Connection.prototype.xmlInput) {
        if (bodyWrap.nodeName === this._proto.strip && bodyWrap.childNodes.length) {
            this.xmlInput(bodyWrap.childNodes[0]);
        } else {
            this.xmlInput(bodyWrap);
        }
    }
    if (this.rawInput !== Strophe.Connection.prototype.rawInput) {
        if (raw) {
            this.rawInput(raw);
        } else {
            this.rawInput(Strophe.serialize(bodyWrap));
        }
    }
    var conncheck = this._proto._connect_cb(bodyWrap);
    if (conncheck === Strophe.Status.CONNFAIL) {
        return;
    }
    this._authentication.sasl_scram_sha1 = false;
    this._authentication.sasl_plain = false;
    this._authentication.sasl_digest_md5 = false;
    this._authentication.sasl_anonymous = false;
    this._authentication.legacy_auth = false;
    // Check for the stream:features tag
    var hasFeatures = bodyWrap.getElementsByTagName("stream:features").length > 0;
    if (!hasFeatures) {
        hasFeatures = bodyWrap.getElementsByTagName("features").length > 0;
    }
    var mechanisms = bodyWrap.getElementsByTagName("mechanism");
    var matched = [];
    var i, mech, auth_str, hashed_auth_str, found_authentication = false;
    if (!hasFeatures) {
        this._proto._no_auth_received(_callback);
        return;
    }
    if (mechanisms.length > 0) {
        for (i = 0; i < mechanisms.length; i++) {
            mech = Strophe.getText(mechanisms[i]);
            if(mech == 'SCRAM-SHA-1' || mech == 'DIGEST-MD5') continue
            if (this.mechanisms[mech]) matched.push(this.mechanisms[mech]);
        }
    }

    this._authentication.legacy_auth = bodyWrap.getElementsByTagName("auth").length > 0;
    found_authentication = this._authentication.legacy_auth || matched.length > 0;
    if (!found_authentication) {
        this._proto._no_auth_received(_callback);
        return;
    }
    if (this.do_authentication !== false) this.authenticate(matched);
}