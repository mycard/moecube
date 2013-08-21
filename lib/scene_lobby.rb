#encoding: UTF-8
#==============================================================================
# Scene_Lobby
#------------------------------------------------------------------------------
# 大厅
#==============================================================================

class Scene_Lobby < Scene
  require_relative 'window_userlist'
  require_relative 'window_userinfo'
  require_relative 'window_roomlist'
  require_relative 'window_chat'
  require_relative 'window_host'
  require_relative 'window_filter'
  require_relative 'window_lobbybuttons'
  require_relative 'chatmessage'
  require_relative 'scene_duel'
  require_relative 'deck_sync'
  attr_reader :chat_window

  def start
    WM::set_caption("MyCard v#{Update::Version} - #{$config['game']} - #{$game.user.name}(#{$game.user.id})", "MyCard")
    $game.refresh
    @background = Graphics.load('lobby', 'background', false)
    Surface.blit(@background, 0, 0, 0, 0, $screen, 0, 0)
    @userlist = Window_UserList.new(24, 204, $game.users)
    @roomlist = Window_RoomList.new(320, 50, $game.rooms)
    @userinfo = Window_UserInfo.new(24, 24, $game.user)
    @host_window = Window_LobbyButtons.new(595, 18)
    @active_window = @roomlist
    @chat_window = Window_Chat.new(313, $config['screen']['height'] - 225, 698, 212)
    @count = 0
    Deck_Sync.start
    super
  end

  def bgm
    "lobby.ogg"
  end

  def handle(event)
    case event
    when Event::KeyDown
      case event.sym
      when Key::UP
        @active_window.cursor_up
      when Key::DOWN
        @active_window.cursor_down
      when Key::F2
        #@joinroom_msgbox = Widget_Msgbox.new("创建房间", "正在等待对手")
        #$game.host Room.new(0, $game.user.name)
      when Key::F3
        #@joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入房间")
        #$game.join 'localhost'
      when Key::F5
        $game.refresh
      when Key::F12
        $game.exit
        $scene = Scene_Login.new
      end
    else
      super
    end
  end

  def handle_game(event)
    case event
    when Game_Event::AllUsers
      @userlist.items = $game.users
      @userinfo.users = $game.users.size
    when Game_Event::AllRooms, Game_Event::AllServers
      @roomlist.items = $game.rooms.find_all { |room|
        $game.filter[:servers].include?(room.server) and
            $game.filter[:waiting_only] ? (room.status == :wait) : true and
            $game.filter[:normal_only] ? (!room.tag? && (room.ot == 0) && (room.lp = 8000)) : true
      }
      @userinfo.rooms = $game.rooms.size
    when Game_Event::Join
      join(event.room)
    when Game_Event::Watch
      require_relative 'scene_watch'
      $scene = Scene_Watch.new(event.room)
    when Game_Event::Chat
      @chat_window.add event.chatmessage
    else
      super
    end
  end

  def join(room)
    $scene = Scene_Duel.new(room)
  end

  def update
    @chat_window.update
    @host_window.update
    @roomlist.update
    if @count >= $game.refresh_interval*60
      $game.refresh
      @count = 0
    end
    @count += 1
    super
  end

  def terminate
    unless $scene.is_a? Scene_Lobby or $scene.is_a? Scene_Duel
      $game.exit
    end
  end
end