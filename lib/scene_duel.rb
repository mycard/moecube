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
  require_relative 'window_fieldback'
  require_relative 'card'
  require_relative 'deck'
  require_relative 'action'
  require_relative 'game_card'
  require_relative 'game_field'
  require_relative 'window_roomchat'
  attr_reader :cardinfo_window
  attr_reader :action_window
  attr_reader :player_field_window
  attr_reader :opponent_field_window
  attr_reader :fieldback_window
	def initialize(room)
    super()
		@room = room
  end
  def start
    $game.refresh if $game
    @bgm = Mixer::Music.load "audio/bgm/title.ogg"
    Mixer.fade_in_music(@bgm, 8000, -1)
    @background = Surface.load "graphics/field/main.png"
    Surface.blit(@background, 0, 0, 0, 0, $screen, 0, 0)
    
    @player1_lp = Window_LP.new(0,0, @room.player1, true)
    @player2_lp = Window_LP.new(360,0, @room.player2, false)
    @phases_window = Window_Phases.new(124, 357)
    @turn_player = true
    
    $game.player_field = Game_Field.new Deck.load("test1.TXT")
    $game.opponent_field = Game_Field.new
    
    @fieldback_window = Window_FieldBack.new(130,174)
    
    @player_field_window = Window_Field.new(4, 398, $game.player_field, true)
    @opponent_field_window = Window_Field.new(4, 60, $game.opponent_field, false)
    @opponent_field_window.angle=180
    
    @cardinfo_window = Window_CardInfo.new(715, 0)
    @player_field_window.action_window = Window_Action.new
    @chat_window = Window_RoomChat.new(@cardinfo_window.x, @cardinfo_window.height, 1024-@cardinfo_window.x, 768-@cardinfo_window.height)
    super
    #(Thread.list - [Thread.current]).each{|t|t.kill}
    #p Thread.list
  end

  def change_phase(phase)
    action Action::ChangePhase.new(@turn_player, [:DP, :SP, :M1, :BP, :M2, :EP][phase])
    
    if phase == 5
      @turn_player = !@turn_player
      @phase = 0
      @phases_window.player = @turn_player
      action Action::Turn_End.new(true, "Turn End", $game.player_field.lp, $game.player_field.hand.size, $game.player_field.deck.size, $game.player_field.graveyard.size, $game.player_field.removed.size, $game.player_field, 1)
    else
      @phase = @phases_window.phase = phase
      @phases_window.refresh
    end
  end
  def reset
    action Action::Reset.new(true)
  end
  def first_to_go
    action Action::FirstToGo.new(true)
  end
  def handle(event)
    case event
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
      when Mouse::BUTTON_RIGHT
        if @player_field_window.action_window
          @player_field_window.action_window.next
        end
      end
    when Event::KeyDown
      case event.sym
      when  Key::F1
        action Action::Shuffle.new
        @player_field_window.refresh
      when Key::F2
        first_to_go
        @player_field_window.refresh
      when Key::F3
        action Action::Dice.new(true)
      when Key::F5
        reset
        @player_field_window.refresh
      end
    else
      super
    end
  end
  
  
  def action(action)
    str = action.escape
    if str =~ /^\[\d+\] (?:●|◎)→(.*)$/m
      str = $1
    end
    $chat_window.add action.from_player, str if action.from_player
    action.run
  end
  
  def handle_game(event)
    case event
    when Game_Event::Action
      str = event.str
      if str =~ /^\[\d+\] (?:●|◎)→(.*)$/m
        str = $1
      end
      $chat_window.add event.action.from_player, str
      action event.action
      @player_field_window.refresh
      @opponent_field_window.refresh
    when Game_Event::Error
      Widget_Msgbox.new(event.title, event.message){$scene = Scene_Title.new}
    end
  end
  def update
    @cardinfo_window.update
    if $game
      while event = Game_Event.poll
        handle_game(event)
      end
    elsif $game
      while event = Game_Event.poll
        handle_game(event)
      end
    end
    super
  end
  def refresh_rect(x, y, width, height)
    return unless $scene == self #线程的情况
    Surface.blit(@background,x,y,width,height,$screen,x,y) rescue p "------奇怪的nil错误----", @background,x,y,width,height,$screen,x,y
    yield
    $screen.update_rect(x, y, width, height)
  end
end