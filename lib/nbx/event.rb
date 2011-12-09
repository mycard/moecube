#encoding: UTF-8

class Game_Event
  def self.parse(info, host=nil)
    result = (if host #来自大厅的udp消息
      info =~ /^(\w*)\|(.*)$/m
      case $1
      when "NewUser"
        NewUser
      when "NewRoom"
        NewRoom
      when "MissingUser"
        MissingUser
      when "MissingRoom"
        MissingRoom
      else
        Error
      end.parse($2, host)
    else #来自房间的消息
      case info
      when /▓SetName:(.*)▓/
        NewUser
      when /\[VerInf\]|\[LinkOK\]\|(.*)/
        VerInf
      when /(\[☆\]开启 游戏王NetBattleX Version  .*\r\n\[.*年.*月.*日禁卡表\]\r\n)▊▊▊.*/
        PlayerJoin
      when /关闭游戏王NetBattleX  .*▊▊▊.*/
        PlayerLeave
      when /(\[\d+\] .*|(?:#{::Action::CardFilter}\r\n)*)▊▊▊.*/m
        Action
      else
        Error
      end.parse($1)
    end)
    p info, result
    result
  end


  class NewUser
    def self.parse(info, host=$game.room.player2.id)
      username, need_reply = info.split(',')
      username = "对手" if username.nil? or username.empty?
      user = User.new(host, username)
      need_reply = need_reply == "1"
      if need_reply and user != $game.user  #忽略来自自己的回复请求
        $game.send(user, 'NewUser', $game.user.name) 
        if $game.room and $game.room.player1 == $game.user #如果自己是主机
          if $game.room.player2
            $game.send(user, "NewRoom", $game.room.player1.name,$game.room.player2.name, $game.room.player2.host)
          else
            $game.send(user, "NewRoom", $game.room.player1.name)
          end
        end
      end
      self.new user
    end
  end
  class NewRoom
    attr_reader :room
    def self.parse(info, host)
      player1_name, player2_name, player2_host = info.split(',')
      player1 = User.new(player1_name, host)
      player2 = User.new(player2_name, player2_host) if player2_name
      self.new Room.new(player1.id, player1.name, player1, player2)
    end
  end

  class PlayerJoin
    def self.parse(info)
      #$game.room.player2.name = info
      #self.new $game.room.player2
    end
  end
  class PlayerLeave
  end
  class Action
    def self.parse(info)
      self.new ::Action.parse(info), info
    end
  end
  class VerInf
    def self.parse(info)
      
    end
  end
end
