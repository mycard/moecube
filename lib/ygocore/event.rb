class Game_Event
  def self.parse(header, data)
    case header
    when :login
      if data
        Login.new User.new(data[:id], data[:name])
      else
        Error.new('登录', '用户名或密码错误')
      end
    when :users
      AllUsers.new data.collect{|user|User.new(user[:id], user[:name], user[:certified])}
    when :rooms
      AllRooms.new data.collect{|room|
        result = Room.new(room[:id], room[:name])
        result.player1 = room[:player1] && User.new(room[:player1][:id], room[:player1][:name])
        result.player2 = room[:player2] && User.new(room[:player2][:id], room[:player2][:name])
        result.pvp = room[:pvp]
        result.match = room[:match]
        result.status = room[:status]
        result
      }.sort_by{|room|room.full? ? 1 : 0}
    when :chat
      case data[:channel]
      when :lobby
        Chat.new ChatMessage.new User.new(data[:from][:id],data[:from][:name]), data[:message], :lobby
      else
        Chat.new ChatMessage.new User.new(data[:from][:id],data[:from][:name]), data[:message], User.new(data[:channel])
      end
    end
  end
end