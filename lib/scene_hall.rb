#encoding: UTF-8
#==============================================================================
# Scene_Hall
#------------------------------------------------------------------------------
# 大厅
#==============================================================================

class Scene_Hall < Scene
  require_relative 'window_userlist'
  require_relative 'window_userinfo'
  require_relative 'window_roomlist'
  require_relative 'window_chat'
	def start
		$game.refresh
		@background = Surface.load "graphics/hall/background.png"
    Surface.blit(@background,0,0,0,0,$screen,0,0)
		@userlist = Window_UserList.new(24,204,$game.users)
    @roomlist = Window_RoomList.new(320,50,$game.rooms)
		@userinfo = Window_UserInfo.new(24,24, $game.user)
		
    @active_window = @roomlist
		@chat = Window_Chat.new(321,551,682,168)
    
    bgm = Mixer::Music.load("audio/bgm/hall.ogg")
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
        $game.join '192.168.0.103'
        @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入房间")
      when Key::F5
        if @roomlist.list and room = @roomlist.list.find{|room|room.player1 == $game.user or room.player2 == $game.user}
          $game.qroom room
        end
        $game.refresh
      when Key::F12
        if @roomlist.list and room = @roomlist.list.find{|room|room.player1 == $game.user or room.player2 == $game.user}
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
      @userlist.list = $game.users
    when Game_Event::AllRooms
      @roomlist.list = $game.rooms
    when Game_Event::Join
      require_relative 'scene_duel'
      $scene = Scene_Duel.new(event.room, Deck.load("test1.TXT"))
    when Game_Event::Watch
      require_relative 'scene_watch'
      $scene = Scene_Watch.new(event.room)
    when Game_Event::Chat
      @chat.add event.user, event.content
    when Game_Event::Error
      Widget_Msgbox.new(event.title, event.message){$scene = Scene_Title.new}
      #when Game_Event::QROOMOK
      #  @joinroom_msgbox.message = "读取房间信息" if @joinroom_msgbox && !@joinroom_msgbox.destroyed?
    else
      $log.info  "---unhandled game event----"
      $log.debug event
    end
  end
  
  def update
    while event = Game_Event.poll
      handle_game(event)
    end
    if @count >= 600
      $game.refresh
      @count = 0
    end
    @count += 1
    super
  end

  def determine
    case @active_window
    when @roomlist
      return unless @roomlist.index and room = @roomlist.list[@roomlist.index]
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