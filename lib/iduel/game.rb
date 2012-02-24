#encoding: UTF-8
load File.expand_path('window_login.rb', File.dirname(__FILE__))
class Iduel < Game
  Version = "20110131"
  Server = "iduel.ocgsoft.cn"
  Register_Url = 'http://www.duelcn.com/member.php?mod=join_id'
  Port = 38522
  RS = "￠"
  attr_accessor :session
  attr_accessor :key
  def initialize
    super
    require 'digest/md5'
    load File.expand_path('action.rb', File.dirname(__FILE__))
    load File.expand_path('event.rb', File.dirname(__FILE__))
    load File.expand_path('user.rb', File.dirname(__FILE__))
    load File.expand_path('replay.rb', File.dirname(__FILE__))
  end

  def rename
    ##8|241019,测试改昵称,5b58559aaf8869282fe3cb9585ffa909￠
    #$N|iDuel系统,您的改名请求已经提交，重新登录后即可看到效果。￠
  end
  def login(username, password)
    connect
    md5 = Digest::MD5.hexdigest(password)
    send(0, username, md5, checknum("LOGINMSG", username, md5), Version)
  end
  def refresh
    send(1, @key, checknum("UPINFOMSG", @session))
  end
  def host(name, password="", lv=0, color = 0)
    send(6, @key, name, password, checknum("JOINROOMMSG", @session + name + password + "0"), 0, color, lv, 0, 0, 0) #TODO:v.ak, v.al
  end
  def join(room, password="")
    send(6, @key, room.id, password, checknum("JOINROOMMSG", @session + room.id.to_s + password + "1"),1)
  end
  def watch(room, password="")
    send(5, @key, room.id, password, checknum("WATCHROOMMSG", "#{@session}#{room.id}#{password}"))
  end
  def leave
    return unless @room
    if @room.include? @user
      send(10, @key, room.id, checknum("QROOM", @session + room.id.to_s))
    else
      send(9, @key, checknum("QUITWATCHROOM", @session))
    end
  end
  def action(action)
    send(2, "#{checknum("RMSG", @session)}@#{@key}", "#{action.escape}▊▊▊mycard") #消息校验字串，为了防止由于mycard开源造成外挂泛滥扰乱正常iduel秩序，这里不模仿iduel计算校验字串，直接发送mycard供iduel识别
  end
  def exit
    @recv.exit if @recv
    if @conn
      leave
      send(11, @key, checknum("ULO", "#{@session}")) 
      @conn.close
      @conn = nil
    end
  end
  
  

  def recv(info)
    if info.nil?
      @conn.close
      @conn = nil
      Game_Event.push Game_Event::Error.parse(0)
    else
      info.chomp!(RS)
      info.delete!("\r")
      $log.info  ">> #{info}"
      Game_Event.push Game_Event.parse info
    end
  end

  #def qroom(room)
  #  send(10, @key, room.id, checknum("QROOM", @session + room.id.to_s))
  #end
  def chat(msg, channel=:lobby)
    msg.gsub!(",", "@@@@")
    case channel
    when :lobby
      send(4, @key, msg, checknum("CHATP", @session))
    when User #私聊
      send(3, @key, "#{channel.name}(#{channel.id})", msg, checknum("CHATX", @session + "X" + "#{channel.name}(#{channel.id})"))
    end
    
    #4|241019,test,2368c6b89b3e2eedb92e1b624a2a157c
  end
  private
  def connect
    require 'socket'
    require 'open-uri'
    begin
      @conn = TCPSocket.new(Server, Port) #TODO: 阻塞优化，注意login。下面注释掉的两句实现connect无阻塞，但是login依然会阻塞所以只优化这里没有意义
      #@conn = Socket.new(:INET, :STREAM)
      @conn.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace
      @recv = Thread.new do
        begin
          #@conn.connect Socket.pack_sockaddr_in(Port, Server)
          recv @conn.gets(RS) while @conn
        rescue => exception
          Game_Event.push Game_Event::Error.new(exception.class.to_s, exception.message)
          $log.error('iduel-connect-1') {[exception.inspect, *exception.backtrace].join("\n")}
        ensure
          self.exit
        end
      end
    rescue => exception
      Game_Event.push Game_Event::Error.new("网络错误", "连接服务器失败")
      $log.error('iduel-connect-2') {[exception.inspect, *exception.backtrace].join("\n")}
    end
  end
  def checknum(head, *args)
    Digest::MD5.hexdigest("[#{head}]_#{args.join('_')}_SCNERO".gsub("\n", "\r\n").encode("GBK"))
  end
  def send(head, *args)
    return unless @conn
    info = "##{head.to_s(16).upcase}|#{args.join(',')}" + RS
    $log.info  "<< #{info}"
    info.gsub!("\n", "\r\n")
    (@conn.write info) rescue Game_Event.push Game_Event::Error.new($!.class.to_s, $!.message)
  end
end