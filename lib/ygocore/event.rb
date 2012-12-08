class Game_Event
  def self.parse(header, data)
    case header
    when :login
      if data
        Login.new parse_user data
      else
        Error.new('登录', '用户名或密码错误')
      end
    when :rooms
      AllRooms.new data.collect{|room|parse_room(room)}
    when :rooms_update
      RoomsUpdate.new data.collect{|room|parse_room(room)}
    when :servers
      servers = data.collect{|server|parse_server(server)}
      $game.filter[:servers].concat (servers - $game.servers)
      AllServers.new servers
    #when :newuser
      #NewUser.new parse_user data
    #when :missinguser
      #MissingUser.new parse_user data
    when :newroom
      NewRoom.new parse_room data
    when :missingroom
      MissingRoom.new parse_room data
    when :chat
      case data[:channel]
      when :lobby
        Chat.new ChatMessage.new User.new(data[:from][:id],data[:from][:name]), data[:message], :lobby
      else
        Chat.new ChatMessage.new User.new(data[:from][:id],data[:from][:name]), data[:message], User.new(data[:channel])
      end
    end
  end
  def self.parse_room(room)
    result = Room.new(room[:id], room[:name])
    result.player1 = room[:player1] && parse_user(room[:player1])
    result.player2 = room[:player2] && parse_user(room[:player2])
    result.private = room[:private]
    result.pvp = room[:pvp]
    result.match = room[:match]
    result.tag = room[:tag]
    result.ot = room[:ot]
    result.status = room[:status]
    result.lp = room[:lp]
    result._deleted = room[:_deleted]
    result.server_id = room[:server_id]
    result.server_ip = room[:server_ip]
    result.server_port = room[:server_port]
    result.server_auth = room[:server_auth]
    result
  end
  def self.parse_user(user)
    User.new(user[:id], user[:name], user[:certified])
  end
  def self.parse_server(server)
    Server.new(server[:id], server[:name], server[:ip], server[:port], server[:auth])
  end
end
