class Game_Event
  def self.parse(header, data)
    case header
    #when :login
    #  if data
    #    Login.new parse_user data
    #  else
    #    Error.new('登录', '用户名或密码错误')
    #  end
    #when :rooms
      #AllRooms.new data.collect{|room|parse_room(room)}
    #when :rooms_update
      #RoomsUpdate.new data.collect{|room|parse_room(room)}
    #when :servers
    #  servers = data.collect{|server|parse_server(server)}
    #  $game.filter[:servers].concat (servers - $game.servers)
    #  AllServers.new servers
    #when :newuser
      #NewUser.new parse_user data
    #when :missinguser
      #MissingUser.new parse_user data
    #when :newroom
     # NewRoom.new parse_room data
    #when :missingroom
     # MissingRoom.new parse_room data
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
    result = Room.new(room['id'], room['name'])
    result.private = room['private']
    result.pvp = room['pvp']
    result.match = room['mode'] == 1
    result.tag = room['mode'] == 2
    result.ot = room['rule'] || 0
    result.status = room['status'].to_sym
    result.lp = room['start_lp'] || 8000

    result.player1 = room['users'][0] && parse_user(room['users'][0])
    result.player2 = room['users'][1] && parse_user(room['users'][1])

    result.server = Server.find room['server_id']

    result._deleted = room['_deleted']
    result
  end
  def self.parse_user(user)
    User.new(user['id'] || user[:id], user['name'] || user[:name], user['certified'] || user[:certified])
  end
  def self.parse_server(server)
    Server.new(server[:id], server[:name], server[:ip], server[:port], server[:auth])
  end
end
