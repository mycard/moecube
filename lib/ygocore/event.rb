class Game_Event
  def self.parse(header, data)
    case header
    when :login
      if data
        Login.new parse_user data
      else
        Error.new('登录', '用户名或密码错误')
      end
    when :users
      AllUsers.new data.collect{|user|parse_user(user)}
    when :rooms
      rooms_wait = []
      rooms_start = []
      data.each do |room|
        room = parse_room(room)
        if room.full?
          rooms_start << room
        else
          rooms_wait << room
        end
      end
      AllRooms.new rooms_wait + rooms_start
    when :newuser
      NewUser.new parse_user data
    when :missinguser
      MissingUser.new parse_user data
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
    result.pvp = room[:pvp]
    result.match = room[:match]
    result.status = room[:status]
    result
  end
  def self.parse_user(user)
    User.new(user[:id], user[:name], user[:certified])
  end
end
