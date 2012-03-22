#encoding: UTF-8
load 'lib/ygocore/window_login.rb'
class Ygocore < Game
  attr_reader :password
  @@config = YAML.load_file("lib/ygocore/server.yml")
  
  WM_LBUTTONDOWN = 0x201
  WM_LBUTTONUP = 0x202
  VK_CONTROL = 0x11
  VK_A = 0x41
  VK_V = 0x56
  VK_TAB = 0x09
  VK_RETURN = 0x0D
  KEYEVENTF_KEYUP = 0x02
  CF_UNICODETEXT = 13;
  GMEM_DDESHARE = 0x2000;
  
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
        Game_Event.push Game_Event::Error.new("登陆", "用户名或密码错误", false)
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
        end rescue nil
      end
    end
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
   
    
    $scene.draw
    #写入配置文件并运行ygocore
    Dir.chdir(File.dirname(path)) do 
      $log.info('当前目录'){Dir.pwd.encode("UTF-8")}
      if option.is_a?(Room)
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
        open('system.conf', 'w') {|file|file.write system_conf.collect{|key,value|"#{key} = #{value}"}.join("\n")}
      end
      $log.info('ygocore路径') {path}
      IO.popen('gframe.exe') #执行外部程序....有中文的情况下貌似只能这样了orz
    end

    #初始化windows API
    require 'win32api'
    @@FindWindow ||= Win32API.new("user32","FindWindow","pp","l")
    @@SendMessage ||= Win32API.new('user32', 'SendMessage', ["L", "L", "L", "L"], "L")
    @@SetForegroundWindow ||= Win32API.new('user32', 'SetForegroundWindow', 'l', 'v')
    @@keybd_event ||= Win32API.new('user32', 'keybd_event', 'llll', 'v')
    @@lstrcpy ||= Win32API.new('kernel32', 'lstrcpyW', ['I', 'P'], 'P');
    @@lstrlen ||= Win32API.new('kernel32', 'lstrlenW', ['P'], 'I');
    @@OpenClipboard ||= Win32API.new('user32', 'OpenClipboard', ['I'], 'I');
    @@CloseClipboard ||= Win32API.new('user32', 'CloseClipboard', [], 'I');
    @@EmptyClipboard ||= Win32API.new('user32', 'EmptyClipboard', [], 'I');
    @@SetClipboardData ||= Win32API.new('user32', 'SetClipboardData', ['I', 'I'], 'I');
    @@GlobalAlloc ||= Win32API.new('kernel32', 'GlobalAlloc', ['I','I'], 'I');
    @@GlobalLock ||= Win32API.new('kernel32', 'GlobalLock', ['I'], 'I');
    @@GlobalUnlock ||= Win32API.new('kernel32', 'GlobalUnlock', ['I'], 'I');
    #获取句柄
    hwnd = nil
    50.times do
      if (hwnd = @@FindWindow.call('CIrrDeviceWin32', nil)) != 0
        break
      else
        sleep 0.1
      end
    end
    if hwnd and hwnd != 0
      #操作ygocore进入主机
      WM.iconify
      
      if option.is_a? Room
        @@SendMessage.call(hwnd, WM_LBUTTONDOWN, 0, MAKELPARAM(507,242))
        @@SendMessage.call(hwnd, WM_LBUTTONUP, 0, MAKELPARAM(507,242))
        sleep 0.5
        if @@OpenClipboard.Call(0) != 0
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
          $log.info('加入房间'){room_name}
          @@EmptyClipboard.Call();
          len = room_name.encode("UTF-16LE").bytesize
          #p len=@@lstrlen.call(room_name.encode("UTF-16LE"))#
          $log.info('房间名长度'){len.to_s}
          hmem = @@GlobalAlloc.Call(GMEM_DDESHARE, len+2);
          pmem = @@GlobalLock.Call(hmem);
          @@lstrcpy.Call(pmem, room_name.encode("UTF-16LE"));
          @@SetClipboardData.Call(CF_UNICODETEXT, hmem);
          @@GlobalUnlock.Call(hmem);
          @@CloseClipboard.Call;
          @@SetForegroundWindow.call(hwnd)
          @@SendMessage.call(hwnd, WM_LBUTTONDOWN, 0, MAKELPARAM(380,500))
          @@SendMessage.call(hwnd, WM_LBUTTONUP, 0, MAKELPARAM(380,500))
          @@keybd_event.call(VK_CONTROL,0,0,0)
          @@keybd_event.call(VK_A,0,0,0)#全选以避免密码处已经有字的情况，正常情况下应该无用
          @@keybd_event.call(VK_A,0,KEYEVENTF_KEYUP,0)
          @@keybd_event.call(VK_V,0,0,0)
          @@keybd_event.call(VK_V,0,KEYEVENTF_KEYUP,0)
          @@keybd_event.call(VK_CONTROL,0,KEYEVENTF_KEYUP,0)
          @@keybd_event.call(VK_TAB,0,0,0)
          @@keybd_event.call(VK_TAB,0,KEYEVENTF_KEYUP,0)
          @@keybd_event.call(VK_RETURN,0,0,0)
          @@keybd_event.call(VK_RETURN,0,KEYEVENTF_KEYUP,0)
          Widget_Msgbox.destroy
        else
          Widget_Msgbox.new("加入房间", '填写房间名失败 请把房间名手动填写到房间密码处', :ok => "确定")
        end
      else
        @@SendMessage.call(hwnd, WM_LBUTTONDOWN, 0, MAKELPARAM(507,389))
        @@SendMessage.call(hwnd, WM_LBUTTONUP, 0, MAKELPARAM(507,389))
        Widget_Msgbox.destroy
      end
    else
      Widget_Msgbox.new("加入房间", 'ygocore运行失败', :ok => "确定")
    end
  end
  private
  def connect
    require 'open-uri'
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

def MAKELPARAM(w1,w2)
  (w2<<16) | w1
end