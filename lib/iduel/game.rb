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
  def connect
    require 'socket'
    require 'open-uri'
    begin
      @conn = TCPSocket.open(Server, Port)
      @conn.set_encoding "GBK", "UTF-8", :invalid => :replace, :undef => :replace
      @recv = Thread.new do
        begin
          recv @conn.gets(RS) while @conn
        rescue => exception
          Game_Event.push Game_Event::Error.new(exception.class.to_s, exception.message)
          $log.error [exception.inspect, *exception.backtrace].join("\n")
        ensure
          self.exit
        end
      end
    rescue => exception
      Game_Event.push Game_Event::Error.new(exception.class.to_s, exception.message)
      $log.error [exception.inspect, *exception.backtrace].join("\n")
    end
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
    if @room.include? @user
      send(10, @key, room.id, checknum("QROOM", @session + room.id.to_s))
    else
      send(9, @key, checknum("QUITWATCHROOM", @session))
    end
  end
  def action(action)
    send(2, "#{checknum("RMSG", @session)}@#{@key}", "#{action.escape}▊▊▊mycard") #if @room.include? @user#TODO:iduel校验字串
  end
  def exit
    @recv.exit
    if @conn
      leave
      send(11, @key, checknum("ULO", "#{@session}")) 
      @conn.close
      @conn = nil
    end
  end
  
  
  def send(head, *args)
    return unless @conn
    info = "##{head.to_s(16).upcase}|#{args.join(',')}" + RS
    $log.info  "<< #{info}"
    info.gsub!("\n", "\r\n")
    (@conn.write info) rescue Game_Event.push Game_Event::Error.new($!.class.to_s, $!.message)
  end
  def recv(info)
    if info.nil?
      @conn.close
      @conn = nil
      Game_Event::Error.parse(0)
    else
      info.chomp!(RS)
      info.delete!("\r")
      $log.info  ">> #{info}"
      Game_Event.push Game_Event.parse info
    end
  end
  def checknum(head, *args)
    Digest::MD5.hexdigest("[#{head}]_#{args.join('_')}_SCNERO".gsub("\n", "\r\n").encode("GBK"))
  end
  def qroom(room)
    send(10, @key, room.id, checknum("QROOM", @session + room.id.to_s))
  end
  def chat(msg)
    send(4, @key, msg, checknum("CHATP", @session))
    #4|241019,test,2368c6b89b3e2eedb92e1b624a2a157c
  end


end