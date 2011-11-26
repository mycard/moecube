#encoding: UTF-8
class Iduel
  VERSION = "20110131"
  Server = "iduel.ocgsoft.cn"
  Port = 38522
  
  RS = "\xA1\xE9".force_encoding "GBK"
  Color = [[0,0,0], [255,0,0], [0,255,0], [0,0,255], [255, 165, 0]]
  attr_accessor :session
  attr_accessor :user
  attr_accessor :room_id
  attr_accessor :key
  attr_accessor :rooms
  def initialize
    require 'socket'
    require 'digest/md5'
    require 'open-uri'
    require_relative 'iduel_action'
    require_relative 'iduel_event'
    require_relative 'iduel_user'
    require_relative 'iduel_room'
    @conn = TCPSocket.open(Server, Port)
    @conn.set_encoding "GBK"
    Thread.abort_on_exception = true
    @recv = Thread.new { recv @conn.gets(RS) while @conn  }
  end
  def send(head, *args)
    info = "##{head.to_s(16).upcase}|#{args.join(',')}".encode("GBK") + RS
    puts "<< #{info}"
    (@conn.write info) rescue Event.push Event::Error.new(0)
  end
  def recv(info)
    Event.push begin
      info.chomp!(RS)
      info.encode! "UTF-8", :invalid => :replace, :undef => :replace
      puts ">> #{info}"
      Event.parse info
    rescue IOError
      @conn.close
      @conn = nil
      Event::Error.new(0)
    end
  end
  def close
    $iduel.quit
    @recv.exit
    @conn.close
    @conn = nil
  end
  def checknum(head, *args)
    Digest::MD5.hexdigest("[#{head}]_#{args.join('_')}_SCNERO")
  end
  def login(username, password)
    md5 = Digest::MD5.hexdigest(password)
    send(0, username, md5, checknum("LOGINMSG", username, md5), VERSION)
  end
  def upinfo
    send(1, @key, checknum("UPINFOMSG", @session))
  end
  def join(room, password="")
    send(6, @key, room.id, password, checknum("JOINROOMMSG", @session + room.id.to_s + password + "1"),1)
  end
  def qroom(room)
    send(10, @key, room.id, checknum("QROOM", @session + room.id.to_s))
  end
  def action(action)
    send(2, "#{checknum("RMSG", @session)}@#{@key}", "#{action.escape}▊▊▊000000") #TODO:iduel校验字串



  end
  def host(name, password="", lv=0, color = 0)
    send(6, @key, name, password, checknum("JOINROOMMSG", @session + name + password + "0"), 0, color, lv, 0, nil, nil) #TODO:v.ak, v.al
  end
  def watch(room, password="")
    send(5, @key, room.id, password, checknum("WATCHROOMMSG", "#{@session}#{room.id}#{password}"))
  end
  def chat(msg)
    send(4, @key, msg, checknum("CHATP", @session))
    #4|241019,test,2368c6b89b3e2eedb92e1b624a2a157c
  end
  def quitwatchroom
    send("QUITWATCHROOM", @key, checknum("QUITWATCHROOM", @session))
  end
  def quit
    send(11, @key, checknum("ULO", "#{@session}"))
  end
end