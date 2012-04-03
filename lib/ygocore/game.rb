#encoding: UTF-8
load 'lib/ygocore/window_login.rb'
class Ygocore < Game
  attr_reader :password
  @@config = YAML.load_file("lib/ygocore/server.yml")
  def initialize
    super
    load 'lib/ygocore/event.rb'
    load 'lib/ygocore/user.rb'
    load 'lib/ygocore/room.rb'
    load 'lib/ygocore/scene_lobby.rb'
    require 'json'
  end
  def login(username, password)
    if username.empty?
      return Widget_Msgbox.new("登录", "请输入用户名", :ok => "确定")
    end
    if password.empty?
      Widget_Msgbox.new("登录", "无密码登录，不能建房，不能加入竞技场", :ok => "确定"){Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))}
    else
      require 'cgi'
      result = open("#{@@config['api']}?operation=passcheck&username=#{CGI.escape username}&pass=#{CGI.escape password}") do |file|
        file.set_encoding "GBK"
        result = file.read.encode("UTF-8")
        $log.info('用户登录传回消息'){result}
        result
      end rescue nil
      case result
      when "true"
        connect
        @password = password
        Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))
      when "false"
        Game_Event.push Game_Event::Error.new("登录", "用户名或密码错误", false)
      else
        Widget_Msgbox.new("登录", "连接服务器失败", :ok => "确定")
      end
    end
  end
  def user=(user)
    super
    begin
      require 'net/yail'
      $log.info('聊天'){user.inspect}
      @irc = Net::YAIL.new(
        address: 'card.touhou.cc',
        username: hexencode(user.id),
        nicknames: [hexencode(user.name), hexencode("#{user.name}_#{rand(10000)}"), hexencode("#{user.name}_#{rand(10000)}")]) 
      $log.info('聊天连接')
      @irc.on_welcome proc { |event| $log.info('连接聊天服务器成功'); Game_Event.push(Game_Event::Chat.new(ChatMessage.new(User.new(:system, 'system'), '聊天服务器连接成功,聊天功能测试中，可能引发程序崩溃，如果崩得过于频繁请暂时不要使用.', :lobby))); @irc.join('#lobby') }
      @irc.hearing_msg {|event| 
        user = User.new(hexdecode(event.msg.user).to_sym, hexdecode(event.nick))
        Game_Event.push Game_Event::Chat.new(ChatMessage.new(user, event.message, event.channel ? event.channel[1,event.channel.size-1].to_sym : user))
      }
      $log.info('聊天开始监听')
      @irc.start_listening
      $log.info('聊天加载完毕')
    rescue Exception => exception
      $log.error('聊天出错'){[exception.inspect, *exception.backtrace].collect{|str|str.encode("UTF-8")}.join("\n")}
      Game_Event.push(Game_Event::Chat.new(ChatMessage.new(User.new(:system, 'system'), '连接聊天服务器失败', :lobby)))
    end
      
  end
  def chat(chatmessage)
    $log.info('发送聊天消息'){chatmessage.inspect}
    return unless @irc
    case chatmessage.channel
    when Symbol
      @irc.msg "##{chatmessage.channel}", chatmessage.message
    when User
      @irc.msg hexencode(chatmessage.channel.id), chatmessage.message
    end
    $log.info('发送聊天消息完毕')
  end
  def host(room_name, room_config)
    if $game.password.nil? or $game.password.empty?
      return Widget_Msgbox.new("建立房间", "必须有账号才能建立房间", :ok => "确定")
    end
    if !ygocore_path
      return Widget_Msgbox.destroy
    end
    room = Room.new(0, room_name)
    room.pvp = room_config[:pvp]
    room.match = room_config[:match]
    refresh do
      if $game.rooms.any?{|game_room|game_room.name == room_name}
        Widget_Msgbox.new("建立房间", "房间名已存在", :ok => "确定")
      else
        if !Update.images.empty?
          Widget_Msgbox.new("加入房间", "卡图正在下载中，可能显示不出部分卡图", :ok => "确定"){Game_Event.push Game_Event::Join.new(room)}
        else
          Game_Event.push Game_Event::Join.new(room)
        end
      end
    end
  end
  def watch(room)
    Widget_Msgbox.new("加入房间", "游戏已经开始", :ok => "确定")
  end
  def join(room)
    if $game.password.nil? or $game.password.empty? and room.pvp?
      return Widget_Msgbox.new("加入房间", "必须有账号才能加入竞技场房间", :ok => "确定")
    end
    if !ygocore_path
      return Widget_Msgbox.destroy
    end
    refresh do
      if room.full? #如果游戏已经开了
        Widget_Msgbox.new("加入房间", "游戏已经开始", :ok => "确定")
      elsif !$game.rooms.include? room
        Widget_Msgbox.new("加入房间", "游戏已经取消", :ok => "确定")
      else
        if !Update.images.empty?
          Widget_Msgbox.new("加入房间", "卡图正在下载中，可能出现显示不出卡图", :ok => "确定"){Game_Event.push Game_Event::Join.new(room)}
        else
          Game_Event.push Game_Event::Join.new(room)
        end
      end
    end
  end
  def refresh
    $log.info('刷新大厅信息'){'开始'}
    Thread.new do
      begin
        open("#{@@config['api']}?operation=getroom") do |file|
          file.set_encoding("GBK")
          info = file.read.encode("UTF-8")
          $log.info('刷新大厅信息'){'完成'}
          Game_Event.push Game_Event::AllRooms.parse info
          Game_Event.push Game_Event::AllUsers.parse info
          yield if block_given?
        end
      rescue Exception => exception
        $log.warn('刷新大厅'){[exception.inspect, *exception.backtrace].collect{|str|str.encode("UTF-8")}.join("\n")}
      end
    end
  end
  def exit
    (@irc.quit if @irc) rescue nil
    @irc = nil
    @chat_thread = nil
  end
  def ygocore_path
    #    return $config['ygocore']['path'] if $config['ygocore']['path'] and File.file? $config['ygocore']['path']
    #    return if @last_clicked and Time.now - @last_clicked < 3 #防止重复点击
    #    msgbox = Widget_Msgbox.new("加入房间", "请指定ygocore主程序位置")
    #    $scene.draw
    #    require_relative '../dialog'
    #    $config['ygocore']['path'] = Dialog.get_open_file("请指定ygocore主程序位置","ygocore主程序 (gframe.exe)" => "gframe.exe")
    #    save_config
    #    msgbox.destroy
    #    @last_clicked = Time.now
    "ygocore/gframe.exe"
  end
  def self.register
    system("start #{@@config['register']}")
  end
  def server
    @@config['server']
  end
  def port
    @@config['port']
  end
  def self.run_ygocore(option)
    path = 'ygocore/gframe.exe'
    Widget_Msgbox.new("ygocore", "正在启动ygocore")
    #写入配置文件并运行ygocore
    Dir.chdir(File.dirname(path)) do 
      $log.info('当前目录'){Dir.pwd.encode("UTF-8")}
      case option
      when Room
        room = option
        room_name = if room.pvp? and room.match?
          "PM#" + room.name
        elsif room.pvp?
          "P#" + room.name
        elsif room.match?
          "M#" + room.name
        else
          room.name
        end
        system_conf = {}
        begin
          IO.readlines('system.conf').each do |line|
            line.force_encoding "UTF-8"
            next if line[0,1] == '#'
            field, contents = line.chomp.split(' = ',2)
            system_conf[field] = contents
          end
        rescue
          system_conf['antialias'] = 2
          system_conf['textfont'] = 'c:/windows/fonts/simsun.ttc 14'
          system_conf['numfont'] = 'c:/windows/fonts/arialbd.ttf'
          $log.error('找不到system.conf')
          $log.info(Dir.foreach('.').to_a.inspect)
        end
        system_conf['nickname'] = "#{$game.user.name}#{"$" unless $game.password.nil? or $game.password.empty?}#{$game.password}"
        system_conf['lastip'] = $game.server
        system_conf['lastport'] = $game.port.to_s
        system_conf['roompass'] = room_name
        open('system.conf', 'w') {|file|file.write system_conf.collect{|key,value|"#{key} = #{value}"}.join("\n")}
        args = '-j'
      when :replay
        args = '-r'
      when :deck
        args = '-d'
      end
      $log.info('ygocore参数') {args}
      IO.popen("gframe.exe #{args}")
      WM.iconify
    end
    Widget_Msgbox.destroy
  end
  def self.deck_edit
    Widget_Msgbox.new("编辑卡组", "\"导入\"导入已有卡组，\"编辑\"启动ygocore", :import => "导入", :edit => "编辑") do |button|
      case button 
      when:import
        file = Dialog.get_open_file("导入卡组", "ygocore卡组 (*.ydk)"=>"*.ydk")#"所有支持的卡组 (*.txt;*.deck;*.ydk)"=>"*.ydk;*.txt;*.deck","ygocore卡组 (*.ydk)"=>"*.ydk", "NBX/iDuel/狐查卡组 (*.txt)" => "*.txt", "图形组卡器卡组 (*.deck)"=>"*.deck")
        if !file.empty?
          open(file) do |src|
            Dir.mkdir "ygocore/deck" unless File.directory?("ygocore/deck")
            open("ygocore/deck/#{File.basename(file)}", 'w') do |dest|
              dest.write src.read
            end
            Widget_Msgbox.new("导入卡组", "导入卡组完成", :ok => "确定")
          end rescue Widget_Msgbox.new("导入卡组", "导入卡组失败", :ok => "确定")
        end
      when :edit
        if !Update.images.empty?
          Widget_Msgbox.new("加入房间", "卡图正在下载中，可能显示不出部分卡图", :ok => "确定"){Ygocore.run_ygocore(:deck)}
        else
          Ygocore.run_ygocore(:deck)
        end
      end
    end
  end
  def self.replay(file)
    require 'fileutils'
    FileUtils.mv Dir.glob('ygocore/replay/*.yrp'), 'replay/'
    FileUtils.copy_file(file, "ygocore/replay/#{File.basename(file)}")
    run_ygocore(:replay)
  end
  private
  def connect
    require 'open-uri'
  end
  def hexencode(str)
    '_' + str.to_s.unpack('H*').first
  end
  def hexdecode(str)
    result = str[1, str.size-1]
    [result.to_s].pack('H*')
  end
  def MAKELPARAM(w1,w2)
    (w2<<16) | w1
  end
  def self.get_announcements
    #公告
    $config['ygocore'] ||= {}
    $config['ygocore']['announcements'] ||= [Announcement.new("正在读取公告...", nil, nil)]
    Thread.new do
      begin
        require 'open-uri'
        open(@@config['api']) do |file|
          file.set_encoding "GBK"
          announcements = []
          file.read.encode("UTF-8").scan(/<div style="color:red" >公告：(.*?)<\/div>/).each do |title,others|
            announcements << Announcement.new(title, @@config['index'], nil)
          end
          $config['ygocore']['announcements'].replace announcements
          save_config
        end
      rescue Exception => exception
        $log.error('公告') {[exception.inspect, *exception.backtrace].join("\n")}
      end
    end
  end
  get_announcements
end