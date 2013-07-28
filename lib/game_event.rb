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
      @users = []
      users.each do |user|
        if user.friend?
          @users.unshift user
        else
          @users << user
        end
      end
      $game.users.replace @users
    end
  end

  class AllServers < Game_Event
    attr_reader :servers

    def initialize(servers)
      $game.servers.replace servers
    end
  end

  class NewUser < AllUsers
    attr_reader :users

    def initialize(user)
      @user = user
      case @user.affiliation
      when :owner
        if index = $game.users.find_index { |user| user.affiliation != :owner }
          $game.users.insert(index, @user)
        else
          $game.users << @user
        end
      when :admin
        if index = $game.users.find_index { |user| user.affiliation != :owner and user.affiliation != :admin }
          $game.users.insert(index, @user)
        else
          $game.users << @user
        end
      else
        $game.users << @user
      end
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
      $game.rooms.sort_by! { |room| [room.status == :start ? 1 : 0, room.private ? 1 : 0, room.id] }
    end

  end
  class RoomsUpdate < AllRooms
    attr_reader :rooms

    def initialize(rooms)
      @rooms = rooms
      $game.rooms.replace $game.rooms | @rooms
      $game.rooms.delete_if { |room| room._deleted }
      $game.rooms.sort_by! { |room| [room.status == :start ? 1 : 0, room.private ? 1 : 0, room.id] }
    end
  end
  class NewRoom < AllRooms
    attr_reader :room

    def initialize(room)
      @room = room
      unless $game.rooms.include? @room
        if @room.full?
          $game.rooms << @room
        else
          $game.rooms.unshift @room
        end
      end
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
    attr_reader :chatmessage

    def initialize(chatmessage)
      @chatmessage = chatmessage
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
    attr_reader :title, :message, :fatal

    def initialize(title, message, fatal=true)
      @title = title
      @message = message
      @fatal = fatal
      $log.error(@fatal ? "致命错误" : "一般错误") { "#{@title}: #{@message} #{caller}" }
    end
  end
  class Unknown < Error
    def initialize(*args)
      super("unknown event", args.inspect)
    end
  end
end