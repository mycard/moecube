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
  require_relative 'window_chat'
  attr_reader :cardinfo_window
  attr_reader :player_field_window
  attr_reader :opponent_field_window
  attr_reader :fieldback_window
	def initialize(room, deck=nil)
    super()
		@room = room
    @deck = deck
  end
  def start
    WM::set_caption("MyCard v#{Update::Version} - #{$config['game']} - #{$game.user.name}(#{$game.user.id}) - #{@room.name}(#{@room.id})", "MyCard")
    @background = Surface.load("graphics/field/main.png").display_format
    Surface.blit(@background, 0, 0, 0, 0, $screen, 0, 0)
    
    init_game
    init_replay
    
    @phases_window = Window_Phases.new(122, 356)
    @fieldback_window = Window_FieldBack.new(131,173)
    @cardinfo_window = Window_CardInfo.new(715, 0)
    
    @player_field_window = Window_Field.new(2, 397, $game.player_field, true)
    @opponent_field_window = Window_Field.new(2, 56, $game.opponent_field, false)
    @player_lp_window = Window_LP.new(0,0, @room.player1, true)
    @opponent_lp_window = Window_LP.new(360,0, @room.player2, false)

    @join_se = Mixer::Wave.load("audio/se/join.ogg") if SDL.inited_system(INIT_AUDIO) != 0
    
    create_action_window
    create_chat_window
    super
  end
  def bgm
    "duel.ogg"
  end
  def create_action_window
    @player_field_window.action_window = Window_Action.new
  end
  def create_chat_window
    @background.fill_rect(@cardinfo_window.x, @cardinfo_window.height, 1024-@cardinfo_window.x, 768-@cardinfo_window.height,0xFFFFFFFF)
    @chat_window = Window_Chat.new(@cardinfo_window.x, @cardinfo_window.height, 1024-@cardinfo_window.x, 768-@cardinfo_window.height){|text|chat(text)}
    @chat_window.channel = @room
  end
  def chat(text)
    action Action::Chat.new(true, text)
  end
  def init_replay
    @replay = Replay.new
  end
  def save_replay
    #@replay.save if @replay #功能尚不可用
  end
  def init_game
    $game.player_field = Game_Field.new @deck
    $game.opponent_field = Game_Field.new
    $game.turn_player = true #
    $game.turn = 0
  end
  def change_phase(phase)
    action Action::ChangePhase.new(true, phase)
    if phase == :EP and
        action Action::TurnEnd.new(true, $game.player_field, $game.turn_player ? $game.turn : $game.turn.next)
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
    when Event::MouseButtonDown
      case event.button
      when Mouse::BUTTON_RIGHT
        if @player_field_window.action_window
          @player_field_window.action_window.next
        end
      else
        super
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
      when Key::F10
        $game.leave
      else
        super
      end
    else
      super
    end
  end
  
  
  def action(action)
    $game.action action# if @from_player
    Game_Event.push Game_Event::Action.new(action)
  end
  
  def handle_game(event)
    case event
    when Game_Event::Chat
      @chat_window.add event.chatmessage
    when Game_Event::Action
      if event.action.instance_of?(Action::Reset) and event.action.from_player
        save_replay
        init_replay
      end
      @replay.add event.str
      str = event.str
      if str =~ /^\[\d+\] (.*)$/m
        str = $1
      end
      if str =~ /^(?:●|◎)→(.*)$/m
        str = $1
      end
      user = if $game.room.player2 == $game.user
        event.action.from_player ? $game.room.player2 : $game.room.player1
      else
        event.action.from_player ? $game.room.player1 : $game.room.player2
      end
      @chat_window.add ChatMessage.new(user, str, $game.room)
      event.action.run
      refresh
    when Game_Event::Leave
      $scene = Scene_Lobby.new
    when Game_Event::Join
      $game.room = event.room
      @player_lp_window.player = $game.room.player1
      @opponent_lp_window.player = $game.room.player2
      player = $game.room.player1 == $game.user ? $game.room.player2 : $game.room.player1
      if player
        notify_send("对手加入房间", "#{player.name}(#{player.id})")
        Mixer.play_channel(-1,@join_se,0) if SDL.inited_system(INIT_AUDIO) != 0
      else
        notify_send("对手离开房间", "对手离开房间")
      end
    else
      super
    end
  end
  def update
    @cardinfo_window.update
    @chat_window.update
    super
  end
  def refresh
    @fieldback_window.card = $game.player_field.field[0] && $game.player_field.field[0].card_type == :"场地魔法" && $game.player_field.field[0].position == :attack ? $game.player_field.field[0] : $game.opponent_field.field[0] && $game.opponent_field.field[0].card_type == :"场地魔法" && $game.opponent_field.field[0].position == :attack ? $game.opponent_field.field[0] : nil
    @player_field_window.refresh
    @opponent_field_window.refresh
    @phases_window.player = $game.turn_player
    @phases_window.phase = $game.phase
    @player_lp_window.lp = $game.player_field.lp
    @opponent_lp_window.lp = $game.opponent_field.lp
  end
  def terminate
    unless $scene.is_a? Scene_Lobby or $scene.is_a? Scene_Duel
      $game.exit
    end
    save_replay
    super
  end
  def notify_send(title, msg)
    command = "notify-send -i graphics/system/icon.ico #{title} #{msg}"
    command = "start ruby/bin/#{command}".encode "GBK" if RUBY_PLATFORM["win"] || RUBY_PLATFORM["ming"]
    system(command)
    $log.info command
  end
end