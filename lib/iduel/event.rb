#encoding: UTF-8
Game_Event = Class.new #避开SDL::Event问题，所以没有用class Game_Event::Event
class Game_Event
  @queue = []
  def self.push(event)
    @queue << event
  end
  def self.poll
    @queue.shift
  end
  def self.parse(info)
    info =~ /^\$([A-Z])\|(.*)$/m
    case $1
    when "A"
      Game_Event::Error
    when "B"
      Game_Event::LOGINOK
    when "C"
      Game_Event::AllUsers
    when "F"
      Game_Event::JOINROOMOK
    when "G"
      Game_Event::WATCHROOMSTART
    when "J"
      Game_Event::Action
    when "K"
      Game_Event::WMSG
    when "M"
      Game_Event::QROOMOK  #TODO
    when "O"
      Game_Event::PCHAT
    when "P"
      Game_Event::AllRooms
    when "Q"
      Game_Event::NewRoom
    when "R"
      Game_Event::QROOMOK  #卡表
    else
      Game_Event::UNKNOWN
    end.new($2)
  end
end
  
class Game_Event::LOGINOK < Game_Event
  attr_reader :user, :session
  def initialize(info)
    info = info.split(",")
    #>> $B|201629,zh99997,5da9e5fa,Level-1 (总经验:183),,20101118
    info[3] =~ /Level-(\d)+ \(总经验:(\d+)\)/
    $game.user = @user = Iduel::User.new(info[0].to_i, info[1], $1.to_i, $2.to_i)
    $game.session = @session = info[2]
    $game.key = ($game.user.id - 0x186a0) ^ 0x22133
  end
end
class Game_Event::AllUsers < Game_Event
  attr_reader :users
  def initialize(info)
    @users = info.split(',').collect do |user|
      Iduel::User.new(user)
    end
  end
end
class Game_Event::AllRooms < Game_Event
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
    $game.rooms = @rooms
  end
end
class Game_Event::NOL < Game_Event
  def initialize(info)
    super
    @args = @args.collect do |user|
      Iduel::User.new(user)
    end
  end
end
class Game_Event::DOL < Game_Event
  def initialize(info)
    super
    @args = @args.collect do |user|
      Iduel::User.new(user)
    end
  end
end
class Game_Event::PCHAT < Game_Event
  attr_reader :user, :content
  def initialize(info)
    user, @content = info.split(",", 2)
    @user = user == "System" ? Iduel::User.new(100000, "iDuel管理中心") : Iduel::User.new(user)
  end
end
class Game_Event::JOINROOMOK < Game_Event
  attr_reader :room
  def initialize(id)
    @room = Iduel::Room.new(id)
  end
end
class Game_Event::QROOMOK < Game_Event
end
class Game_Event::NewRoom < Game_Event
  def initialize(info)
    id, x, player1, player2 = info.split(",", 4)
    @room = Iduel::Room.new(id)
    @room.player1 = Iduel::User.new(player1)
    @room.player2 = Iduel::User.new(player2)
    $game.rooms << @room unless $game.rooms.include? @room
  end
end
#"Q"
#"273,1,zh99998(201448),zh99997(201629)"
class Game_Event::WATCHROOMSTART < Game_Event
  attr_reader :room
  def initialize(info)
    id, name = info.split(",", 1)
    @room = Iduel::Room.new(id.to_i, name, '', '', false, Iduel::Color[0])#:name, :player1, :player2, :crypted, :color
  end
end
class Game_Event::Action < Game_Event
  attr_reader :action
  def initialize(info)
    info["◎"] = "●" if info =~ /^\[\d+\] (?:.*\r\n){0,1}(◎)→.*▊▊▊.*$/
    @action = ::Action.parse info
    p @action
  end
end
class Game_Event::WMSG < Game_Event
  def initialize(info)
    #black_st(212671), [109] ┊墓地，苍岩┊
    #p info
        
    #p $1, $2
    info =~ /(.+)\((\d+)\), \[(\d+)\] (.*)/m #cchenwor(211650), [27] ◎→<[效果怪兽][盟军·次世代鸟人] 1400 400>攻击8
    @args = [$1, $2, $3, $4]
  end
end
class Game_Event::WATCHSTOP < Game_Event
end
class Game_Event::Error < Game_Event
  attr_reader :title, :message
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
    p caller
    p @title
    p @message
    #system("pause")
  end
end
class Game_Event::UNKNOWN < Game_Event
  def initialize(*args)
    puts '--------UnKnown Iduel Event-------'
    p $1, $2, args
    system("pause")
  end
end