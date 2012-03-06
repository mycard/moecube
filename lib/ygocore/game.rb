#encoding: UTF-8
load File.expand_path('window_login.rb', File.dirname(__FILE__))
require 'open-uri'
class Ygocore < Game
  Register_Url = 'http://sh.convnet.net:7922/?userregist=NEW'
  Port = 7911
  Server = '221.226.68.62'
  
  WM_LBUTTONDOWN = 0x201
  WM_LBUTTONUP = 0x202
  VK_CONTROL = 0x11
  VK_A = 0x41
  VK_V = 0x56
  VK_TAB = 0x09
  VK_RETURN = 0x0D
  KEYEVENTF_KEYUP = 0x02
  def initialize
    super
    load File.expand_path('event.rb', File.dirname(__FILE__))
    load File.expand_path('user.rb', File.dirname(__FILE__))
    load File.expand_path('room.rb', File.dirname(__FILE__))
  end
  def login(username, password)
    connect
    @password = password
    Game_Event.push Game_Event::Login.new(User.new(username.to_sym, username))
  end
  def watch(room)
    join(room)
  end
  def join(room)
    return if @last_clicked and Time.now - @last_clicked < 3 #防止重复点击
    unless $config['ygocore']['path'] and  File.file? $config['ygocore']['path']
      Widget_Msgbox.new("加入房间", "请指定ygocore主程序位置")
      $scene.draw
      require 'tk'
      $config['ygocore']['path'] = Tk.getOpenFile
      save_config
      @last_clicked = Time.now
    end
    if $config['ygocore']['path'] and File.file? $config['ygocore']['path']
      $scene.draw
      
      #写入ygocore配置文件
      Dir.chdir(File.dirname($config['ygocore']['path'])) do 
        system_conf = {}
        IO.readlines('system.conf').each do |line|
          next if line[0,1] == '#'
          field, contents = line.chomp.split(' = ',2)
          system_conf[field] = contents
          system_conf['nickname'] = "#{@user.name}#{"$" unless @password.empty?}#{@password}"
          system_conf['lastip'] = Server
          system_conf['lastport'] = Port.to_s  
        end
        open('system.conf', 'w') {|file|file.write system_conf.collect{|key,value|"#{key} = #{value}"}.join("\n")}
        
        #运行ygocore
        require 'launchy'
        Launchy.open $config['ygocore']['path']
        
        #初始化windows API
        require 'win32api'
        @@FindWindow = Win32API.new("user32","FindWindow","pp","l")
        @@SendMessage = Win32API.new('user32', 'SendMessage', ["L", "L", "L", "L"], "L")
        @@SetForegroundWindow = Win32API.new('user32', 'SetForegroundWindow', 'l', 'v')
        @@keybd_event = Win32API.new('user32', 'keybd_event', 'llll', 'v')
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
          sleep 0.2
          require 'win32/clipboard'
          Win32::Clipboard.set_data(room.name.encode("GBK").force_encoding("UTF-8"))
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
          Widget_Msgbox.new("加入房间", 'ygocore运行失败')
        end
      end
    end
    $scene = Scene_Lobby.new
  end
  def refresh
    Thread.new do
      begin
        open('http://sh.convnet.net:7922/') do |file|
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
        open('http://sh.convnet.net:7922/') do |file|
          file.set_encoding "GBK"
          announcements = []
          file.read.scan(/<div style="color:red" >(.*?)<\/div>/).each do |title,others|
            announcements << Announcement.new(title.encode("UTF-8"), "http://sh.convnet.net:7922/", nil)
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