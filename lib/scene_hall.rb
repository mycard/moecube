#==============================================================================
# 鈻�Scene_Hall
#------------------------------------------------------------------------------
# 銆�all
#==============================================================================

class Scene_Hall < Scene
  require_relative 'window_playerlist'
  require_relative 'window_userinfo'
  require_relative 'window_roomlist'

  #require_relative 'window_chat'
	def start
		$iduel.upinfo
    
		@background = Surface.load "graphics/hall/background.png"
    Surface.blit(@background,0,0,0,0,$screen,0,0)
		@playerlist = Window_PlayerList.new(24,200)
		@userinfo = Window_UserInfo.new(24,24, $iduel.user)
		@roomlist = Window_RoomList.new(320,50)
    @active_window = @roomlist
		#@chat = Window_Chat.new(320,550)
    
    $screen.update_rect(0,0,0,0)
    bgm = Mixer::Music.load("audio/bgm/hall.ogg")
    Mixer.fade_in_music(bgm, 800, -1)
    @bgm.destroy if @bgm
    @bgm = bgm
    @count = 0
  end
  def handle(event)
    case event
    when Event::MouseMotion
      [@playerlist, @roomlist].each do |window|
        if window .include? event.x, event.y
          @active_window = window 
          @active_window.mousemoved(event.x, event.y)
          break
        end
      end
    when Event::KeyDown
      case event.sym
      when Key::UP
        @active_window.cursor_up
      when Key::DOWN
        @active_window.cursor_down
      when Key::RETURN
        @active_window.clicked
      when Key::F5
        if @roomlist.list and room = @roomlist.list.find{|room|room.player1 == $iduel.user or room.player2 == $iduel.user}
          $iduel.qroom room
        end
        $iduel.upinfo
      when Key::F12
        if @roomlist.list and room = @roomlist.list.find{|room|room.player1 == $iduel.user or room.player2 == $iduel.user}
          $iduel.qroom room
        end
        $iduel.close
        $scene = Scene_Login.new
      end
    when Event::KeyUp
      case event.sym
      when Key::RETURN
        determine
      end
    when Event::MouseButtonDown
      case event.button
      when Mouse::BUTTON_LEFT
        @active_window.mousemoved(event.x, event.y)
        @active_window.clicked
      when 4
        @active_window.cursor_up
      when 5
        @active_window.cursor_down
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
  def handle_iduel(event)
    case event
    when Iduel::Event::OLIF
      @playerlist.list = event.users
    when Iduel::Event::RMIF
      @roomlist.list = event.rooms
    when Iduel::Event::JOINROOMOK
      require_relative 'scene_duel'
      $scene = Scene_Duel.new(event.room)
    when Iduel::Event::WATCHROOMSTART
      require_relative 'scene_watch'
      $scene = Scene_Watch.new(event.room)
    else
      puts "---unhandled iduel event----"
      p event
    end
  end
  def update
    super
    while event = Iduel::Event.poll
      handle_iduel(event)
    end
    if @count >= 600
      $iduel.upinfo
      @count = 0
    end
    @count += 1
  end
  
  def determine
    case @active_window
    when @roomlist
      return unless @roomlist.index and room = @roomlist.list[@roomlist.index]
      if room.full?
        $iduel.watch room
      else
        $iduel.join room, "test"
      end
    end
  end

end