#encoding: UTF-8
class Game_Event
  def self.parse(info)
    info =~ /^\$([A-Z])\|(.*)$/m
    case $1
    when "A"
      Error
    when "B"
      Login
    when "C"
      AllUsers
    when "F"
      Join
    when "G"
      Watch
    when "H"
      Leave
    when "J"
      Action
    when "K"
      WatchAction
    when "M"
      Leave
    when "O"
      Chat
    when "P"
      AllRooms
    when "Q"
      NewRoom
    when "R"
      QROOMOK  #卡表
    else
      Unknown
    end.parse($2)
  end

  
  class Login
    def self.parse(info)
      info = info.split(",")
      #>> $B|201629,zh99997,5da9e5fa,Level-1 (总经验:183),,20101118
      info[3] =~ /Level-(\d)+ \(总经验:(\d+)\)/
      result = self.new User.new(info[0].to_i, info[1], $1.to_i, $2.to_i)
      $game.session = info[2]
      $game.key = ($game.user.id - 0x186a0) ^ 0x22133
      result
    end
  end
  class AllUsers
    def self.parse(info)
      self.new info.split(',').collect{|user|User.parse(user)}
    end
  end
  class AllRooms
    def self.parse(info)
      info = info.split("|")
      rooms = []
      templist = rooms
      empty = false
      info.each do |room|
        if room == '~~'
          empty = true
          templist = []
        else
          room = room.split(",")
          templist << if empty
            Room.new(room[0].to_i, room[1], User.parse(room[2]), nil, room[3]=="1", Room::Color[room[4].to_i], nil, room[6])
          else
            Room.new(room[0].to_i, room[3], User.parse(room[1]), User.parse(room[2]), false, Room::Color[room[5].to_i], room[3])
          end
        end
      end
      rooms = templist + rooms
      self.new rooms
    end
  end
  class NewUser
    def self.parse(info)
      p info
      #super
      #@args = @args.collect do |user|
      #  User.new(user)
      #end
    end
  end
  class MissingUser
    def self.parse(info)
      p info
      #super
      #@args = @args.collect do |user|
      #  User.new(user)
      #end
    end
  end

  class Join
    def self.parse(info)
      self.new Room.new(info.to_i)
    end
  end
  class Leave
    def self.parse(info)
      self.new
    end
  end
  class NewRoom
    def self.parse(info)
      id, x, player1, player2 = info.split(",", 4)
      room = Room.new(id.to_i)
      room.player1 = User.parse(player1)
      room.player2 = User.parse(player2)
      self.new room
    end
  end
  #"Q"
  #"273,1,zh99998(201448),zh99997(201629)"
  class Watch
    attr_reader :room
    def self.parse(info)
      id, name = info.split(",", 2)
      self.new Room.new(id.to_i, name)
    end
  end
  class Action
    attr_reader :action
    def self.parse(info)
      info =~ /(.*)▊▊▊.*?$/m
      info = $1
      info["◎"] = "●" if info["◎"]
      self.new ::Action.parse(info), info
    end
  end
  class Leave
  end
  class Chat
    attr_reader :user, :content
    alias old_initialize initialize
    def self.parse(info)
      user, content = info.split(",", 2)
      user = user == "System" ? User.new(100000, "iDuel管理中心") : User.parse(user)
      self.new(user, content, :hall)
    end
  end
  class Error
    attr_reader :title, :message
    def self.parse(info)
      title, message = case info.to_i
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
      self.new title, message
    end
  end
  class Unknown
    def self.parse(*args)
      $log.info  '--------Unknown Iduel Event-------'
      p $1, $2, args
    end
  end
  
  
  
  
  #以下iduel专有
  class WatchAction < Action
    attr_reader :user
    def initialize(action, str, user)
      @user = user
      super(action, str)
      @action.from_player = @user == $game.room.player1
    end
    def self.parse(info)
      info =~ /(.+)\((\d+)\), (.*)/m
      self.new ::Action.parse($3), $3, User.new($2.to_i, $1)
    end
  end
  class QROOMOK < Game_Event
    def self.parse(info)
    end
  end
end