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
    @background = Surface.load "graphics/frm/frmmain.png"
    Surface.blit(@background, 0, 0, 0, 0, $screen, 0, 0)
    
    @player1_lp = Window_LP.new(0,0, @room.player1, true)
    @player2_lp = Window_LP.new(360,0, @room.player2, false)
    
    @phases_window = Window_Phases.new(124, 357)
    @turn_player = true
    
    @player = Game_Field.new(Deck.load("test1.TXT"))
    @opponent = Game_Field.new
    
    @player_field_window = Window_Field.new(4, 398, @player)
    Action.player_field = @player
    Action.opponent_field = @opponent
    
    $screen.update_rect(0,0,0,0)
  end
  
  def change_phase(phase)
    if phase == 5
      @turn_player = !@turn_player
      @phase = 0
      @phases_window.player = @turn_player
    else
      @phase = @phases_window.phase = phase
      @phases_window.refresh
    end
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
      else
        super
      end
    end
  end
  def handle_iduel(event)
    case event
    when Iduel::Event::UMSG
      event.action.do
      @player_field_window.refresh
    end
  end
  def update
    super
    while event = Iduel::Event.poll
      handle_iduel(event)
    end
  end
end