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
    #子类定义
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
      player_field.hand = player_field.deck.pop(5)
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
    def run
      $game.phase = phase
      super
    end
  end
  class Move < Action
    attr_reader :from_pos, :to_pos, :card, :position
    def initialize(from_player, from_pos, to_pos=nil, card=nil, msg=nil, position=nil)
      super(from_player, msg)
      @from_pos = from_pos
      @to_pos = to_pos
      @card = card
      @position = position
    end
    def parse_field(pos)
      case pos
      when 0..10, :field
        player_field.field
      when 11..70, :hand, :handtop, :handrandom
        player_field.hand
      when 71..130,:deck, :decktop, :deckbottom
        player_field.deck
      when :graveyard
        player_field.graveyard
      when :extra
        player_field.extra
      when :removed
        player_field.removed
      end
    end
    def run
      $log.info('移动操作执行'){self.inspect}
      
      from_field = parse_field(@from_pos)
      
      from_pos = case @from_pos
      when 0..10
        @from_pos
      when 11..70
        @from_pos - 11
      when 71..130
        @from_pos - 71
      when :handtop
        player_field.hand.size - 1
      when :decktop
        player_field.deck.size - 1
      when nil
        nil
      else
        (@card.is_a?(Game_Card) ? from_field.index(@card) : from_field.index{|card|card.card == @card}) || from_field.index{|card|!card.known?}
      end
      
      to_field = parse_field(@to_pos)
      
      card = if from_pos 
        case @card
        when Game_Card
          @card
        when Card
          if from_field[from_pos]
            from_field[from_pos].card = @card
          else
            $log.warn('移动操作1'){'似乎凭空产生了卡片' + self.inspect}
            from_field[from_pos] = Game_Card.new(@card)
          end
          from_field[from_pos]
        else
          from_field[from_pos] || Game_Card.new
        end
      else #没有来源
        $log.warn('移动操作2'){'似乎凭空产生了卡片' + self.inspect}
        Game_Card.new(@card)
      end
      
      if @position
        if @position == :"face-up"
          if card.position != :attack and (6..10).include?(@to_pos || @from_pos) #里侧表示的怪兽
            card.position = :defense
          else
            card.position = :attack
          end
        else
          card.position = @position
        end
      end
      
      if @to_pos
        if from_pos
          if from_field == player_field.field
            from_field[from_pos] = nil
          else
            from_field.delete_at from_pos
          end
        end
        case @to_pos
        when 0..10
          to_field[@to_pos] = card
        when :hand, :deck, :decktop, :extra, :graveyard, :removed
          to_field.push card
        when :deckbottom
          to_field.unshift card
        else
          $log.error('移动操作3'){'错误的to_pos' + self.inspect}
        end
      end
      if from_field == player_field.hand and !@card || !@card.known?
        case @to_pos
        when 0..5
          player_field.hand.each{|card|card.card = Card::Unknown if card.known? and !card.monster?}
        when 6..10
          player_field.hand.each{|card|card.card = Card::Unknown if card.known? and card.monster?}
        else
          player_field.hand.each{|card|card.card = Card::Unknown if card.known?}
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
    def initialize(from_player, from_pos, card)
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
      super(from_player, from_pos, nil, card)
    end
    def run
      to_pos = opponent_field.field[6..10].index(nil)+6
      unless to_pos
        $log.warn('转移控制权'){'没有空余场位'}
        return
      end
      
      card = if @card.is_a? Game_Card
        @card
      elsif player_field.field[from_pos]
        card = player_field.field[from_pos]
        card.card = @card
        card
      else
        $log.warn('转移控制权'){'似乎凭空产生了卡片'+self.inspect}
        Game_Card.new(@card)
      end
      
      player_field.field[from_pos] = nil
      opponent_field.field[to_pos] = card
    end
  end
  class SendToOpponentGraveyard < SendToGraveyard
    def run
      card = if @card.is_a? Game_Card
        @card
      elsif player_field.field[from_pos]
        card = player_field.field[from_pos]
        card.card = @card
        card
      else
        Game_Card.new(@card)
      end
      player_field.field[from_pos] = nil
      opponent_field.graveyard.unshift card
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
      super(from_player, :decktop, :hand, nil, msg, :set)
    end
  end
  class Counter < Action
    
  end
  class MultiDraw < Action
    def initialize(from_player, count, msg=nil)
      super(from_player, msg)
      @count = count
    end
    def run
      super
      player_field.hand.concat player_field.deck.pop(@count)
    end
  end
  class MultiMove < Action
    def initialize(from_player, from_pos, to_pos, cards=nil)
      super(from_player)
      @from_pos = from_pos
      @to_pos = to_pos
      @cards = cards
    end
    def run
      from_field = case @from_pos
      when :hand
        player_field.hand
      when :graveyard
        player_field.graveyard
      when :spellsandtraps
        player_field.field[0..5]
      when :monsters
        player_field.field[6..10]
      end
      @cards = if @cards
        @cards.collect do |card|
          index = from_field.index{|fieldcard|fieldcard and fieldcard.card == card} || from_field.index{|fieldcard|fieldcard and !fieldcard.known?}
          if index
            fieldcard = from_field[index]
            from_field[index] = nil
            fieldcard.card = card
            fieldcard
          else
            $log.warn '似乎凭空产生了卡片'
            Game_Card.new(@card)
          end
        end
      else
        from_field.compact
      end
      to_field, position = case @to_pos
      when :hand
        [player_field.hand, :set]
      when :graveyard
        [player_field.graveyard, :attack]
      when :deck
        [player_field.deck, :set]
      when :removed
        [player_field.removed, :attack]
      end
      
      #执行部分
      case @from_pos
      when :hand
        player_field.hand.clear
      when :graveyard
        player_field.graveyard.clear
      when :spellsandtraps
        player_field.field[0..5] = Array.new(6, nil)
      when :monsters
        player_field.field[6..10] = Array.new(5, nil)
      end
      if to_field == player_field.hand or to_field == player_field.deck
        @cards.each{|card|card.position = position; to_field.push card}
      else
        @cards.each{|card|card.position = position; to_field.unshift card}
      end
      super
    end
  end
=begin #似乎不需要细分
  class MonstersSendToGraveyard < MultiMove
    def initialize(from_player, cards)
      super(from_player, :monsters, :graveyard, cards)
    end
  end
  class MonstersRemove < MultiMove
    def initialize(from_player, cards)
      super(from_player, :monsters, :remove, cards)
    end
  end
  class MonstersReturnToDeck < MultiMove
    def initialize(from_player, cards)
      super(from_player, :monsters, :deck, cards)
    end
  end
  class MonstersReturnToHand < MultiMove
    def initialize(from_player, cards)
      super(from_player, :monsters, :hand, cards)
    end
  end
  class SpellsAndTrapsSendToGraveyard < MultiMove
    def initialize(from_player, cards)
      super(from_player, :spellsandtraps, :graveyard, cards)
    end
  end
  class SpellsAndTrapsRemove < MultiMove
    def initialize(from_player, cards)
      super(from_player, :spellsandtraps, :remove, cards)
    end
  end
  class SpellsAndTrapsReturnToDeck < MultiMove
    def initialize(from_player, cards)
      super(from_player, :spellsandtraps, :deck, cards)
    end
  end
  class SpellsAndTrapsReturnToHand < MultiMove
    def initialize(from_player, cards)
      super(from_player, :spellsandtraps, :hand, cards)
    end
  end
  class HandSendToGraveyard < MultiMove
    def initialize(from_player, cards)
      super(from_player, :hand, :graveyard, cards)
    end
  end
  class HandRemove < MultiMove
    def initialize(from_player, cards)
      super(from_player, :hand, :remove, cards)
    end
  end
  class HandReturnToDeck < MultiMove
    def initialize(from_player, cards)
      super(from_player, :hand, :deck, cards)
    end
  end
=end
  class RefreshField < Action
    attr_reader :field
    def initialize(from_player, field, msg=nil)
      super(from_player, msg)
      @field = field
    end
    def run
      super
      return if @field.is_a? Game_Field #本地信息，无需处理。
      player_field.lp = @field[:lp]
      if player_field.hand.size > @field[:hand]
        player_field.hand.pop(player_field.hand.size-@field[:hand])
      elsif player_field.hand.size < @field[:hand]
        (@field[:hand]-player_field.hand.size).times{$log.warn('刷新场地-手卡'){'似乎凭空产生了卡片'};player_field.hand.push Game_Card.new(Card::Unknown)}
      end
      if player_field.deck.size > @field[:deck]
        player_field.deck.pop(player_field.deck.size-@field[:deck])
      elsif player_field.deck.size < @field[:deck]
        (@field[:deck]-player_field.deck.size).times{$log.warn('刷新场地-卡组'){'似乎凭空产生了卡片'};player_field.deck.push Game_Card.new(Card::Unknown)}
      end
      if player_field.graveyard.size > @field[:graveyard]
        player_field.graveyard.pop(player_field.graveyard.size-@field[:graveyard])
      elsif player_field.graveyard.size < @field[:graveyard]
        (@field[:graveyard]-player_field.graveyard.size).times{$log.warn('刷新场地-墓地'){'似乎凭空产生了卡片'};player_field.graveyard.push Game_Card.new(Card::Unknown)}
      end
      (0..10).each do |pos|
        if @field[pos]
          if player_field.field[pos]
            player_field.field[pos].card = @field[pos][:card]
          else
            $log.warn("刷新场地-#{pos}"){'似乎凭空产生了卡片'}
            player_field.field[pos] = Game_Card.new(@field[pos][:card])
          end
          player_field.field[pos].position = @field[pos][:position]
        else
          player_field.field[pos] = nil
        end
      end
    end
  end

  class TurnEnd < RefreshField
    attr_reader :turn
    def initialize(from_player, field, turn, msg=nil)
      super(from_player, field, msg)
      @turn = turn
    end
    def run
      $game.phase = :DP
      $game.turn = @turn.next
      $game.turn_player = !from_player
      super
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
    def initialize(from_player, from_pos=nil, cards)
      super(from_player, nil)
      @from_pos = from_pos
      @cards = cards
    end
    def run
      return if @cards[0].is_a? Game_Card #本地消息，不处理
      case @from_pos
      when :hand
        if player_field.hand.size > @cards.size
          player_field.hand.pop(player_field.hand.size-@cards.size)
        end
        @cards.each_with_index do |card, index|
          if player_field.hand[index]
            player_field.hand[index].card = card
          else
            player_field.hand[index] = Game_Card.new card
          end
        end
      when 71..130
        cards = @cards.to_enum
        player_field.deck[@from_pos-71, @cards.size].each do |game_card|
          game_card.card = cards.next
        end
      end
    end
  end
  class EffectActivate < Move
    def initialize(from_player, from_pos, card)
      if (0..10).include?(from_pos)
        position = :"face-up"
      else
        position = nil
      end
      super(from_player, from_pos, to_pos, card, nil, position)
    end
  end
  class ActivateAsk < Action
    def initialize(from_player)
      super(from_player)
    end
  end
  class ActivateAnswer < Action
    def initialize(from_player, activate)
      super(from_player)
      @activate = activate
    end
  end
  class Target < Action
    def initialize(from_player, from_pos, card, target_player ,target_pos, target_card)
      super(from_player)
      @from_pos = from_pos
      @card = card
      @target_pos = target_player
      @target_pos = target_pos
      @target_card = target_card
    end
    def run
      card = if @card.is_a? Game_Card
        @card
      else
        if player_field.field[@from_pos]
          player_field.field[@from_pos].card = @card
          player_field.field[@from_pos]
        else
          $log.warn('攻击宣言'){'似乎凭空产生了卡片' + self.inspect}
          player_field[@from_pos] = Game_Card.new(@card)
        end
      end
      $log.info('攻击宣言'){self.inspect}
    end
  end
  
  class ViewDeck < Action;  end
  class LP < Action
    attr_accessor :operator, :value
    def initialize(from_player, operator, value)
      super(from_player)
      @operator = operator
      @value = value
    end
    def run
      case operator
      when :lose
        player_field.lp -= @value
      when :increase
        player_field.lp += @value
      when :become
        player_field.lp = @value
      end
    end
  end
  class Attack < Action
    def initialize(from_player, from_pos, to_pos=nil, card)
      super(from_player)
      @from_pos = from_pos
      @to_pos = to_pos
      @card = card
    end
    def run
      card = if @card.is_a? Game_Card
        @card
      elsif @from_pos
        if player_field.field[@from_pos]
          player_field.field[@from_pos].card = @card
        else
          $log.warn('攻击宣言'){'似乎凭空产生了卡片' + self.inspect}
          player_field.field[@from_pos] = Game_Card.new(@card)
          player_field.field[@from_pos].position = :attack
        end
        player_field.field[@from_pos]
      else
        $log.info('直接攻击'){'功能未实现'}
        @card
      end
    end
  end
  class Counter < Action
    def initialize(from_player, from_pos, card, operator, value)
      super(from_player)
      @from_pos = from_pos
      @card = card
      @operator = operator
      @value = value
    end
    def run
      card = if @card.is_a? Game_Card
        @card
      else
        if player_field.field[@from_pos]
          player_field.field[@from_pos].card = @card
        else
          $log.warn('指示物操作'){'似乎凭空产生了卡片' + self.inspect}
          player_field.field[@from_pos] = Game_Card.new(@card)
          player_field.field[@from_pos].position = :attack
        end
        player_field.field[@from_pos]
      end
      case @operator
      when :become
        card.counters = @value
      else
        $log.warn('指示物操作'){'become以外的未实现' + self.inspect}
      end
    end
  end
  class Note < Action
    def initialize(from_player, from_pos, card, note)
      super(from_player)
      @from_pos = from_pos
      @card = card
      @note = note
    end
    def run
      card = if @card.is_a? Game_Card
        @card
      else
        if player_field.field[@from_pos]
          player_field.field[@from_pos].card = @card
        else
          $log.warn('指示物操作'){'似乎凭空产生了卡片' + self.inspect}
          player_field.field[@from_pos] = Game_Card.new(@card)
          player_field.field[@from_pos].position = :attack
        end
        player_field.field[@from_pos]
      end
      card.note = @note
    end
  end
  class Token < SpecialSummon
    def initialize(from_player, to_pos, card, position=:defense)
      super(from_player, nil, to_pos, card)
    end
  end
  class MultiToken < SpecialSummon
    def initialize(from_player, num, card, position=:attack)
      super(from_player, nil, nil, card)
      @num = num
    end
    def run
      @num.times do
        @to_pos = player_field.field[6..10].index(nil)+6
        super
      end
    end
  end
  class Add < Action
    def initialize(from_player, card)
      super(from_player)
      @card = card
    end
    def run
      if @card.extra?
        player_field.extra << Game_Card.new(@card)
      else
        player_field.hand << Game_Card.new(@card)
      end
    end
  end
  class Destroy < Action
    def initialize(from_player, from_pos, card)
      super(from_player)
      @from_pos = from_pos
      @card = card
    end
    def run
      if @from_pos <= 10
        player_field.field[@from_pos] = nil
      else
        player_field.hand.delete_at(@from_pos - 11)
      end
    end
  end
  class CardInfo < Action
    def initialize(card, card_type, atk, _def, attribute, type, level, lore)
      return unless card.diy?
      card.card_type = card_type
      #card.monster_type = monster_type
      card.atk = atk
      card.def = _def
      card.attribute = attribute
      card.type = type
      card.level = level
      card.lore = lore
    end
  end
  class Unknown < Action
    def initialize(str)
      @str = str
      $log.warn('unkonwn action') { str }
    end
    def run
      $log.warn('unkonwn action run'){ @str }
    end
  end
  def self.reset
    @@id=1
  end
  reset
end