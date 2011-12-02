#encoding: UTF-8
#==============================================================================
# Scene_Hall
#------------------------------------------------------------------------------
# 大厅
#==============================================================================

class Scene_Hall_NBX < Scene
  require_relative 'window_playerlist'
  require_relative 'window_userinfo'
  require_relative 'window_roomlist'
  require_relative 'window_chat'
  require_relative 'nbx'
	def start
		$nbx = NBX.new
    $nbx.login(ENV['username'])
		@background = Surface.load "graphics/hall/background.png"
    Surface.blit(@background,0,0,0,0,$screen,0,0)
		@playerlist = Window_PlayerList.new(24,204)
		@userinfo = Window_UserInfo.new(24,24, $nbx.user)
		@roomlist = Window_RoomList.new(320,50)
    @active_window = @roomlist
		@chat = Window_Chat.new(321,551,682,168)
    
    bgm = Mixer::Music.load("audio/bgm/hall.ogg")
    Mixer.fade_in_music(bgm, 800, -1)
    @bgm.destroy if @bgm
    @bgm = bgm
    @count = 0
    super
  end

  def handle(event)
    case event
    when Event::MouseMotion
      if @active_window and @active_window.visible && !@active_window.include?(event.x, event.y)
        @active_window.lostfocus
        @active_window = nil
      end
      self.windows.reverse.each do |window|
        if window.include?(event.x, event.y) && window.visible
          @active_window = window 
          @active_window.mousemoved(event.x, event.y)
          break true
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
      #when Key::F5
      #  if @roomlist.list and room = @roomlist.list.find{|room|room.player1 == $iduel.user or room.player2 == $iduel.user}
      #    $iduel.qroom room
      #  end
      #  $iduel.upinfo
      #when Key::F12
      #  if @roomlist.list and room = @roomlist.list.find{|room|room.player1 == $iduel.user or room.player2 == $iduel.user}
          #$iduel.qroom room
      #  end
        #$iduel.close
      #  $scene = Scene_Login.new
      when Key::F2
        $nbx.host
        @joinroom_msgbox = Widget_Msgbox.new("创建房间", "正在等待对手"){}
      when Key::F5
        $nbx.refresh
      end
    when Event::KeyUp
      case event.sym
      when Key::RETURN
        determine
      end
    when Event::MouseButtonDown
      case event.button
      when Mouse::BUTTON_LEFT
        if @active_window and !@active_window.include? event.x, event.y
          @active_window.lostfocus
          @active_window = nil
        end
        self.windows.reverse.each do |window|
          if @active_window and @active_window.visible && !@active_window.include?(event.x, event.y)
            @active_window = window 
            @active_window.mousemoved(event.x, event.y)
            break
          end
        end
        @active_window.clicked if @active_window
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

  def handle_nbx(event)
    case event
    when NBX::Event::USERONLINE
      if !@playerlist.list.include? event.user
        @playerlist.list << event.user
        @playerlist.list = @playerlist.list #OMG...
      else
        @playerlist.refresh
      end
    when NBX::Event::SingleRoomInfo
      if !@roomlist.list.include? event.room
        @roomlist.list << event.room
        @roomlist.list = @roomlist.list #OMG...
      else
        @roomlist.refresh
      end
    when NBX::Event::Connect
      require_relative 'scene_duel'
      $scene = Scene_Duel.new($nbx.room)
      #
    #when Iduel::Event::OLIF
    #  @playerlist.list = event.users
    #when Iduel::Event::RMIF
    #  @roomlist.list = event.rooms
    #when Iduel::Event::JOINROOMOK
    #  require_relative 'scene_duel'
    #  $scene = Scene_Duel.new(event.room)
    #when Iduel::Event::WATCHROOMSTART
    #  require_relative 'scene_watch'
    #  $scene = Scene_Watch.new(event.room)
    #when Iduel::Event::PCHAT
    #  @chat.add event.user, event.content
    #when Iduel::Event::Error
    #  Widget_Msgbox.new(event.title, event.message){$scene = Scene_Title.new}
    #when Iduel::Event::QROOMOK
    #  @joinroom_msgbox.message = "读取房间信息" if @joinroom_msgbox && !@joinroom_msgbox.destroyed?
    else
      puts "---unhandled iduel event----"
      p event
    end
  end
  
  def update
    super
    while event = NBX::Event.poll
      handle_nbx(event)
    end
  end

  def determine
    case @active_window
    when @roomlist
      return unless @roomlist.index and room = @roomlist.list[@roomlist.index]
      if room.full?
        #$iduel.watch room
        @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入观战"){}
      else
        #$iduel.join room, "test"
        @joinroom_msgbox = Widget_Msgbox.new("加入房间", "正在加入房间"){}
      end
    end
  end
end