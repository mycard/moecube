#encoding: UTF-8
load 'lib/ygocore/window_login.rb'
require 'eventmachine'
require 'em-http'
require 'websocket'
require 'open-uri'
require 'yaml'
require 'json'
require 'date'
class Ygocore < Game
  attr_reader :username
  attr_accessor :password
  @@config = YAML.load_file("lib/ygocore/server.yml")

  def initialize
    super
    load 'lib/ygocore/event.rb'
    load 'lib/ygocore/user.rb'
    load 'lib/ygocore/room.rb'
    load 'lib/ygocore/scene_lobby.rb'
    require 'json'
    require 'xmpp4r/client'
    require 'xmpp4r/muc'
  end

  def refresh_interval
    60
  end

  def login(username, password)
    @username = username
    @password = password
    @nickname_conflict = []
    matched = @username.match Jabber::JID::PATTERN
    if matched[1] && matched[2]
      @username = matched[1]
      jid = Jabber::JID::new @username, matched[2], matched[3] || 'mycard'
    else
      jid = Jabber::JID::new @username, 'my-card.in', 'mycard'
    end
    Jabber::Client.module_eval do |klass|
      def start
        super
        send(generate_stream_start(@jid.domain, nil, nil, $config['i18n']['locale'])) { |e| e.name == 'stream' }
      end
    end

    @@im = Jabber::Client.new(jid)
    @@im_room = Jabber::MUC::MUCClient.new(@@im)

    @@im.on_exception do |exception, c, where|
      $log.error('聊天出错') { [exception, c, where] }
      Game_Event.push(Game_Event::Chat.new(ChatMessage.new(User.new(:system, 'System'), '聊天服务连接中断: ' + exception.to_s)))
    end
    @@im_room.add_message_callback do |m|
      if m.from.resource.nil? and m.subject
        Game_Event.push Game_Event::Chat.new ChatMessage.new(User.new(:subject, '主题'), m.subject, :lobby) rescue $log.error('收到聊天消息') { $! }
      end
      if m.from.resource and m.body
        user = m.from.resource == nickname ? @user : User.new(m.from.resource.to_sym, m.from.resource)
        Game_Event.push Game_Event::Chat.new ChatMessage.new(user, m.body, :lobby) rescue $log.error('收到聊天消息') { $! }
      end
    end
    @@im_room.add_private_message_callback do |m|
      if m.from.resource and m.body #忽略无消息的正在输入等内容
        user = m.from.resource == nickname ? @user : User.new(m.from.resource.to_sym, m.from.resource)
        Game_Event.push Game_Event::Chat.new ChatMessage.new(user, m.body, user) rescue $log.error('收到私聊消息') { $! }
      end
    end
    @@im_room.add_join_callback do |m|
      user = User.new m.from.resource.to_sym, m.from.resource
      user.affiliation = m.x('http://jabber.org/protocol/muc#user').first_element('item').affiliation rescue nil
      Game_Event.push Game_Event::NewUser.new user
    end
    @@im_room.add_leave_callback do |m|
      Game_Event.push Game_Event::MissingUser.new User.new m.from.resource.to_sym, m.from.resource
    end
    connect
    im_connect
  end

  def nickname
    return @nickname if @nickname
    if @nickname_conflict.include? @username
      1.upto(9) do |i|
        result = "#{@username}-#{i}"
        return result unless @nickname_conflict.include? result
      end
      raise 'can`t get available nickname'
    else
      @username
    end
  end

  def connect
    @recv = Thread.new do
      EventMachine::run {
        http = EM::HttpRequest.new("https://my-card.in/servers.json").get
        http.callback {
          begin
            self.servers.replace JSON.parse(http.response).collect { |data| Server.new(data['id'], data['name'], data['ip'], data['port'], data['auth']) }
            self.filter[:servers] = self.servers.clone
          rescue
            Game_Event.push Game_Event::Error.new('ygocore', '读取服务器列表失败.1', true)
          end

          ws = WebSocket::EventMachine::Client.connect(:uri => 'wss://my-card.in/rooms.json');
          ws.onmessage do |msg, type|
            Game_Event.push Game_Event::RoomsUpdate.new JSON.parse(msg).collect { |room| Game_Event.parse_room(room) }
          end
          ws.onclose do
            $log.info('websocket连接断开')
            Game_Event.push Game_Event::Error.new('ygocore', '网络连接中断.1', true)
          end

        }
        http.errback {
          Game_Event.push Game_Event::Error.new('ygocore', '读取服务器列表失败', true)
        }
      }
    end
  end

  def im_connect
    Thread.new {
      begin
        @@im.allow_tls = false
        @@im.use_ssl = true

        connected = false
        if @@im.jid.domain == "my-card.in"
          begin
            @@im.connect("chat.my-card.in", 5223)
            connected = true
          rescue
            Game_Event.push Game_Event::Error.new('登录', '连接服务器失败')
          end
        else
          srv = []
          Resolv::DNS.open { |dns|
            Jabber::debuglog("RESOLVING:\n_xmpp-client._tcp.#{@@im.jid.domain} (SRV)")
            srv = dns.getresources("_xmpp-client._tcp.#{@@im.jid.domain}", Resolv::DNS::Resource::IN::SRV)
          }

          if srv.empty?
            Game_Event.push Game_Event::Error.new('登录', '解析服务器地址失败')
          end
          # Sort SRV records: lowest priority first, highest weight first
          srv.sort! { |a, b| (a.priority != b.priority) ? (a.priority <=> b.priority) : (b.weight <=> a.weight) }

          srv.each { |record|
            begin
              @@im.connect(record.target.to_s, 5223)
              # Success
              connected = true
              break
            rescue
              # Try next SRV record
            end
          }
        end

        if connected
          begin
            @@im.fd.define_singleton_method(:external_encoding) { |*args| @@im.fd.io.external_encoding(*args) }
            @@im.auth(@password)
          rescue Jabber::ClientAuthenticationFailure
            Game_Event.push Game_Event::Error.new('登录', '用户名或密码错误')
            Thread.exit
          end
          @@im.send(Jabber::Presence.new.set_type(:available))
          Game_Event.push Game_Event::Login.new User.new(@@im.jid, @username, true)
          begin
            nickname = nickname()
            #@@im_room.join(Jabber::JID.new(I18n.t('lobby.room'), I18n.t('lobby.server'), nickname))
            @@im_room.join(Jabber::JID.new('mycard', 'conference.my-card.in', nickname))
          rescue Jabber::ServerError => exception
            Game_Event.push(Game_Event::Chat.new(ChatMessage.new(User.new(:system, 'System'), exception.message)))
            if exception.error.error == 'conflict'
              @nickname_conflict << nickname
              retry
            end
          end
        end
      rescue StandardError => exception
        $log.error('聊天连接出错') { exception }
        Game_Event.push Game_Event::Error.new('登录', '登录失败')
      end
    }
  end

  def chat(chatmessage)
    case chatmessage.channel
    when :lobby
      msg = Jabber::Message::new(nil, chatmessage.message)
      @@im_room.send msg
    when User
      msg = Jabber::Message::new(nil, chatmessage.message)
      @@im_room.send msg, chatmessage.channel.id
      #send(:chat, channel: chatmessage.channel.id, message: chatmessage.message, time: chatmessage.time)
    end
  end

  #def chat(chatmessage)
  #  case chatmessage.channel
  #  when :lobby
  #    send(:chat, channel: :lobby, message: chatmessage.message, time: chatmessage.time)
  #  when User
  #    send(:chat, channel: chatmessage.channel.id, message: chatmessage.message, time: chatmessage.time)
  #  end
  #end

  def host(room_name, room_config)
    room = Room.new(nil, room_name)
    room.pvp = room_config[:pvp]
    room.match = room_config[:match]
    room.tag = room_config[:tag]
    room.password = room_config[:password]
    room.ot = room_config[:ot]
    room.lp = room_config[:lp]

    room.host_server

    if $game.rooms.any? { |game_room| game_room.name == room_name }
      Widget_Msgbox.new("建立房间", "房间名已存在", :ok => "确定")
      false
    else
      Game_Event.push Game_Event::Join.new(room)
      room
    end
  end

  def watch(room)
    Widget_Msgbox.new("加入房间", "游戏已经开始", :ok => "确定")
  end

  def join(room)
    Game_Event.push Game_Event::Join.new(room)
  end

  def refresh
    #send(:refresh)
  end

  def send(header, data=nil)
    #$log.info('发送消息') { {header: header, data: data} }
    #Client::MycardChannel.push header: header, data: data
  end

  def exit
    @recv.exit if @recv
    @recv = nil
  end

  def self.ygocore_path
    Windows ? 'ygocore/ygopro_vs.exe' : 'ygocore/gframe'
  end

  def self.register
    Dialog.web @@config['register']
  end

  def server
    @@config['server']
  end

  def port
    @@config['port']
  end

  def server=(server)
    @@config['server'] = server
  end

  def port=(port)
    @@config['port'] = port
  end

  def self.write_system_conf(options)
    system_conf = {}
    begin
      IO.readlines(File.join(File.dirname(ygocore_path), 'system.conf')).each do |line|
        line.force_encoding "UTF-8"
        next if line[0, 1] == '#'
        field, contents = line.chomp.split(' = ', 2)
        system_conf[field] = contents
      end
    rescue
    end

    font, size = system_conf['textfont'].split(' ')
    if !File.file?(File.expand_path(font, File.dirname(ygocore_path))) or size.to_i.to_s != size
      require 'pathname'
      font_path = Pathname.new(Font)
      font_path = font_path.relative_path_from(Pathname.new(File.dirname(ygocore_path))) if font_path.relative?
      system_conf['textfont'] = "#{font_path} 14"
    end
    if !File.file?(system_conf['numfont'])
      system_conf['numfont'] = Windows ? 'c:/windows/fonts/arialbd.ttf' : '/usr/share/fonts/gnu-free/FreeSansBold.ttf'
    end
    options.each do |key, value|
      system_conf[key] = value
    end
    open(File.join(File.dirname(ygocore_path), 'system.conf'), 'w') { |file| file.write system_conf.collect { |key, value| "#{key} = #{value}" }.join("\n") }
  end

  def self.run_ygocore(option, image_downloading=false)
    Widget_Msgbox.new("ygocore", "正在启动ygocore") rescue nil
    #写入配置文件并运行ygocore
    case option
    when Room
      room = option
      room_name = if room.ot != 0 or room.lp != 8000
                    mode = case when room.match? then
                                  1; when room.tag? then
                                       2
                           else
                             0
                           end
                    room_name = "#{room.ot}#{mode}FFF#{room.lp},5,1,#{room.name}"
                  elsif room.tag?
                    "T#" + room.name
                  elsif room.pvp? and room.match?
                    "PM#" + room.name
                  elsif room.pvp?
                    "P#" + room.name
                  elsif room.match?
                    "M#" + room.name
                  else
                    room.name
                  end
      if room.password and !room.password.empty?
        room_name += "$" + room.password
      end
      options = {}
      if $game.user
        options['nickname'] = $game.user.name
        options['nickname'] += '$' + $game.password if $game.password and !$game.password.empty? and room.server.auth
      end
      options['lastip'] = room.server.ip
      options['lastport'] = room.server.port.to_s
      options['roompass'] = room_name if room_name and !room_name.empty?
      write_system_conf options
      args = '-j'
    when :replay
      args = '-r'
    when :deck
      args = '-d'
    when String
      File.rename(File.join(File.dirname(ygocore_path), 'deck', option + '.ydk'), File.join(File.dirname(ygocore_path), 'deck', option.gsub!(' ', '_') + '.ydk')) if option[' ']
      write_system_conf 'lastdeck' => option
      args = '-d'
    end
    spawn('./' + File.basename(ygocore_path), args, :chdir => File.dirname(ygocore_path))
    WM.iconify rescue nil
    Widget_Msgbox.destroy rescue nil
  end

  def self.replay(file, skip_image_downloading = false)
    require 'fileutils'
    FileUtils.mv Dir.glob('ygocore/replay/*.yrp'), 'replay/'
    FileUtils.copy_file(file, "ygocore/replay/#{File.basename(file)}")
    run_ygocore(:replay, skip_image_downloading)
  end

  private

  def self.get_announcements
    #公告
    $config['ygocore'] ||= {}
    $config['ygocore']['announcements'] ||= [Announcement.new("正在读取公告...", nil, nil)]
    Thread.new do
      begin
        open('https://my-card.in/announcements.json') do |file|
          $config['ygocore']['announcements'].replace JSON.parse(file.read).collect { |announcement|
            Announcement.new(announcement['title'], announcement['url'], Date.parse(announcement['created_at']))
          }
          Config.save
        end
      rescue Exception => exception
        $log.error('公告读取失败') { [exception.inspect, *exception.backtrace].collect { |str| str.force_encoding("UTF-8") }.join("\n") } if $log
      end
    end
  end

#module Client
#  MycardChannel = EM::Channel.new
#  include EM::P::ObjectProtocol
#
#  def post_init
#    send_object header: :login, data: {name: $game.username, password: $game.password}
#    MycardChannel.subscribe { |msg| send_object(msg) }
#  end
#
#  def receive_object obj
#    $log.info('收到消息') { obj.inspect }
#    Game_Event.push Game_Event.parse obj[:header], obj[:data]
#  end
#
#  def unbind
#    Game_Event.push Game_Event::Error.new('ygocore', '网络连接中断', true)
#  end
#end
  get_announcements
end


# websocket, due to the author hasn't release separate gem yet
#https://github.com/imanel/websocket-ruby/issues/12

module WebSocket
  module EventMachine
    class Base < ::EventMachine::Connection

      ###########
      ### API ###
      ###########

      def onopen(&blk)
        ; @onopen = blk;
      end

      # Called when connection is opened
      def onclose(&blk)
        ; @onclose = blk;
      end

      # Called when connection is closed
      def onerror(&blk)
        ; @onerror = blk;
      end

      # Called when error occurs
      def onmessage(&blk)
        ; @onmessage = blk;
      end

      # Called when message is received from server
      def onping(&blk)
        ; @onping = blk;
      end

      # Called when ping message is received from server
      def onpong(&blk)
        ; @onpong = blk;
      end

      # Called when pond message is received from server

      # Send data to client
      # @param data [String] Data to send
      # @param args [Hash] Arguments for send
      # @option args [String] :type Type of frame to send - available types are "text", "binary", "ping", "pong" and "close"
      # @return [Boolean] true if data was send, otherwise call on_error if needed
      def send(data, args = {})
        type = args[:type] || :text
        unless type == :plain
          frame = outgoing_frame.new(:version => @handshake.version, :data => data, :type => type)
          if !frame.supported?
            trigger_onerror("Frame type '#{type}' is not supported in protocol version #{@handshake.version}")
            return false
          elsif !frame.require_sending?
            return false
          end
          data = frame.to_s
        end
        # debug "Sending raw: ", data
        send_data(data)
        true
      end

      # Close connection
      # @return [Boolean] true if connection is closed immediately, false if waiting for server to close connection
      def close
        if @state == :open
          @state = :closing
          return false if send('', :type => :close)
        else
          send('', :type => :close) if @state == :closing
          @state = :closed
        end
        close_connection_after_writing
        true
      end

      # Send ping message to client
      # @return [Boolean] false if protocol version is not supporting ping requests
      def ping(data = '')
        send(data, :type => :ping)
      end

      # Send pong message to client
      # @return [Boolean] false if protocol version is not supporting pong requests
      def pong(data = '')
        send(data, :type => :pong)
      end

      ############################
      ### EventMachine methods ###
      ############################

      def receive_data(data)
        # debug "Received raw: ", data
        case @state
        when :connecting then
          handle_connecting(data)
        when :open then
          handle_open(data)
        when :closing then
          handle_closing(data)
        end
      end

      def unbind
        unless @state == :closed
          @state = :closed
          close
          trigger_onclose('')
        end
      end

      #######################
      ### Private methods ###
      #######################

      private

      ['onopen'].each do |m|
        define_method "trigger_#{m}" do
          callback = instance_variable_get("@#{m}")
          callback.call if callback
        end
      end

      ['onerror', 'onping', 'onpong', 'onclose'].each do |m|
        define_method "trigger_#{m}" do |data|
          callback = instance_variable_get("@#{m}")
          callback.call(data) if callback
        end
      end

      def trigger_onmessage(data, type)
        @onmessage.call(data, type) if @onmessage
      end

      def handle_connecting(data)
        @handshake << data
        return unless @handshake.finished?
        if @handshake.valid?
          send(@handshake.to_s, :type => :plain) if @handshake.should_respond?
          @frame = incoming_frame.new(:version => @handshake.version)
          @state = :open
          trigger_onopen
          handle_open(@handshake.leftovers) if @handshake.leftovers
        else
          trigger_onerror(@handshake.error)
          close
        end
      end

      def handle_open(data)
        @frame << data
        while frame = @frame.next
          case frame.type
          when :close
            @state = :closing
            close
            trigger_onclose(frame.to_s)
          when :ping
            pong(frame.to_s)
            trigger_onping(frame.to_s)
          when :pong
            trigger_onpong(frame.to_s)
          when :text
            trigger_onmessage(frame.to_s, :text)
          when :binary
            trigger_onmessage(frame.to_s, :binary)
          end
        end
        unbind if @frame.error?
      end

      def handle_closing(data)
        @state = :closed
        close
        trigger_onclose
      end

      def debug(description, data)
        puts(description + data.bytes.to_a.collect { |b| '\x' + b.to_s(16).rjust(2, '0') }.join) unless @state == :connecting
      end

    end
  end
end
# Example WebSocket Client (using EventMachine)
# @example
#   ws = WebSocket::EventMachine::Client.connect(:host => "0.0.0.0", :port => 8080)
#   ws.onmessage { |msg| ws.send "Pong: #{msg}" }
#   ws.send "data"
module WebSocket
  module EventMachine
    class Client < Base

      # Connect to websocket server
      # @param args [Hash] The request arguments
      # @option args [String] :host The host IP/DNS name
      # @option args [Integer] :port The port to connect too(default = 80)
      # @option args [Integer] :version Version of protocol to use(default = 13)
      def self.connect(args = {})
        host = nil
        port = nil
        if args[:uri]
          uri = URI.parse(args[:uri])
          host = uri.host
          port = uri.port
        end
        host = args[:host] if args[:host]
        port = args[:port] if args[:port]
        port ||= 80

        ::EventMachine.connect host, port, self, args
      end

      # Initialize connection
      # @param args [Hash] Arguments for connection
      # @option args [String] :host The host IP/DNS name
      # @option args [Integer] :port The port to connect too(default = 80)
      # @option args [Integer] :version Version of protocol to use(default = 13)
      def initialize(args)
        @args = args
      end

      ############################
      ### EventMachine methods ###
      ############################

      # Called after initialize of connection, but before connecting to server
      def post_init
        @state = :connecting
        @handshake = WebSocket::Handshake::Client.new(@args)
      end

      # Called by EventMachine after connecting.
      # Sends handshake to server
      def connection_completed
        send(@handshake.to_s, :type => :plain)
      end

      private

      def incoming_frame
        WebSocket::Frame::Incoming::Client
      end

      def outgoing_frame
        WebSocket::Frame::Outgoing::Client
      end

    end
  end
end





