#encoding: UTF-8
class Action
  CardFilter = /(<\[.*?\]\[(?:.*?)\][\s\d]*>|一张怪兽卡|一张魔\/陷卡)/.to_s
  PosFilter = /((?:手卡|场上|魔陷区|怪兽区|墓地|额外牌堆|除外区|卡组顶端|\(\d+\)){1,2})/.to_s
  PositionFilter = /(|攻击表示|防守表示|里侧表示|背面守备表示)/.to_s

  
	attr_reader :from_player, :msg
	def initialize(from_player, msg=nil)
    @from_player = from_player
    @msg = msg
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
  def do
    end
    def self.pos(pos)
      if index = pos.index("(")
        index += 1
        pos[index, pos.index(")")-index].to_i
      else
        case pos
        when "手卡"
          :hand
        when "场上", "魔陷区", "怪兽区"
          :field
        when "墓地"
          :graveyard
        when "额外牌堆"
          :extra
        when "除外区"
          :removed
        when "卡组顶端"
          :deck
        end
      end
    end
    def self.card(card)
      if index = card.rindex("[")
        index += 1
        Card.find(card[index, card.rindex("]")-index].to_sym)
      else
        Card.find(nil)
      end
    end
    def self.position(position)
      case position
      when "攻击表示"
        :attack
      when "防守表示"
        :defense
      when "里侧表示", "背面守备表示"
        :set
      end
    end
    def self.parse(str)
      str =~ /^\[\d+\] (.*)▊▊▊.*?$/m
      from_player = false
      case $1
      when /^┊(.*)┊$/m
        Chat.new from_player, $1
      when /^※\[(.*)\]\r\n(.*)\r\n注释$/m
        Note.new from_player, $2, Card.find($1.to_sym)
      when /^※(.*)$/
        Chat.new from_player, $1
      when /^(?:(.*)\r\n){0,1}(◎|●)→(.*)$/
        from_player = $2 == "◎"
        msg = $1
        case $3
        when /^\[\d+年\d+月\d+日禁卡表\] Duel!!/
          Reset.new from_player
        when /(.*)抽牌/
          Draw.new from_player, $1
        when "开启更换卡组"
          Deck.new from_player
        when "更换新卡组-检查卡组中..."
          Reset.new from_player
        when "换SIDE……"
          Side.new from_player
        when /\[\d+年\d+月\d+日禁卡表\](?:<(.+)> ){0,1}先攻/
          FirstToGo.new from_player, $1
        when /\[\d+年\d+月\d+日禁卡表\](?:<(.+)> ){0,1}后攻/
          SecondToGo.new from_player, $1
        when /(.*)掷骰子,结果为 (\d+)/
          Dice.new from_player, $2.to_i, $1
        when /(.*)抛硬币,结果为(.+)/
          Coin.new from_player, $2=="正面", $1
        when /从#{PosFilter}~发动#{CardFilter}#{PosFilter}/
          Activate.new from_player, pos($1), pos($3), card($2), msg
        when /从#{PosFilter}~召唤#{CardFilter}#{PosFilter}/
          Summon.new from_player, pos($1), pos($3), card($2), msg
        when /从#{PosFilter}~特殊召唤#{CardFilter}#{PosFilter}呈#{PositionFilter}/
          SpecialSummon.new from_player, pos($1), pos($3), card($2), msg, position($4)
        when /从手卡~取#{CardFilter}盖到#{PosFilter}/
          Set.new from_player, pos($2), card($1)
        when /将#{CardFilter}从~#{PosFilter}~送往墓地/
          SendToGraveyard.new(from_player, pos($2), card($1))
        when /将#{PosFilter}的#{CardFilter}从游戏中除外/
          Remove.new from_player, pos($1), card($2)
        when /#{CardFilter}从#{PosFilter}~放回卡组顶端/
          ReturnToDeck.new from_player, pos($2), card($1)
        when /#{CardFilter}从#{PosFilter}返回额外牌堆/
          ReturnToExtra.new from_player, pos($2), card($1)
        when /从#{PosFilter}取#{CardFilter}加入手卡/
          ReturnToHand.new from_player, pos($1), card($2)
        else
          p str, 1
          system("pause")
        end
      else
        p str, 2
        system("pause")
      end
    end
    class Reset < Action; end
    class Draw < Action
      def do
          player_field.hand << player_field.deck.shift
        end
      end
      class Deck < Action;  end
      class Side < Deck;  end
      class Go < Action
        def do
            player_field.deck.shuffle!
            player_field.hand = player_field.deck.shift(5)
          end
        end
        class FirstToGo < Go
          def escape
            "[2011年3月1日禁卡表\]#{"<#{@msg}>" if @msg} 先攻"
          end
        end
        class SecondToGo < Go
          def escape
            "[2011年3月1日禁卡表\]#{"<#{@msg}>" if @msg} 先攻"
          end
        end
        class Chat < Action; end
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
        class Move < Action
          attr_reader :from_pos, :to_pos, :card, :position
          def initialize(from_player, from_pos, to_pos, card, msg=nil, position=:attack)
            super(from_player, msg)
            @from_pos = from_pos
            @to_pos = to_pos
            @card = card
            @position = position
          end
          def do
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
            end
          end
          class Set < Move
            def initialize(from_player, from_pos, to_pos)
              super(from_player, from_pos, to_pos, :set)
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
              super(from_player, from_pos, card, :hand)
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
        end