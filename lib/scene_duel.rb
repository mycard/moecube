#encoding: UTF-8
#==============================================================================
# Scene_Duel
#------------------------------------------------------------------------------
# 决斗盘的场景
#==============================================================================

class Scene_Duel < Scene
  require_relative 'window_lp'
  require_relative 'window_phases'
  require_relative 'window_field'
  require_relative 'card'
  require_relative 'deck'
  require_relative 'action'
  require_relative 'game_card'
  require_relative 'game_field'
  
	def initialize(room)
		@room = room
  end
  def start
    $iduel.upinfo
    @bgm = Mixer::Music.load "audio/bgm/title.ogg"
    Mixer.fade_in_music(@bgm, 8000, -1)
    @background = Surface.load "graphics/field/main.png"
    Surface.blit(@background, 0, 0, 0, 0, $screen, 0, 0)
    
    @player1_lp = Window_LP.new(0,0, @room.player1, true)
    @player2_lp = Window_LP.new(360,0, @room.player2, false)
    
    @phases_window = Window_Phases.new(124, 357)
    @turn_player = true
    
    @player_field = Game_Field.new(Deck.load("test1.TXT"))
    @opponent_field = Game_Field.new
    
    @player_field_window = Window_Field.new(4, 398, @player_field, true)
    @opponent_field_window = Window_Field.new(4, 60, @opponent_field, false)
    Action.player_field = @player_field
    Action.opponent_field = @opponent_field
    
    $screen.update_rect(0,0,0,0)
  end

  def change_phase(phase)
    if phase == 5
      @turn_player = !@turn_player
      @phase = 0
      @phases_window.player = @turn_player
      Action::Turn_End.new(field)
    else
      @phase = @phases_window.phase = phase
      @phases_window.refresh
    end
  end
  def reset
    Action::Reset.new(true).run
  end
  def first_to_go
    Action::FirstToGo.new(true).run
  end
  def handle(event)
    case event
    when Event::MouseMotion
      @phases_window.mousemoved event.x, event.y
    when Event::MouseButtonDown
      case event.button
      when Mouse::BUTTON_LEFT
        @phases_window.mousemoved event.x, event.y
        @phases_window.clicked
      end
    when Event::MouseButtonUp
      case event.button
      when Mouse::BUTTON_LEFT
        if @phases_window.include? event.x, event.y
          if @turn_player
            @phases_window.mousemoved event.x, event.y
            change_phase(@phases_window.index)
          else
            @phases_window.index = @phase
          end
        end
      end
    when Event::KeyDown
      case event.sym
      when  Key::F1
        suffle
      when Key::F2
        draw
      when Key::F5
        reset
      end
    else
      super
    end
  end
  def handle_iduel(event)
    case event
    when Iduel::Event::Action
      event.action.run
      @player_field_window.refresh
      @opponent_field_window.refresh
    end
  end
  def update
    super
    while event = Iduel::Event.poll
      handle_iduel(event)
    end
  end
  def refresh_rect(x, y, width, height)
    return unless $scene == self #线程的情况
    Surface.blit(@background,x,y,width,height,$screen,x,y) rescue p "------奇怪的nil错误----", @background,x,y,width,height,$screen,x,y
    yield
    $screen.update_rect(x, y, width, height)
  end
end