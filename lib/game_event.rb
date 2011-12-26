#encoding: UTF-8

#游戏事件的抽象类
class Game_Event
  @queue = []
  def self.push(event)
    @queue << event
  end
  def self.poll
    @queue.shift
  end
  def self.parse(info, *args)
    #适配器定义
  end


  class Login < Game_Event
    attr_reader :user
    def initialize(user)
      @user = user
      $game.user = @user
    end
  end
  
  class AllUsers < Game_Event
    attr_reader :users
    def initialize(users)
      @users = users
      $game.users.replace @users
    end
  end
  
  class NewUser < AllUsers
    attr_reader :users
    def initialize(user)
      @user = user
      $game.users << @user unless $game.users.include? @user
    end
  end

  class MissingUser < AllUsers
    attr_reader :users
    def initialize(user)
      @user = user
      $game.users.delete @user
    end
  end

  class AllRooms < Game_Event
    attr_reader :rooms
    def initialize(rooms)
      @rooms = rooms
      $game.rooms.replace @rooms
    end
  end
  
  class NewRoom < AllRooms
    attr_reader :room
    def initialize(room)
      @room = room
      $game.rooms << @room unless $game.rooms.include? @room
    end
  end

  class MissingRoom < AllRooms
    attr_reader :room
    def initialize(room)
      @room = room
      $game.rooms.delete @room
    end
  end



  class Chat < Game_Event
    attr_reader :user, :content, :channel
    def initialize(user, content, channel=:hall)
      @user = user
      @content = content
      @channel = channel
      @time = Time.now
    end
  end

  class Join < Game_Event
    attr_reader :room
    def initialize(room)
      @room = room
      $game.room = @room
    end
  end
  class Host < Join
  end
  class Watch < Game_Event
    attr_reader :room
    def initialize(room)
      @room = room
      $game.room = @room
    end
  end
  class Leave < Game_Event
    def initialize
    end
  end
  class PlayerJoin < Game_Event
    attr_reader :user
    def initialize(user)
      @user = user
      $game.room.player2 = @user
    end
  end
  class PlayerLeave < Game_Event
    def initialize
      $game.room.player2 = nil
    end
  end

  class Action < Game_Event
    attr_reader :action, :str
    def initialize(action, str=action.escape)
      @action = action
      @str = str
    end
  end


  class Error < Game_Event
    attr_reader :title, :message
    def initialize(title, message)
      @title = title
      @message = message
      $log.info  @title
      $log.info  @message
    end
  end
  class Unknown < Error
    def initialize(*args)
      super("unknown event", args.inspect)
    end
  end
end