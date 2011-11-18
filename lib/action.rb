#encoding: UTF-8
class Action
  @@id = 0
	attr_reader :from_player, :msg, :id
	def initialize(from_player=true, msg=nil)
    @id = @@id
    @from_player = from_player
    @msg = msg
    if @from_player
      @@id += 1
    end
  end
  def player_field
    @from_player ? @@player_field : @@opponent_field
  end
  def opponent_field
    @from_player ? @@opponent_field : @@player_field
  end
  def self.player_field=(field)
    @@player_field = field
  end
  def self.opponent_field=(field)
    @@opponent_field = field
  end
  def run
    #子类定义
  end
  class Reset < Action; end
  class Draw < Action
    def run
      player_field.hand << player_field.deck.shift
      super
    end
  end
  class Deck < Action;  end
  class Side < Deck;  end
  class Go < Action
    def run
      player_field.deck.shuffle!
      player_field.hand = player_field.deck.shift(5)
      super
    end
  end
  class FirstToGo < Go;  end
  class SecondToGo < Go;  end
  class Chat < Action; end
  class Shuffle < Action
    def run
      player_field.deck.shuffle!
      super
    end
  end
  class Note < Action
    attr_reader :card
    def initialize(from_player, msg, card)
      super(from_player, msg)
      @card = card
    end
  end
  class Coin < Action
    attr_reader :result
    def initialize(from_player, result=rand(1)==0, msg=nil)
      super(from_player, msg)
      @result = result
    end
  end
  class Dice < Action
    attr_reader :result
    def initialize(from_player, result=rand(6)+1, msg=nil)
      super(from_player, msg)
      @result = result
    end
  end
  class ChangePhase < Action
    attr_reader :phase
    def initialize(from_player, phase)
      super(from_player)
      @phase = phase
    end
  end
  class Move < Action
    attr_reader :from_pos, :to_pos, :card, :position
    def initialize(from_player, from_pos, to_pos, card, msg=nil, position=:attack)
      super(from_player, msg)
      @from_pos = from_pos
      @to_pos = to_pos
      @card = card
      @position = position
    end
    def run
      from_field = case @from_pos
      when Integer
        player_field.field
      when :hand
        player_field.hand
      when :field
        player_field.field
      when :graveyard
        player_field.graveyard
      when :deck
        player_field.deck
      when :extra
        player_field.extra
      when :removed
        player_field.removed
      end
      if @from_pos.is_a? Integer
        from_pos = @from_pos
      else
        from_pos = from_field.index(@card) || from_field.index(Card.find(nil))
      end
      if from_pos
        if from_field == player_field.field
          from_field[from_pos] = nil
        else
          from_field.delete_at from_pos
        end
      end
      p @to_pos
      p self
      
      to_field = case @to_pos
      when Integer
        player_field.field
      when :hand
        player_field.hand
      when :field
        player_field.field
      when :graveyard
        player_field.graveyard
      when :deck
        player_field.deck
      when :extra
        player_field.extra
      when :removed
        player_field.removed
      end
      if @to_pos.is_a? Integer
        to_pos = @to_pos
      elsif to_field == player_field.field
        to_pos = from_field.index(nil) || 11
      else
        to_pos = to_field.size
      end
      to_field[to_pos] = @card
      super
    end
  end
  class Set < Move
    def initialize(from_player, from_pos, to_pos, card)
      super(from_player, from_pos, to_pos, card, nil, :set)
    end
  end
  class Activate < Move;  end
  class Summon < Move;  end
  class SpecialSummon < Move;  end
  class SendToGraveyard < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, card, :graveyard)
    end
  end
  class Remove < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, card, :removed)
    end
  end
  class ReturnToHand < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, :hand, card)
    end
  end
  class ReturnToDeck < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, card, :deck)
    end
  end
  class ReturnToExtra < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, card, :extra)
    end
  end
  class Control < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, card, :opponent)
    end
  end
  class Refresh_Field < Action
    attr_reader :lp, :hand_count, :deck_count, :graveyard_count, :removed_count, :field
    def initialize(from_player, msg, lp, hand_count, deck_count, graveyard_count, removed_count, field)
      super(from_player, msg)
      @lp = lp
      @hand_count = hand_count
      @deck_count = deck_count
      @graveyard_count = graveyard_count
      @removed_count = removed_count
      @field = field
    end
  end
  class Turn_End < Refresh_Field
    attr_reader :turn
    def initialize(from_player, msg, lp, hand_count, deck_count, graveyard_count, removed_count, field, turn)
      super(from_player, msg, lp, hand_count, deck_count, graveyard_count, removed_count, field)
      @turn = turn
    end
  end
end