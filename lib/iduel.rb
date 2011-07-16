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
  
  def initialize
    require 'socket'
    require 'digest/md5'
    require 'open-uri'
    require_relative 'iduel_action'
    require_relative 'iduel_event'
    @conn = TCPSocket.open(Server, Port)
    @conn.set_encoding "GBK"
    Thread.abort_on_exception = true
    @recv = Thread.new { recv @conn.gets(RS) while @conn  }
  end
  def send(head, *args)
    info = "##{head.to_s(16).upcase}|#{args.join(',')}".encode("GBK") + RS
    puts "<< #{info}"
    (@conn.write info) rescue Iduel::Event.push Event::Error.new(0)
  end
  def recv(info)
    info.chomp!(RS)
    info.encode! "UTF-8"
    puts ">> #{info}"
    Event.push Event.parse info
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
    send(2, "#{checknum("RMSG", @session)}@#{@key}", "#{action.escape}▊▊▊000000") #TODO
  end
  def host(name, password="", lv=0, color = 0)
    send(6, @key, name, password, checknum("JOINROOMMSG", @session + name + password + "0"), 0, color, lv, 0, nil, nil) #TODO:v.ak, v.al
  end
  def watch(room, password="")
    send(5, @key, room.id, password, checknum("WATCHROOMMSG", "#{@session}#{room.id}#{password}"))
  end
  def quitwatchroom
    send("QUITWATCHROOM", @key, checknum("QUITWATCHROOM", @session))
  end
  def quit
    send(11, @key, checknum("ULO", "#{@session}"))
  end
end

class Iduel::User
  @@all = []
  attr_accessor :id, :name, :level, :exp    
  class << self
    alias old_new new
    def new(id, name = "", level = nil, exp = nil)
      if id.is_a? String and id =~ /(.*)\((\d+)\)/
        id = $2.to_i
        name=$1
      else
        id = id.to_i
      end
      user = @@all.find{|user| user.id == id }
      if user
        user.name = name if name
        user.level = level if level
        user.exp = exp if exp
        user
      else
        user = old_new(id, name, level, exp)
        @@all << user
        user
      end
    end
  end
  def initialize(id, name = "", level = nil, exp = nil)
    @id = id
    @name = name
    @level = level
    @exp = exp
  end
  def avatar(size = :small)
    cache = "graphics/avatars/#{@id}_#{size}.png"
    Thread.new do
      open("http://www.duelcn.com/uc_server/avatar.php?uid=#{id-100000}&size=#{size}", 'rb') do |io|
        open(cache, 'wb') {|c|c.write io.read}
      end rescue Thread.exit
      yield Surface.load cache
    end rescue p("http://www.duelcn.com/uc_server/avatar.php?uid=#{id-100000}&size=#{size}") if block_given?
    Surface.load cache rescue Surface.load "graphics/avatars/noavatar_#{size}.gif"
  end
end

class Iduel::Room
  @@all = []
  attr_accessor :id, :name, :player1, :player2, :private, :color
  class << self
    alias old_new new
    def new(id, *args)
      id = id.to_i
      room = @@all.find{|room| room.id == id }
      if room
        room
      else
        room = old_new(id, *args)
        @@all << room
        room
      end
    end
  end
  def initialize(id, name, player1, player2, private, color, session = nil, forbid = nil)
    @id =id
    @name = name
    @player1 = player1
    @player2 = player2
    @private = private
    @color = color
    @forbid = forbid
    @session = session
  end
  alias full? player2
  alias private? private
end