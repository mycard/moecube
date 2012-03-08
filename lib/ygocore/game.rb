#encoding: UTF-8
load File.expand_path('window_login.rb', File.dirname(__FILE__))
require 'open-uri'
class Ygocore < Game
  Register_Url = 'http://140.113.242.65/register.html'
  Port = 7911
  Server = '140.113.242.65'
  
  WM_LBUTTONDOWN = 0x201
  WM_LBUTTONUP = 0x202
  #WM_KEYDOWN = 0x0100
  #WM_KEYUP = 0x0100
  VK_CONTROL = 0x11
  VK_A = 0x41
  VK_V = 0x56
  VK_TAB = 0x09
  VK_RETURN = 0x0D
  KEYEVENTF_KEYUP = 0x02
  CF_TEXT = 1;
  GMEM_DDESHARE = 0x2000;
  def initialize
    super
    load File.expand_path('event.rb', File.dirname(__FILE__))
    load File.expand_path('user.rb', File.dirname(__FILE__))
    load File.expand_path('room.rb', File.dirname(__FILE__))
  end
  def login(username, password)
    if username.empty?
      return Widget_Msgbox.new("登陆", "请输入用户名", :ok => "确定")
    end
    connect
    @password = password
    Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))
  end
  def watch(room)
    Widget_Msgbox.new("观战", "ygocore不支持加入已经开始游戏的房间", :ok => "确定")
  end
  def join(room)
    return if @last_clicked and Time.now - @last_clicked < 3 #防止重复点击
    unless $config['ygocore']['path'] and  File.file? $config['ygocore']['path']
      Widget_Msgbox.new("加入房间", "请指定ygocore主程序位置")
      $scene.draw
      require 'tk'
      $config['ygocore']['path'] = Tk.getOpenFile.encode("UTF-8")
      save_config
      @last_clicked = Time.now
    end
    if $config['ygocore']['path'] and File.file? $config['ygocore']['path']
      $scene.draw
      #写入配置文件并运行ygocore
      Dir.chdir(File.dirname($config['ygocore']['path'])) do 
        $log.debug('当前目录'){Dir.pwd.encode("UTF-8")}
        system_conf = {}
        IO.readlines('system.conf').each do |line|
          line.force_encoding "UTF-8"
          next if line[0,1] == '#'
          field, contents = line.chomp.split(' = ',2)
          system_conf[field] = contents
        end
        system_conf['nickname'] = "#{@user.name}#{"$" unless @password.empty?}#{@password}"
        system_conf['lastip'] = Server
        system_conf['lastport'] = Port.to_s  
        open('system.conf', 'w') {|file|file.write system_conf.collect{|key,value|"#{key} = #{value}"}.join("\n")}
        $log.debug('ygocore路径') {$config['ygocore']['path']}
        IO.popen("\"#{$config['ygocore']['path']}\"".encode("GBK")) #执行外部程序....有中文的情况下貌似只能这样了orz
      end
      #初始化windows API
      require 'win32api'
      @@FindWindow = Win32API.new("user32","FindWindow","pp","l")
      @@SendMessage = Win32API.new('user32', 'SendMessage', ["L", "L", "L", "L"], "L")
      @@SetForegroundWindow = Win32API.new('user32', 'SetForegroundWindow', 'l', 'v')
      @@keybd_event = Win32API.new('user32', 'keybd_event', 'llll', 'v')
      @@lstrcpy = Win32API.new('kernel32', 'lstrcpy', ['I', 'P'], 'P');
      @@lstrlen = Win32API.new('kernel32', 'lstrlen', ['P'], 'I');
      @@OpenClipboard = Win32API.new('user32', 'OpenClipboard', ['I'], 'I');
      @@CloseClipboard = Win32API.new('user32', 'CloseClipboard', [], 'I');
      @@EmptyClipboard = Win32API.new('user32', 'EmptyClipboard', [], 'I');
      @@SetClipboardData = Win32API.new('user32', 'SetClipboardData', ['I', 'I'], 'I');
      @@GlobalAlloc = Win32API.new('kernel32', 'GlobalAlloc', ['I','I'], 'I');
      @@GlobalLock = Win32API.new('kernel32', 'GlobalLock', ['I'], 'I');
      @@GlobalUnlock = Win32API.new('kernel32', 'GlobalUnlock', ['I'], 'I');
      #获取句柄
      hwnd = nil
      100.times do
        if (hwnd = @@FindWindow.call('CIrrDeviceWin32', nil)) != 0
          break
        else
          sleep 0.1
        end
      end
      if hwnd and hwnd != 0
        #操作ygocore进入主机
        @@SendMessage.call(hwnd, WM_LBUTTONDOWN, 0, MAKELPARAM(507,242))
        @@SendMessage.call(hwnd, WM_LBUTTONUP, 0, MAKELPARAM(507,242))
        sleep 0.3
        if @@OpenClipboard.Call(0) != 0
          @@EmptyClipboard.Call();
          len = @@lstrlen.Call(room.name.encode("GBK"));
          hmem = @@GlobalAlloc.Call(GMEM_DDESHARE, len+1);
          pmem = @@GlobalLock.Call(hmem);
          @@lstrcpy.Call(pmem, room.name.encode("GBK"));
          @@SetClipboardData.Call(CF_TEXT, hmem);
          @@GlobalUnlock.Call(hmem);
          @@CloseClipboard.Call;
        else
          return Widget_Msgbox.new("加入房间", '填写房间名失败 请把房间名手动填写到房间密码处', :ok => "确定")
        end
        $log.debug('加入房间'){room.name}
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
      else
        return Widget_Msgbox.new("加入房间", 'ygocore运行失败', :ok => "确定")
      end
    end
    Widget_Msgbox.new("加入房间","已经加入房间").destroy  #仅仅为了消掉正在加入房间的消息框
  end
  def refresh
    Thread.new do
      begin
        open('http://140.113.242.65:7922/') do |file|
          file.set_encoding("GBK")
          info = file.read.encode("UTF-8")
          Game_Event.push Game_Event::AllUsers.parse info
          Game_Event.push Game_Event::AllRooms.parse info
        end
      end
    end
  end
  private
  def connect
  end
  def MAKELPARAM(w1,w2)
    return (w2<<16) | w1
  end

  def self.get_announcements
    #公告
    $config['ygocore']['announcements'] ||= [Announcement.new("正在读取公告...", nil, nil)]
    Thread.new do
      begin
        open('http://140.113.242.65:7922/') do |file|
          file.set_encoding "GBK"
          announcements = []
          file.read.encode("UTF-8").scan(/<div style="color:red" >公告：(.*?)<\/div>/).each do |title,others|
            announcements << Announcement.new(title, "http://140.113.242.65/", nil)
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