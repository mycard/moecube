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
  require_relative 'replay'
  require_relative 'game_card'
  require_relative 'game_field'
  require_relative 'window_roomchat'
  attr_reader :cardinfo_window
  attr_reader :action_window
  attr_reader :player_field_window
  attr_reader :opponent_field_window
  attr_reader :fieldback_window
	def initialize(room, deck=nil)
    super()
		@room = room
    @deck = deck
  end
  def start
    $game.refresh if $game
    @bgm = Mixer::Music.load "audio/bgm/title.ogg"
    Mixer.fade_in_music(@bgm, 8000, -1)
    @background = Surface.load "graphics/field/main.png"
    Surface.blit(@background, 0, 0, 0, 0, $screen, 0, 0)
    
    init_game
    init_replay
    
    @player_lp_window = Window_LP.new(0,0, @room.player1, true)
    @opponent_lp_window = Window_LP.new(360,0, @room.player2, false)
    @player_field_window = Window_Field.new(4, 398, $game.player_field, true)
    @opponent_field_window = Window_Field.new(4, 60, $game.opponent_field, false)
    @opponent_field_window.angle=180
    
    @phases_window = Window_Phases.new(124, 357)
    @fieldback_window = Window_FieldBack.new(130,174)
    @cardinfo_window = Window_CardInfo.new(715, 0)
    
    @chat_window = Window_RoomChat.new(@cardinfo_window.x, @cardinfo_window.height, 1024-@cardinfo_window.x, 768-@cardinfo_window.height)
    create_action_window
    
    super
  end
  def create_action_window
    @player_field_window.action_window = Window_Action.new
  end
  def init_replay
    @replay = Replay.new
  end
  def save_replay
    @replay.save if @replay
  end
  def init_game
    $game.player_field = Game_Field.new @deck
    $game.opponent_field = Game_Field.new
    $game.turn_player = true #
    $game.turn = 0
  end
  def change_phase(phase)
    action Action::ChangePhase.new(true, phase)
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
          @phases_window.mousemoved event.x, event.y
          change_phase(Window_Phases::Phases[@phases_window.index])
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
    Game_Event.push Game_Event::Action.new(action)
  end
  
  def handle_game(event)
    case event
    when Game_Event::Action
      if event.action.instance_of?(Action::Reset) and event.action.from_player
        save_replay
        init_replay
      end
      @replay.add event.str
      str = event.str
      if str =~ /^\[\d+\] (?:●|◎)→(.*)$/m
        str = $1
      end
      $chat_window.add event.action.from_player, str
      event.action.run
      @player_field_window.refresh
      @opponent_field_window.refresh
      @phases_window.player = $game.turn_player
      @phases_window.phase = $game.phase
      @fieldback_window.card = $game.player_field.field[0] || $game.opponent_field.field[0]
    when Game_Event::Error
      Widget_Msgbox.new(event.title, event.message){$scene = Scene_Title.new}
    when Game_Event::Leave
      $scene = Scene_Hall.new
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
  def terminate
    save_replay
    super
  end
end