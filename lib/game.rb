#encoding: UTF-8

#游戏适配器的抽象类
require_relative 'game_event'
require_relative 'action'
require_relative 'user'
require_relative 'room'
class Game
  attr_reader :users, :rooms
  attr_accessor :user, :room, :player_field, :opponent_field, :turn, :turn_player, :phase
  def initialize
    @users = []
    @rooms = []
  end
  def login(username, password=nil)
  end
  def refresh
  end
  def host
  end
  def join(room)
  end
  def watch(room)
  end
  def leave
  end
  def action(action)
  end
  def chat(chatmessage)
  end
  def exit
  end
  def watching?
    @room and @room.include? @user
  end
end


