#encoding: UTF-8
load File.expand_path('window_login.rb', File.dirname(__FILE__))
require 'open-uri'
class Ygocore < Game
  config = YAML.load_file("lib/ygocore/server.yml")
  Register_Url = config['register']
  Port = config['port']
  Server = config['server']
  API_Url = config['api']
  Index_Url = config['index']
  attr_reader :password
  def initialize
    super
    load File.expand_path('event.rb', File.dirname(__FILE__))
    load File.expand_path('user.rb', File.dirname(__FILE__))
    load File.expand_path('room.rb', File.dirname(__FILE__))
    load File.expand_path('scene_lobby.rb', File.dirname(__FILE__))
  end
  def login(username, password)
    if username.empty?
      return Widget_Msgbox.new("登陆", "请输入用户名", :ok => "确定")
    end
    if password.empty?
      Widget_Msgbox.new("登陆", "无密码登陆，不能建房，不能加入竞技场", :ok => "确定"){Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))}
    else
      require 'cgi'
      open("#{API_Url}?userregist=CHANGEPASS&username=#{CGI.escape username}&password=#{CGI.escape password}&oldpass=#{CGI.escape password}") do |file|
        file.set_encoding "GBK"
        result = file.read.encode("UTF-8")
        $log.debug('用户登陆传回消息'){result}
        case result
        when "修改成功"
          connect
          @password = password
          Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))
        when "用户注册禁止"
          connect
          @password = password
          Widget_Msgbox.new("登陆", "验证关闭，加房连接断开请自行检查密码", :ok => "确定"){Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))}
        else
          Game_Event.push Game_Event::Error.new("登陆", "用户名或密码错误")
        end
      end
    end
  end
  def host(room_name, room_config)
    if $game.password.nil? or $game.password.empty?
      return Widget_Msgbox.new("建立房间", "必须有账号才能建立房间", :ok => "确定")
    end
    return unless ygocore_path
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
    return unless ygocore_path
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
        open(API_Url) do |file|
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
    Widget_Msgbox.new("加入房间", "请指定ygocore主程序位置")
    $scene.draw
    require 'tk'
    $config['ygocore']['path'] = Tk.getOpenFile.encode("UTF-8")
    save_config
    @last_clicked = Time.now
  end
  private
  def connect
  end
  def self.get_announcements
    #公告
    $config['ygocore']['announcements'] ||= [Announcement.new("正在读取公告...", nil, nil)]
    Thread.new do
      begin
        open(API_Url) do |file|
          file.set_encoding "GBK"
          announcements = []
          file.read.encode("UTF-8").scan(/<div style="color:red" >公告：(.*?)<\/div>/).each do |title,others|
            announcements << Announcement.new(title, Index_Url, nil)
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