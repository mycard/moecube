#encoding: UTF-8

#游戏适配器的抽象类
class Game
  attr_reader :users, :rooms
  attr_accessor :user, :room
  def initialize
    @users = []
    @rooms = []
  end
  def refresh
  end
  def login(username, password=nil)
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
  def exit
  end
end


