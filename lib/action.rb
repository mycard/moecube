#encoding: UTF-8
class Action
	attr_accessor :from_player, :msg
  attr_accessor :id
	def initialize(from_player=true, msg=nil)
    @id = @@id
    @from_player = from_player
    @msg = msg
    @@id += 1 if @from_player
  end
  def player_field
    @from_player ? $game.player_field : $game.opponent_field
  end
  def opponent_field
    @from_player ? $game.opponent_field : $game.player_field
  end
  def run
    $game.action self
  end
  class Reset < Action
    def run
      player_field.reset
      super
    end
  end

  class Deck < Action;  end
  class Side < Deck;  end
  class Go < Reset
    def run
      super
      player_field.hand = player_field.deck.shift(5)
      #player_field.hand.each{|card|card.position = :set}
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
    def initialize(from_player, from_pos, to_pos=nil, card=Card::Unknown, msg=nil, position=nil)
      super(from_player, msg)
      @from_pos = from_pos
      @to_pos = to_pos
      @card = card
      @position = position
    end
    def run
      from_field = case @from_pos
      when 0..10
        player_field.field
      when Integer, :hand
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
      else
        puts '奇怪的from_field'
        puts
      end
      
      if @from_pos.is_a? Integer
        if @from_pos > 10
          from_pos = @from_pos - 11
        else
          from_pos = @from_pos
        end
      else
        from_pos = (@card.is_a?(Game_Card) ? from_field.index(@card) : from_field.index{|card|card.card == @card}) || from_field.index{|card|!card.known?}
      end
      
      to_field = case @to_pos
      when Integer
        player_field.field
      when :hand
        player_field.hand
      when :graveyard
        player_field.graveyard
      when :deck, :deckbottom
        player_field.deck
      when :extra
        player_field.extra
      when :removed
        player_field.removed
      end
      if from_pos && from_field[from_pos]
        case @card
        when Game_Card
          card = from_field[from_pos] = @card
        when nil, Card::Unknown
          card = from_field[from_pos]
        when Card
          card = from_field[from_pos]
          card.card = @card
        end
        if @to_pos
          if from_field == player_field.field
            from_field[from_pos] = nil
          else
            from_field.delete_at from_pos
          end
        end
      else
        card = Game_Card.new(@card)
        puts "似乎凭空产生了卡片？"
        p self
      end
      card.position = @position if @position
      if @to_pos
        if @to_pos.is_a? Integer
          to_field[@to_pos] = card
        elsif @to_pos == :hand or @to_pos == :deckbottom
          to_field << card
        else
          to_field.unshift card
        end
      end
      super
    end
  end
  class Set < Move
    def initialize(from_player, from_pos, to_pos, card)
      super(from_player, from_pos, to_pos, card, nil, :set)
    end
  end
  class Activate < Move
    def initialize(from_player, from_pos, to_pos, card)
      super(from_player, from_pos, to_pos, card, nil, :attack)
    end
  end
  class Summon < Move
    def initialize(from_player, from_pos, to_pos, card, msg=nil)
      super(from_player, from_pos, to_pos, card, msg, :attack)
    end
  end
  class SpecialSummon < Move
    def initialize(from_player, from_pos, to_pos, card, msg=nil, position=:attack)
      super(from_player, from_pos, to_pos, card, msg, position)
    end
  end
  class SendToGraveyard < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, :graveyard, card, nil, :attack)
    end
  end
  class Remove < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, :removed, card, nil, :attack)
    end
  end
  class ReturnToHand < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, :hand, card, nil, :set)
    end
  end
  class ReturnToDeck < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, :deck, card, nil, :set)
    end
  end
  class ReturnToDeckBottom < Move
    def initialize(from_player, from_pos, card=Card.find(nil))
      if from_pos == :deck and card == Card.find(nil)
        @from_player = from_player
        card = player_field.deck.first
      end
      super(from_player, from_pos, :deckbottom, card, nil, :set)
    end
  end
  class ReturnToExtra < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, :extra, card, nil, :set)
    end
  end
  class Control < Move
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, :opponent, card)
    end
  end
  class Tribute < SendToGraveyard;  end
  class Discard < SendToGraveyard;  end
  class ChangePosition < Move
    def initialize(from_player, from_pos, card, position)
      super(from_player, from_pos, from_pos, card, nil, position)
    end
  end
  class Flip < ChangePosition
    def initialize(from_player, from_pos, card, position=:defense)
      super(from_player, from_pos, card, position)
    end
  end
  class FlipSummon < Flip
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, card, :attack)
    end
  end
  class Draw < Move
    def initialize(from_player=true, msg=nil)
      @from_player = from_player
      super(from_player, :deck, :hand, player_field.deck.first, msg, :set)
    end
  end
  class MultiDraw < Action
    def initialize(from_player, count, msg=nil)
      super(from_player, msg)
      @count = count
    end
    def run
      super
      player_field.hand += player_field.deck.shift(@count)
    end
  end
  class RefreshField < Action
    attr_reader :field
    def initialize(from_player, field, msg=nil)
      super(from_player, msg)
      @field = field
    end
    def run
      player_field.lp = @field[:lp]
      if player_field.hand.size > @field[:hand]
        player_field.hand.pop(player_field.hand.size-@field[:hand])
      elsif player_field.hand.size < @field[:hand]
        (@field[:hand]-player_field.hand.size).times{player_field.hand.push Game_Card.new(Card::Unknown)}
      end
      if player_field.deck.size > @field[:deck]
        player_field.deck.pop(player_field.deck.size-@field[:deck])
      elsif player_field.deck.size < @field[:deck]
        (@field[:deck]-player_field.deck.size).times{player_field.deck.push Game_Card.new(Card::Unknown)}
      end
      if player_field.graveyard.size > @field[:graveyard]
         player_field.graveyard.pop(player_field.graveyard.size-@field[:graveyard])
      elsif player_field.graveyard.size < @field[:graveyard]
         (@field[:graveyard]-player_field.graveyard.size).times{player_field.graveyard.push Game_Card.new(Card::Unknown)}
      end
      (0..10).each do |pos|
        if @field[pos]
          player_field.field[pos] ||= Game_Card.new(@field[pos][:card])
          player_field.field[pos].card = @field[pos][:card]
          p player_field.field[pos].card
          player_field.field[pos].position = @field[pos][:position]
        else
          player_field.field[pos] = nil
        end
      end
      p player_field
    end
  end

  class TurnEnd < RefreshField
    attr_reader :turn
    def initialize(from_player, field, turn, msg=nil)
      super(from_player, field, msg)
      @turn = turn
    end
  end
  class Show < Move
    attr_reader :from_pos, :card
    def initialize(from_player, from_pos, card)
      super(from_player, from_pos, nil, card)
      @from_pos = from_pos
      @card = card
    end
  end
  class MultiShow < Action
    def initialize(from_player, cards)
      super(from_player, nil)
      @cards = cards
    end
  end
  class Effect_Activate < Move
    def initialize(from_player, from_pos, card)
      @from_player = from_player
      if (0..10).include?(from_pos)
        if (6..10).include?(from_pos) && player_field.field[from_pos] && (player_field.field[from_pos].position == :set || player_field.field[from_pos].position == :defense)
          position = :defense
        else
          position = :attack
        end
      else
        position = nil
      end
      super(from_player, from_pos, nil, card, nil, position)
    end
  end
  class Ignored < Action
    def initialize(str)
      @str = str
    end
  end
  class Unknown < Action
    def initialize(str)
      @str = str
      puts 'unkonwn action ' + str
    end
    def run
      puts 'unkonwn action run ' + @str
    end
  end
  def self.reset
    @@id=1
  end
  reset
end