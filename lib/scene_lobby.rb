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
  require_relative 'chatmessage'
  attr_reader :chat_window
  def start
		$game.refresh
		@background = Surface.load("graphics/lobby/background.png").display_format
    Surface.blit(@background,0,0,0,0,$screen,0,0)
		@userlist = Window_UserList.new(24,204,$game.users)
    @roomlist = Window_RoomList.new(320,50,$game.rooms)
		@userinfo = Window_UserInfo.new(24,24, $game.user)
		
    @active_window = @roomlist
		@chat_window = Window_Chat.new(313,543,698,212)
    bgm = Mixer::Music.load("audio/bgm/lobby.ogg")
    Mixer.fade_in_music(bgm, -1, 800)
    @bgm.destroy if @bgm
    @bgm = bgm
    @count = 0
    super
  end

  def handle(event)
    case event
    when Event::KeyDown
      case event.sym
      when Key::UP
        @active_window.cursor_up
      when Key::DOWN
        @active_window.cursor_down
      when Key::RETURN
        @active_window.clicked
      when Key::F2
        $game.host("test")
        @joinroom_msgbox = Widget_Msgbox.new("创建房间", "正在等待对手")
      when Key::F3
        $game.join 'localhost'
        @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入房间")
      when Key::F5
        if @roomlist.items and room = @roomlist.items.find{|room|room.player1 == $game.user or room.player2 == $game.user}
          $game.qroom room
        end
        $game.refresh
      when Key::F12
        if @roomlist.items and room = @roomlist.items.find{|room|room.player1 == $game.user or room.player2 == $game.user}
          $game.qroom room
        end
        $game.exit
        $scene = Scene_Login.new
      end
    when Event::KeyUp
      case event.sym
      when Key::RETURN
        determine
      end
    when Event::MouseButtonUp
      case event.button
      when Mouse::BUTTON_LEFT
        determine
      end
    else
      super
    end
  end

  def handle_game(event)
    case event
    when Game_Event::AllUsers
      @userlist.items = $game.users
    when Game_Event::AllRooms
      @roomlist.items = $game.rooms
    when Game_Event::Join
      require_relative 'scene_duel'
      $scene = Scene_Duel.new(event.room, Deck.load("test1.TXT"))
    when Game_Event::Watch
      require_relative 'scene_watch'
      $scene = Scene_Watch.new(event.room)
    when Game_Event::Chat
      @chat_window.add event.chatmessage
    else
      super
    end
  end
  
  def update
    if @count >= 300
      $game.refresh
      @count = 0
    end
    @count += 1
    super
  end

  def determine
    case @active_window
    when @roomlist
      return unless @roomlist.index and room = @roomlist.items[@roomlist.index]
      if room.full?
        $game.watch room
        @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入观战")
      else
        $game.join room, "test"
        @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入房间")
      end
    end
  end
end