class Scene_Lobby
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
  def join(room)
    path = $game.ygocore_path
    return Widget_Msgbox.destroy unless path
    Widget_Msgbox.new("加入房间", "正在启动ygocore")
    room_name = if room.pvp? and room.match?
      "PM#" + room.name
    elsif room.pvp?
      "P#" + room.name
    elsif room.match?
      "M#" + room.name
    else
      room.name
    end
      
    $scene.draw
    #写入配置文件并运行ygocore
    Dir.chdir(File.dirname(path)) do 
      $log.info('当前目录'){Dir.pwd.encode("UTF-8")}
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
      $log.info('ygocore路径') {path}
      IO.popen("\"#{path}\"".encode("GBK")) #执行外部程序....有中文的情况下貌似只能这样了orz
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
      @@SendMessage.call(hwnd, WM_LBUTTONDOWN, 0, MAKELPARAM(507,242))
      @@SendMessage.call(hwnd, WM_LBUTTONUP, 0, MAKELPARAM(507,242))
      sleep 0.5
      if @@OpenClipboard.Call(0) != 0
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
        Widget_Msgbox.destroy  #仅仅为了消掉正在加入房间的消息框
      else
        Widget_Msgbox.new("加入房间", '填写房间名失败 请把房间名手动填写到房间密码处', :ok => "确定")
      end
    else
      Widget_Msgbox.new("加入房间", 'ygocore运行失败', :ok => "确定")
    end
    #这里似乎有个能引起ruby解释器崩溃的故障，但是没法稳定重现。
  end
  def MAKELPARAM(w1,w2)
    return (w2<<16) | w1
  end
end
