#encoding: UTF-8
load 'lib/ygocore/window_login.rb'
require 'eventmachine'
require 'open-uri'
require 'yaml'
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
    #require 'xmpp4r/client'
    #require 'xmpp4r/muc'
  end

  def refresh_interval
    60
  end

  def login(username, password)
    @username          = username
    @password          = password
    #@nickname_conflict = []
    #@@im               = Jabber::Client.new(Jabber::JID::new(@username, 'my-card.in', 'mycard'))
    #@@im_room          = Jabber::MUC::MUCClient.new(@@im)
    #Jabber.debug       = true

    #@@im.on_exception do |exception, c, where|
    #  $log.error('聊天出错') { [exception, c, where] }
    #  if where == :close
    #    Game_Event.push(Game_Event::Chat.new(ChatMessage.new(User.new(:system, 'System'), '聊天连接断开, 可能是网络问题或帐号从其他地点登录')))
    #  else
    #    Game_Event.push(Game_Event::Chat.new(ChatMessage.new(User.new(:system, 'System'), '聊天连接断开, 5秒后重新连接')))
    #    sleep 5
    #    im_connect
    #  end
    #end
    #@@im_room.add_message_callback do |m|
    #  user = m.from.resource == nickname ? @user : User.new(m.from.resource.to_sym, m.from.resource)
    #  Game_Event.push Game_Event::Chat.new ChatMessage.new(user, m.body, :lobby) rescue $log.error('收到聊天消息') { $! }
    #end
    #@@im_room.add_private_message_callback do |m|
    #  if m.body #忽略无消息的正在输入等内容
    #    user = m.from.resource == nickname ? @user : User.new(m.from.resource.to_sym, m.from.resource)
    #    Game_Event.push Game_Event::Chat.new ChatMessage.new(user, m.body, user) rescue $log.error('收到私聊消息') { $! }
    #  end
    #end
    #@@im_room.add_join_callback do |m|
    #  Game_Event.push Game_Event::NewUser.new User.new m.from.resource.to_sym, m.from.resource
    #end
    #@@im_room.add_leave_callback do |m|
    #  Game_Event.push Game_Event::MissingUser.new User.new m.from.resource.to_sym, m.from.resource
    #end
    connect
    #im_connect
  end

  #def nickname
  #  return @nickname if @nickname
  #  if @nickname_conflict.include? @username
  #    1.upto(9) do |i|
  #      result = "#{@username}-#{i}"
  #      return result unless @nickname_conflict.include? result
  #    end
  #    raise 'can`t get available nickname'
  #  else
  #    @username
  #  end
  #end

  def connect
    @recv = Thread.new do
      EventMachine::run {
        EventMachine::connect "mycard-server.my-card.in", 9997, Client
      }
    end
  end

  #def im_connect
  #  Thread.new {
  #    begin
  #      @@im.allow_tls = false
  #      @@im.use_ssl   = true
  #      @@im.connect('my-card.in', 5223)
  #      #ruby19/windows下 使用tls连接时会卡住
  #
  #      @@im.auth(@password)
  #      @@im.send(Jabber::Presence.new.set_type(:available))
  #      begin
  #        nickname = nickname()
  #        @@im_room.join(Jabber::JID.new(I18n.t('lobby.room'), I18n.t('lobby.server'), nickname))
  #      rescue Jabber::ServerError => exception
  #        if exception.error.error == 'conflict'
  #          @nickname_conflict << nickname
  #          retry
  #        end
  #      end
  #      Game_Event.push Game_Event::AllUsers.new @@im_room.roster.keys.collect { |nick| User.new(nick.to_sym, nick) } rescue p $!
  #    rescue StandardError => exception
  #      $log.error('聊天连接出错') { exception }
  #      Game_Event.push(Game_Event::Chat.new(ChatMessage.new(User.new(:system, 'System'), '聊天服务器连接失败')))
  #    end
  #  }
  #end

  #def chat(chatmessage)
  #  case chatmessage.channel
  #  when :lobby
  #    msg = Jabber::Message::new(nil, chatmessage.message)
  #    @@im_room.send msg
  #  when User
  #    msg = Jabber::Message::new(nil, chatmessage.message)
  #    @@im_room.send msg, chatmessage.channel.id
  #    #send(:chat, channel: chatmessage.channel.id, message: chatmessage.message, time: chatmessage.time)
  #  end
  #end
  def chat(chatmessage)
    case chatmessage.channel
    when :lobby
      send(:chat, channel: :lobby, message: chatmessage.message, time: chatmessage.time)
    when User
      send(:chat, channel: chatmessage.channel.id, message: chatmessage.message, time: chatmessage.time)
    end
  end

  def host(room_name, room_config)
    room          = Room.new(0, room_name)
    room.pvp      = room_config[:pvp]
    room.match    = room_config[:match]
    room.tag      = room_config[:tag]
    room.password = room_config[:password]
    room.ot       = room_config[:ot]
    room.lp       = room_config[:lp]
    room.server_ip = $game.server
    room.server_port = $game.port
    room.server_auth = true
    if $game.rooms.any? { |game_room| game_room.name == room_name }
      Widget_Msgbox.new("建立房间", "房间名已存在", :ok => "确定")
    else
      Game_Event.push Game_Event::Join.new(room)
    end
  end

  def watch(room)
    Widget_Msgbox.new("加入房间", "游戏已经开始", :ok => "确定")
  end

  def join(room)
    Game_Event.push Game_Event::Join.new(room)
  end

  def refresh
    send(:refresh)
  end

  def send(header, data=nil)
    $log.info('发送消息') { {header: header, data: data} }
    Client::MycardChannel.push header: header, data: data
  end

  def exit
    @recv.exit if @recv
    @recv = nil
  end

  def ygocore_path
    "ygocore/ygopro_vs.exe"
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

  def self.run_ygocore(option, image_downloading=false)
    if !image_downloading and !Update.images.empty?
      return Widget_Msgbox.new("加入房间", "卡图正在下载中，可能显示不出部分卡图", :ok => "确定") { run_ygocore(option, true) }
    end
    path = 'ygocore/ygopro_vs.exe'
    Widget_Msgbox.new("ygocore", "正在启动ygocore") rescue nil
    #写入配置文件并运行ygocore
    Dir.chdir(File.dirname(path)) do
      case option
      when Room
        room      = option
        room_name = if room.ot != 0 or room.lp != 8000
                      mode      = case when room.match? then
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
        system_conf = {}
        begin
          IO.readlines('system.conf').each do |line|
            line.force_encoding "UTF-8"
            next if line[0, 1] == '#'
            field, contents    = line.chomp.split(' = ', 2)
            system_conf[field] = contents
          end
        rescue
          system_conf['antialias'] = 2
          system_conf['textfont']  = 'c:/windows/fonts/simsun.ttc 14'
          system_conf['numfont']   = 'c:/windows/fonts/arialbd.ttf'
        end
        system_conf['nickname'] = $game.user.name
        system_conf['nickname'] += '$' + $game.password if $game.password and !$game.password.empty? and room.server_auth
        p room
        system_conf['lastip']   = room.server_ip
        system_conf['lastport'] = room.server_port.to_s
        system_conf['roompass'] = room_name
        open('system.conf', 'w') { |file| file.write system_conf.collect { |key, value| "#{key} = #{value}" }.join("\n") }
        args = '-j'
      when :replay
        args = '-r'
      when :deck
        args = '-d'
      when String
        system_conf = {}
        begin
          IO.readlines('system.conf').each do |line|
            line.force_encoding "UTF-8"
            next if line[0, 1] == '#'
            field, contents    = line.chomp.split(' = ', 2)
            system_conf[field] = contents
          end
        rescue
          system_conf['antialias'] = 2
          system_conf['textfont']  = 'c:/windows/fonts/simsun.ttc 14'
          system_conf['numfont']   = 'c:/windows/fonts/arialbd.ttf'
        end
        system_conf['lastdeck'] = option
        open('system.conf', 'w') { |file| file.write system_conf.collect { |key, value| "#{key} = #{value}" }.join("\n") }
        args = '-d'
      end
      IO.popen("ygopro_vs.exe #{args}")
      WM.iconify rescue nil
    end
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
    $config['ygocore']                  ||= {}
    $config['ygocore']['announcements'] ||= [Announcement.new("开放注册", nil, nil)]
    #Thread.new do
    #  begin
    #    open(@@config['api']) do |file|
    #      file.set_encoding "GBK"
    #      announcements = []
    #      file.read.encode("UTF-8").scan(/<div style="color:red" >公告：(.*?)<\/div>/).each do |title, others|
    #        announcements << Announcement.new(title, @@config['index'], nil)
    #      end
    #      $config['ygocore']['announcements'].replace announcements
    #      Config.save
    #    end
    #  rescue Exception => exception
    #    $log.error('公告读取失败') { [exception.inspect, *exception.backtrace].collect { |str| str.encode("UTF-8") }.join("\n") }
    #  end
    #end
  end

  module Client
    MycardChannel = EM::Channel.new
    include EM::P::ObjectProtocol

    def post_init
      send_object header: :login, data: {name: $game.username, password: $game.password}
      MycardChannel.subscribe { |msg| send_object(msg) }
    end

    def receive_object obj
      $log.info('收到消息') { obj.inspect }
      Game_Event.push Game_Event.parse obj[:header], obj[:data]
    end

    def unbind
      Game_Event.push Game_Event::Error.new('ygocore', '网络连接中断', true)
    end
  end
  get_announcements
end