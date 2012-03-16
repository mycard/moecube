#encoding: UTF-8
load File.expand_path('window_login.rb', File.dirname(__FILE__))
class Ygocore < Game
  attr_reader :password
  @@config = YAML.load_file("lib/ygocore/server.yml")
  def initialize
    super
    load File.expand_path('event.rb', File.dirname(__FILE__))
    load File.expand_path('user.rb', File.dirname(__FILE__))
    load File.expand_path('room.rb', File.dirname(__FILE__))
    load File.expand_path('scene_lobby.rb', File.dirname(__FILE__))
    require 'json'
  end
  def login(username, password)
    if username.empty?
      return Widget_Msgbox.new("登陆", "请输入用户名", :ok => "确定")
    end
    if password.empty?
      Widget_Msgbox.new("登陆", "无密码登陆，不能建房，不能加入竞技场", :ok => "确定"){Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))}
    else
      require 'cgi'
      result = open("#{@@config['api']}?operation=passcheck&username=#{CGI.escape username}&pass=#{CGI.escape password}") do |file|
        file.set_encoding "GBK"
        result = file.read.encode("UTF-8")
        $log.info('用户登陆传回消息'){result}
        result
      end rescue nil
      case result
      when "true"
        connect
        @password = password
        Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))
      when "false"
        Game_Event.push Game_Event::Error.new("登陆", "用户名或密码错误")
      else
        Widget_Msgbox.new("登陆", "连接服务器失败", :ok => "确定")
      end
    end
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
        Game_Event.push Game_Event::Join.new(room)
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
        Game_Event.push Game_Event::Join.new(room)
      end
    end
  end
  def refresh
    Thread.new do
      begin
        open("#{@@config['api']}?operation=getroom") do |file|
          file.set_encoding("GBK")
          info = file.read.encode("UTF-8")
          Game_Event.push Game_Event::AllUsers.parse info
          Game_Event.push Game_Event::AllRooms.parse info
          yield if block_given?
        end
      end
    end
  end
  def ygocore_path
    return $config['ygocore']['path'] if $config['ygocore']['path'] and File.file? $config['ygocore']['path']
    return if @last_clicked and Time.now - @last_clicked < 3 #防止重复点击
    msgbox = Widget_Msgbox.new("加入房间", "请指定ygocore主程序位置")
    $scene.draw
    require 'tk'
    $config['ygocore']['path'] = Tk.getOpenFile.encode("UTF-8")
    save_config
    msgbox.destroy
    @last_clicked = Time.now
  end
  def self.register
    require 'launchy'
    Launchy.open @@config['register']
  end
  def server
    @@config['server']
  end
  def port
    @@config['port']
  end
  private
  def connect
    require 'open-uri'
  end
  def self.get_announcements
    #公告
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