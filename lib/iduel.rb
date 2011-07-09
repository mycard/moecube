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
    @conn = TCPSocket.open(Server, Port)
    @conn.set_encoding "GBK"
    Thread.abort_on_exception = true
    @recv = Thread.new { (recv(@last_info) while @last_info = @conn.gets(RS)) rescue Iduel::Event.push Event::Error.new(0)}
    #at_exit{($iduel.qroom(Iduel::Room.new(1,1,1,1,1,1,1));$iduel.quit) if $iduel}
  end
  def send(head, *args)
    info = "##{head.to_s(16).upcase}|#{args.join(',')}".encode("GBK") + RS
    puts ">> #{info}"
    (@conn.write info) rescue Iduel::Event.push Event::Error.new(0)
  end
  def recv(info)
    info.chomp!(RS)
    info.encode! "UTF-8"
    puts ">> #{info}"
    info =~ /^\$([A-Z])\|(.*)$/m
		#建立房间
    #$F|253￠
    #$R|￠
    #$Q|253,2,zh99998(201448),1￠
    #加入房间
    #$M||￠
    #$F|256￠
    #$R|￠
    #$Q|256,1,zh99997(201629),zh99998(201448)￠
 


    Event.push case $1
    when "A"
      Event::Error
    when "B"
      Event::LOGINOK
    when "C"
      Event::OLIF
    when "F"
      Event::JOINROOMOK
    when "G"
      Event::WATCHROOMSTART
    when "J"
      Event::UMSG
    when "K"
      Event::WMSG
    when "M"
      Event::QROOMOK  #TODO
    when "O"
      Event::PCHAT
    when "P"
      Event::RMIF
    when "Q"
      Event::SingleRoomInfo
    when "R"
      Event::QROOMOK  #卡表
    else
      p $1, $2
      system("pause")
      Event::UNKNOWN
    end.new($2)
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
  
  Event = Class.new{@queue = []}
  class <<Event
    
    def push(event)
      @queue << event
    end
    def poll
      @queue.shift
    end
  end
  class Event::LOGINOK < Event
    attr_reader :user, :session
    def initialize(info)
      info = info.split(",")
      #>> $B|201629,zh99997,5da9e5fa,Level-1 (总经验:183),,20101118
      info[3] =~ /Level-(\d)+ \(总经验:(\d+)\)/
      $iduel.user = @user = User.new(info[0].to_i, info[1], $1.to_i, $2.to_i)
      $iduel.session = @session = info[2]
      $iduel.key = ($iduel.user.id - 0x186a0) ^ 0x22133
      
    end
  end
  class Event::OLIF < Event
    attr_reader :users
    def initialize(info)
      @users = info.split(',').collect do |user|
        Iduel::User.new(user)
      end
    end
  end
  class Event::RMIF < Event
    attr_reader :rooms
    def initialize(info)
      info = info.split("|")
      @rooms = []
      templist = @rooms
      empty = false
      info.each do |room|
        if room == '~~'
          empty = true
          templist = []
        else
          room = room.split(",")
          templist << if empty
            Iduel::Room.new(room[0].to_i, room[1], Iduel::User.new(room[2]), nil, room[3]=="1", Iduel::Color[room[4].to_i], nil, room[6])
          else
            Iduel::Room.new(room[0].to_i, room[3], Iduel::User.new(room[1]), Iduel::User.new(room[2]), false, Iduel::Color[room[5].to_i], room[3])
          end
        end
      end
      @rooms = templist + @rooms
    end
  end
  class Event::NOL < Event
    def initialize(info)
      super
      @args = @args.collect do |user|
        Iduel::User.new(user)
      end
    end
  end
  class Event::DOL < Event
    def initialize(info)
      super
      @args = @args.collect do |user|
        Iduel::User.new(user)
      end
    end
  end
  class Event::PCHAT < Event
    attr_reader :user, :content
    def initialize(info)
      user, @content = info.split(",", 2)
      @user = Iduel::User.new user
    end
  end
  class Event::JOINROOMOK < Event
    attr_reader :room
    def initialize(id)
      @room = Iduel::Room.new(id)
    end
  end
  class Event::QROOMOK < Event
  end
  class Event::SingleRoomInfo < Event
    def initialize(info)
      id, x, player1, player2 = info.split(",", 4)
      @room = Room.new(id)
      @room.player1 = User.new(player1)
      @room.player2 = User.new(player2)
    end
  end
  #"Q"
  #"273,1,zh99998(201448),zh99997(201629)"
  class Event::WATCHROOMSTART < Event
    def initialize(info)
      id, name = info.split(",", 1)
      @room = Iduel::Room.new(id.to_i, name, '', '', false, Color[0])#:name, :player1, :player2, :crypted, :color
    end
  end
  class Event::UMSG < Event
    attr_reader :action
    def initialize(info)
      @action = Action.parse info
      p @action
    end
  end
  class Event::WMSG < Event
    def initialize(info)
      #black_st(212671), [109] ┊墓地，苍岩┊
      #p info
        
      #p $1, $2
      info =~ /(.+)\((\d+)\), \[(\d+)\] (.*)/m #cchenwor(211650), [27] ◎→<[效果怪兽][盟军·次世代鸟人] 1400 400>攻击8
      @args = [$1, $2, $3, $4]
    end
  end
  class Event::WATCHSTOP < Event
  end
  class Event::Error < Event
    def initialize(info)
      @title, @message = case info.to_i
      when 0x00
        ["网络错误", "网络连接中断"]
      when 0x65
        ["出错啦~", "服务器程序出现未知错误，请记录好出现错误的事件，并联系管理员。"]
      when 0x66
        ["错误", "通信验证错误"]
      when 0x67
        ["错误", "通信钥匙错误"]
      when 0xc9
        ["登录失败", "错误的帐号名或密码"]
      when 0xca
        ["登录失败", "你的账号还未激活"]
      when 0xcb
        ["登录失败", "你的账号被系统封锁"]
      when 0x12d
        ["错误", "房间已满"]
      when 0x12e
        ["错误", "房间密码错误"]
      when 0x12f
        ["错误", "你没有权限给房间上密码"]
      when 0x130
        ["错误", "你已经加入房间，请不要重新加入"]
      when 0x131
        ["加入房间", "你未达到房间要求的等级限制。"]
      when 0x132
        ["观战错误", "所请求的房间无效，或未开始决斗"]
      when 0x133
        ["观战错误", "你已经在该房间观战"]
      when 0x134
        ["发送信息错误", "你还未加入房间"]
      when 0x135
        ["错误", "请求的房间无效"]
      end
      #Exception.new(@message).raise
      puts @title.encode! "GBK"
      puts @message.encode! "GBK"
      #system("pause")
    end
  end
  class Event::UNKNOWN < Event
    def initialize(*args)
      #puts "Unknown Server Return:#{@last_info}:#{args.inspect}"
    end
  end
end
__END__
$conn = Iduel.new
$conn.login "zh99997", "111111"
loop{$conn.update;sleep 0.1}
$conn.joinroom 221, "zh" unless $conn.room_id
p $conn.room_id
sleep 5
puts "-----------------END----------------"
while c = @conn.getc
  print c
end
