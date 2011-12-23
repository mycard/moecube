#encoding: UTF-8
#这个文件iduel和nbx相同，编辑时推荐使用软/硬链接来保持一致
require_relative '../action'
class Action
  CardFilter = /((?:<)?(?:\[.*?\])?\[(?:.*?)\][\s\d]*(?:>)?|一张怪兽卡|一张魔\/陷卡|\?\?)/
  PosFilter = /((?:手卡|手牌|场上|魔陷区|怪兽区|墓地|额外牌堆|除外区|卡组|卡组顶端|\(\d+\)){1,2})/
  PositionFilter = /(表攻|表守|里守|攻击表示|防守表示|里侧表示|背面守备表示)/
  PhaseFilter = /(抽卡`阶段|准备`阶段|主`阶段1|战斗`阶段|主`阶段2|结束`阶段)/
  FieldFilter = /(?:LP:(\d+)\n手卡(?:数)?:(\d+)\n卡组:(\d+)\n墓地:(\d+)\n除外:(\d+)\n前场:\n     <(?:#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{PositionFilter}\|#{CardFilter})?>\n后场:<#{CardFilter}?><#{CardFilter}?><#{CardFilter}?><#{CardFilter}?><#{CardFilter}?>\n场地\|<(?:无|#{CardFilter})>\n(?:◎|●)→＼＼)/
  def self.parse_pos(pos)
    if index = pos.index("(")
      index += 1
      pos[index, pos.index(")")-index].to_i
    else
      case pos
      when "手卡", "手牌"
        :hand
      when "场上", "魔陷区", "怪兽区"
        :field
      when "墓地"
        :graveyard
      when "额外牌堆"
        :extra
      when "除外区"
        :removed
      when "卡组顶端", "卡组"
        :deck
      end
    end
  end
  def self.parse_card(card)
    if index = card.rindex("[")
      index += 1
      name = card[index, card.rindex("]")-index].to_sym
      Card.find(name)
    else
      Card.find(nil)
    end
  end
  def self.parse_fieldcard(card)
    case card
    when "<>"
      [nil, nil]
    when "<??>"
      [:set, Card.find(nil)]
    else
      [card["表守"] ? :defense : card["里守"] ? :set : :attack, parse_card(card)]
    end
  end
  def self.parse_field(arr)
    #LP, 手卡, 卡组，墓地，除外，6表示形式，6卡，7表示形式，7卡，8表示形式，8卡，9表示形式，9卡，10表示形式，10卡，1,2,3,4,5,0
    {
      :lp => arr[0].to_i,
      :hand => arr[1].to_i,
      :deck => arr[2].to_i,
      :graveyard => arr[3].to_i,
      :removed => arr[4].to_i,
      6 => arr[5] && {:position => parse_position(arr[5]), :card => parse_card(arr[6])},
      7 => arr[7] && {:position => parse_position(arr[7]), :card => parse_card(arr[8])},
      8 => arr[9] && {:position => parse_position(arr[9]), :card => parse_card(arr[10])},
      9=> arr[11] && {:position => parse_position(arr[11]), :card => parse_card(arr[12])},
      10 => arr[13] && {:position => parse_position(arr[13]), :card => parse_card(arr[14])},
      1 => arr[15] && {:position => arr[15] == "??" ? :set : :attack, :card => parse_card(arr[15])},
      2 => arr[16] && {:position => arr[16] == "??" ? :set : :attack, :card => parse_card(arr[16])},
      3 => arr[17] && {:position => arr[17] == "??" ? :set : :attack, :card => parse_card(arr[17])},
      4 => arr[18] && {:position => arr[18] == "??" ? :set : :attack, :card => parse_card(arr[18])},
      5 => arr[19] && {:position => arr[19] == "??" ? :set : :attack, :card => parse_card(arr[19])},
      0 => arr[20] && {:position => arr[20] == "??" ? :set : :attack, :card => parse_card(arr[20])}
    }
  end
  def self.parse_position(position)
    case position
    when "攻击表示", "表攻"
      :attack
    when "防守表示", "表守"
      :defense
    when "里侧表示", "背面守备表示", "里守"
      :set
    end
  end
  def self.parse_phase(phase)
    case phase
    when "抽卡`阶段"
      :DP
    when "准备`阶段"
      :SP
    when "主`阶段1"
      :M1
    when "战斗`阶段"
      :BP
    when "主`阶段2"
      :M2
    when "结束`阶段"
      :EP
    end
  end
  def self.escape_pos(pos)
    case pos
    when 0..5
      "魔陷区(#{pos})"
    when 6..10
      "怪兽区(#{pos})"
    when :hand
      "手卡"
    when :field
      "场上"
    when :graveyard
      "墓地"
    when :extra
      "除外区"
    when :deck
      "卡组顶端"
    end
  end
  def self.escape_pos2(pos)
    case pos
    when :hand
      "手卡"
    when :deck
      "卡组"
    when :graveyard
      "墓地"
    when :extra
      "额外牌堆"
    when :removed
      "除外区"
    when 0..10
      "场上(#{pos})"
    end
  end
  def self.escape_position(position)
    case position
    when :attack
      "攻击表示"
    when :defense
      "防守表示"
    when :set
      "里侧表示"
    end
  end
  def self.escape_position_short(position)
    case position
    when :attack
      "表攻"
    when :defense
      "表守"
    when :set
      "里守"
    end
  end


  def self.escape_phase(phase)
    case phase
    when :DP
      "抽卡`阶段"
    when :SP
      "准备`阶段"
    when :M1
      "主`阶段1"
    when :BP
      "战斗`阶段"
    when :M2
      "主`阶段2"
    when :EP
      "结束`阶段"
    end
  end
  def self.parse(str)
    from_player = false
    case str
    when /^\[(\d+)\] (.*)$/m
      id = $1.to_i
      result = case $2
      when /^┊(.*)┊$/m
        Chat.new from_player, $1
      when /^※\[(.*)\]\n(.*)\n注释$/m
        Note.new from_player, $2, Card.find($1.to_sym)
      when /^※(.*)$/
        Chat.new from_player, $1
      when /^(◎|●)→=\[0:0:0\]==回合结束==<(\d+)>=\[\d+\]\n#{FieldFilter}(.*)$/ #把这货弄外面的原因是因为这个指令里开头有一个●→，后面还有，下面判msg的正则会判错
        field = $~.to_a
        field.shift #去掉第一个完整匹配信息
        from_player = field.shift == "◎"
        turn = field.shift.to_i
        msg = field.pop
        TurnEnd.new(from_player, parse_field(field), turn, msg)
      when /^(◎|●)→#{FieldFilter}$/
        field = $~.to_a
        field.shift
        from_player = field.shift == "◎"
        RefreshField.new(from_player, parse_field(field))
      when /^(?:(.*)\n)?(◎|●)→(.*)$/m
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
        when "卡组洗切", "切洗卡组"
          Shuffle.new from_player
        when "查看卡组"
          ViewDeck.new "查看卡组"
        when "将顶牌放回卡组底部"
          ReturnToDeckBottom.new(from_player, :deck)
        when /抽取\((\d+)\)张卡/
          MultiDraw.new from_player, $1.to_i
        when /\[\d+年\d+月\d+日禁卡表\](?:<(.+)> )?先攻/
          FirstToGo.new from_player, $1
        when /\[\d+年\d+月\d+日禁卡表\](?:<(.+)> )?后攻/
          SecondToGo.new from_player, $1
        when /(.*)掷骰子,结果为 (\d+)/
          Dice.new from_player, $2.to_i, $1
        when /(.*)抛硬币,结果为(.+)/
          Coin.new from_player, $2=="正面", $1
        when /从#{PosFilter}~发动#{CardFilter}#{PosFilter}/
          Activate.new from_player, parse_pos($1), parse_pos($3), parse_card($2)
        when /从#{PosFilter}~召唤#{CardFilter}#{PosFilter}/
          Summon.new from_player, parse_pos($1), parse_pos($3), parse_card($2), msg
        when /从#{PosFilter}~特殊召唤#{CardFilter}#{PosFilter}(?:呈#{PositionFilter})?/
          SpecialSummon.new from_player, parse_pos($1), parse_pos($3), parse_card($2), msg, $4 ? parse_position($4) : :attack
        when /从手卡~取#{CardFilter}盖到#{PosFilter}/
          Set.new from_player, :hand, parse_pos($2), parse_card($1)
        when /将#{CardFilter}从~#{PosFilter}~送往墓地/
          SendToGraveyard.new(from_player, parse_pos($2), parse_card($1))
        when /将~#{PosFilter}~的#{CardFilter}解~放/
          Tribute.new(from_player, parse_pos($1), parse_card($2))
        when /随机将一张卡从手卡\((\d+\))~放回卡组顶端/
          ReturnToDeck.new(from_player, $1.to_i+10, nil)
        when /随机舍弃~手卡~#{CardFilter}/
          Discard.new(from_player, :hand, parse_card($1))
        when /随机将手卡的#{CardFilter}从游戏中除外/
          Remove.new from_player, :hand, parse_card($1)
        when /随机显示一张手卡为：#{CardFilter}/
          Show.new(from_player, :hand, parse_card($1))
        when /第(\d+)张手牌为:#{CardFilter}/
          Show.new(from_player, $1.to_i+10, parse_card($2))
        when /\|--\+>手卡:(?:\[#{CardFilter}\])*/
          MultiShow.new from_player, $&.scan(CardFilter).collect{|matched|parse_card(matched.first)}
        when /将#{PosFilter}的#{CardFilter}从游戏中除外/
          Remove.new from_player, parse_pos($1), parse_card($2)
        when /#{CardFilter}从#{PosFilter}~放回卡组顶端/
          ReturnToDeck.new from_player, parse_pos($2), parse_card($1)
        when /#{CardFilter}从#{PosFilter}~放回卡组底端/
          ReturnToDeckBottom.new from_player, parse_pos($2), parse_card($1)
        when /#{CardFilter}从#{PosFilter}返回额外牌堆/
          ReturnToExtra.new from_player, parse_pos($2), parse_card($1)
        when /从#{PosFilter}取#{CardFilter}加入手卡/
          ReturnToHand.new from_player, parse_pos($1), parse_card($2)
        when /(?:己方)?#{PosFilter}.*?#{CardFilter}效果发(?:\~)?动/
          EffectActivate.new(from_player, parse_pos($1), parse_card($2))
        when /#{PosFilter}#{CardFilter}(?:变|改)为#{PositionFilter}/
          ChangePosition.new(from_player, parse_pos($1), parse_card($2), parse_position($3))
        when /#{PosFilter}#{CardFilter}打开/
          Flip.new(from_player, parse_pos($1), parse_card($2))
        when /#{PhaseFilter}/
          ChangePhase.new(from_player, parse_phase($1))
        else
          Unknown.new str
        end
      else
        Unknown.new str
      end
      result.id = id
      result
    when /^(#{CardFilter}\n)*$/
      MultiShow.new from_player, $&.lines.collect{|card|parse_card(card)}
    else
      Unknown.new str
    end
  end
  def escape
    inspect
  end
  def run
    $game.action self if @from_player
  end
  class FirstToGo
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→[11年3月1日禁卡表]先攻"
    end
  end
  class Draw
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→抽牌"
    end
  end
  class MultiDraw
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→抽取(#{@count})张卡"
    end
  end
  class Dice
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→掷骰子,结果为 #{@result}"
    end
  end
  class Reset
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→[11年3月1日禁卡表] Duel!!"
    end
  end
  class ChangePhase
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→#{Action.escape_phase(@phase)}"
    end
  end
  class TurnEnd
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→=[0:0:0]==回合结束==<#{@turn}>=[0]\n"+ @field.escape
    end
  end
  class Shuffle
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→卡组洗切"
    end
  end
  class Set
    def escape
      case @from_pos
      when :hand
        "[#{@id}] #{from_player ? '◎' : '●'}→从手卡~取一张#{@card.monster? ? "怪兽卡" : "魔/陷卡"}盖到场上(#{@to_pos})"
      end
    end
  end
  class Summon
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→从手卡~召唤#{@card.escape}(#{@to_pos})"
    end
  end
  class SpecialSummon
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→从#{Action.escape_pos2(@from_pos)}~特殊召唤#{@card.escape}(#{@to_pos})呈#{case @position; when :attack; "攻击"; when :defense; "守备";when :set; "背面守备"; end}表示"
    end
  end
  class Activate
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→从手卡~发动#{@card.escape}(#{@to_pos})"
    end
  end
  class SendToGraveyard
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→将#{@card.escape}从~#{Action.escape_pos2(@from_pos)}~送往墓地"
    end
  end
  class Tribute
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→将~#{Action.escape_pos2(@from_pos)}~的#{@card.escape}解~放"
    end
  end
  class Remove
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→将#{Action.escape_pos2(@from_pos)}的#{@card.escape}从游戏中除外"
    end
  end
  class ReturnToHand
    def escape
      pos = case @from_pos
      when :deck
        "卡组顶端"
      when :graveyard
        "墓地"
      when :removed
        "除外区"
      when 0..10
        "场上(#{@from_pos})"
      end
      "[#{@id}] #{from_player ? '◎' : '●'}→从#{pos}取#{@card.escape}加入手卡"
    end
  end
  class ReturnToDeck
    def escape
      pos = case @from_pos
      when :hand
        "手卡"
      when :graveyard
        "墓地"
      when :removed
        "除外区"
      when 0..10
        "场上(#{@from_pos})"
      end
      "[#{@id}] #{from_player ? '◎' : '●'}→#{@card.nil? or @from_pos == :hand ? "一张卡" : @card.escape}从#{pos}~放回卡组顶端" #TODO:set=【一张卡】
    end
  end
  class ReturnToDeckBottom
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→将顶牌放回卡组底部"
    end
  end
  class ReturnToExtra
    def escape
      pos = case @from_pos
      when :graveyard
        "墓地"
      when :removed
        "除外区"
      when 0..10
        "场上(#{pos})"
      end
      "[#{@id}] #{from_player ? '◎' : '●'}→#{@card.escape}从#{pos}返回额外牌堆"
    end
  end
  class Flip
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→(#{@from_pos})#{@card.escape}打开"
    end
  end
  class FlipSummon
    def escape
      "[#{@id}] #{from_player ? '◎' : '●'}→(#{@from_pos})#{@card.escape}反转"
    end
  end
  class ChangePosition
    def escape
      if @position == :set
        if (6..10).include? @from_pos #攻击表示的怪兽，由于iduel没有变成里侧守备指令，所以采用重新放置的方式
          "[#{@id}] #{from_player ? '◎' : '●'}→从怪兽区(#{@from_pos})~取一张怪兽卡盖到场上(#{@to_pos})"
        else
          "[#{@id}] #{from_player ? '◎' : '●'}→(#{@from_pos})#{@card.escape}变为里侧表示"
        end
      else
        "[#{@id}] #{from_player ? '◎' : '●'}→(#{@from_pos})#{@card.escape}改为#{position == :attack ? '攻击' : '防守'}表示"
      end
    end
  end
  class Show
    def escape
      case from_pos
      when 0..10
        #场上
      when Integer
        "第#{@from_pos-10}张手牌为:#{@card.escape}"
      end
    end
  end
  class MultiShow
    def escape
      @cards.collect{|card|card.escape}.join("\n")
    end
  end
  class EffectActivate
    def escape
      pos = case @from_pos
      when :hand
        "己方手牌"
      when :graveyard
        "己方墓地"
      when :deck
        "己方卡组"
      when :extra
        "己方额外牌堆"
      when :removed
        "己方除外区"
      when 0..10
        "(#{@from_pos})"
      end
      "[#{@id}] #{from_player ? '◎' : '●'}→#{pos}#{@card.escape}效果发#{"~" unless (0..10).include? @from_pos}动"
    end
  end
  class Chat
    def escape
      "[#{@id}] ┊#{@msg}┊"
    end
  end
end


class Game_Field
  def escape
    "LP:#{@lp}\n手卡:#{@hand.size}\n卡组:#{@deck.size}\n墓地:#{@graveyard.size}\n除外:#{@removed.size}\n前场:\n" +
      @field[6..10].collect{|card|"     <#{"#{Action.escape_position_short(card)}|#{card.position == :set ? '??' : "[#{card.card_type}][#{card.name}] #{card.atk}#{' '+card.def.to_s}"}" if card}>\n"}.join +
      "后场:" + 
      @field[1..5].collect{|card|"<#{card.position == :set ? '??' : card.escape if card}>"}.join +
      "\n场地|<#{@field[0] ? @field[0].escape : '无'}>\n" +
      "◎→＼＼"    
  end
  def self.parse(str)
    
    
  end
end
class Card
  def escape
    if [:通常魔法, :永续魔法, :装备魔法, :场地魔法, :通常陷阱, :永续陷阱, :反击陷阱].include? @card_type
      if @position == :set
        "一张魔/陷卡"
      else
        "<[#{@card_type}][#{@name}] >"
      end
    else
      if @position == :set
        "一张怪兽卡"
      else
        "<[#{@card_type}][#{@name}] #{@atk} #{@def}>"
      end
    end
  end
end
