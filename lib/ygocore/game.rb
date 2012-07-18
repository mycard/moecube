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
  end

  def refresh_interval
    60
  end

  def login(username, password)
    @username = username
    @password = password
    connect
  end

  def connect
    @recv = Thread.new do
      EventMachine::run {
        EventMachine::connect "bbs.66rpg.com", 9998, Client
      }
    end
  end

  def chat(chatmessage)
    case chatmessage.channel
      when :lobby
        send(:chat, channel: :lobby, message: chatmessage.message, time: chatmessage.time)
      when User
        send(:chat, channel: chatmessage.channel.id, message: chatmessage.message, time: chatmessage.time)
    end

  end

  def host(room_name, room_config)
    room = Room.new(0, room_name)
    room.pvp = room_config[:pvp]
    room.match = room_config[:match]
    room.tag = room_config[:tag]
    room.password = room_config[:password]
    room.ot = room_config[:ot]
    room.lp = room_config[:lp]
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
          system_conf = {}
          begin
            IO.readlines('system.conf').each do |line|
              line.force_encoding "UTF-8"
              next if line[0, 1] == '#'
              field, contents = line.chomp.split(' = ', 2)
              system_conf[field] = contents
            end
          rescue
            system_conf['antialias'] = 2
            system_conf['textfont'] = 'c:/windows/fonts/simsun.ttc 14'
            system_conf['numfont'] = 'c:/windows/fonts/arialbd.ttf'
          end
          (system_conf['nickname'] = "#{$game.user.name}#{"$" unless $game.password.nil? or $game.password.empty?}#{$game.password}") rescue nil
          system_conf['lastip'] = $game.server
          system_conf['lastport'] = $game.port.to_s
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
              field, contents = line.chomp.split(' = ', 2)
              system_conf[field] = contents
            end
          rescue
            system_conf['antialias'] = 2
            system_conf['textfont'] = 'c:/windows/fonts/simsun.ttc 14'
            system_conf['numfont'] = 'c:/windows/fonts/arialbd.ttf'
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
    $config['ygocore'] ||= {}
    $config['ygocore']['announcements'] ||= [Announcement.new("正在读取公告...", nil, nil)]
    Thread.new do
      begin
        open(@@config['api']) do |file|
          file.set_encoding "GBK"
          announcements = []
          file.read.encode("UTF-8").scan(/<div style="color:red" >公告：(.*?)<\/div>/).each do |title, others|
            announcements << Announcement.new(title, @@config['index'], nil)
          end
          $config['ygocore']['announcements'].replace announcements
          Config.save
        end
      rescue Exception => exception
        $log.error('公告读取失败') { [exception.inspect, *exception.backtrace].collect { |str| str.encode("UTF-8") }.join("\n") }
      end
    end
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