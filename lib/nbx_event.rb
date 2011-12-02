#encoding: UTF-8
NBX::Event = Class.new #避开SDL::Event问题，所以没有用class NBX::Event::Event
class NBX::Event
  @queue = []
  def self.push(event)
    @queue << event
  end
  def self.poll
    @queue.shift
  end
  def self.parse(info, host=nil)
    if host #来自大厅的udp消息
      info =~ /^(\w*)\|(.*)$/m
      case $1
      when "USERONLINE"
        NBX::Event::USERONLINE
      when "SingleRoomInfo"
        NBX::Event::SingleRoomInfo
      end.new($2, host)
    else #来自房间的消息
      case info
      when /▓SetName:(.*)▓/
        NBX::Event::SetName
      when /\[VerInf\]\|(.*)/
        NBX::Event::VerInf
      when /(\[☆\]开启 游戏王NetBattleX Version  .*\r\n\[.*年.*月.*日禁卡表\]\r\n)▊▊▊.*/
        NBX::Event::Connect
      when /关闭游戏王NetBattleX  .*▊▊▊.*/
        NBX::Event::DisConnect
      when /(\[\d+\] .*▊▊▊.*)/m
        NBX::Event::Action
      else
        p '------unkonwn nbx event--------'
        p info
      end.new($1)
    end
  end
end

class NBX::Event::USERONLINE < NBX::Event
  attr_reader :user#, :session
  def initialize(info, host)
    username, need_reply = info.split(',')
    @user = NBX::User.new(username, host)
    @need_reply = need_reply == "1"
    if @need_reply and @user != $nbx.user
      $nbx.send(@user, 'USERONLINE', $nbx.user.name) 
      if $nbx.room and $nbx.room.player1 == $nbx.user #如果自己是主机
        if $nbx.room.player2
          $nbx.send(@user, "SingleRoomInfo", $nbx.room.player1.name,$nbx.room.player2.name, $nbx.room.player2.host)
        else
          $nbx.send(@user, "SingleRoomInfo", $nbx.room.player1.name)
        end
      end
    end
  end
end
class NBX::Event::RoomConnect
  attr_reader :user
  def initialize(info, host)
    @user = NBX::User.new(info, host)
    $nbx.room.player2 = @user
  end
end
class NBX::Event::SingleRoomInfo < NBX::Event
  attr_reader :room
  def initialize(info, host)
    player1_name, player2_name, player2_host = info.split(',')
    player1 = NBX::User.new(player1_name, host)
    player2 = NBX::User.new(player2_name, player2_host) if player2_name
    @room = NBX::Room.new(player1, player2)
  end
end

class NBX::Event::SetName < NBX::Event
  def initialize(info)
    $nbx.room.player2.name = info
  end
end
class NBX::Event::VerInf < NBX::Event
  def initialize(info)
  end
end
class NBX::Event::Connect < NBX::Event
  def initialize(info)
  end
end
class NBX::Event::DisConnect < NBX::Event
  def initialize(info)
  end
end
class NBX::Event::Action < NBX::Event
  def initialize(info)
    @action = ::Action.parse info
  end
end