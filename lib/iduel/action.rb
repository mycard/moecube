#encoding: UTF-8
class Action
  CardFilter = /(<?\[?Token[ \\\d]*\]?>?|<?(?:\[.*?\])?\[(?:.*?)\][ \d？]*>?|一张怪兽卡|一张魔\/陷卡|一张卡|\?\?)/.to_s
  PosFilter = /((?:手卡|手牌|场上|魔陷区|怪兽区|墓地|墓地\|,,,,,\|\*\:\d+张\:\*|额外牌堆|除外区|卡组|卡组顶端|\(\d+\)){1,2})/.to_s
  PositionFilter = /(表攻|表守|里守|攻击表示|防守表示|里侧表示|背面守备表示)/.to_s
  PhaseFilter = /(抽卡`阶段|准备`阶段|主`阶段1|战斗`阶段|主`阶段2|结束`阶段)/.to_s
  CountersFilter = /(?:\()?(\d+)?(?:\))?/.to_s
  FieldFilter = /(?:LP:(\d+)\n手卡(?:数)?:(\d+)\n卡组:(\d+)\n墓地:(\d+)\n除外:(\d+)\n前场:\n     <(?:#{CountersFilter}#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{CountersFilter}#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{CountersFilter}#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{CountersFilter}#{PositionFilter}\|#{CardFilter})?>\n     <(?:#{CountersFilter}#{PositionFilter}\|#{CardFilter})?>\n后场:<(?:#{CountersFilter}#{CardFilter})?><(?:#{CountersFilter}#{CardFilter})?><(?:#{CountersFilter}#{CardFilter})?><(?:#{CountersFilter}#{CardFilter})?><(?:#{CountersFilter}#{CardFilter})?>\n场地\|<(?:无|#{CountersFilter}#{CardFilter})>\n(?:◎|●)→＼＼)/.to_s
  def self.parse_pos(pos)
    if index = pos.index("(")
      index += 1
      result = pos[index, pos.index(")")-index].to_i
      result += 10 if pos["手卡"]
      result
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
      when "卡组顶端"
        :decktop
      when "卡组"
        :deck
      end
    end
  end
  def self.parse_card(card)
    if card['Token']
      @token ||= Card.new('name'=>:Token, 'id'=>-1, 'token'=>true, 'number'=>:"00000000", 'attribute' => :暗, 'level' => 1, 'card_type' => :通常怪兽, 'stats' => "", 'archettypes' => "", 'mediums' => "", 'lore' => "这张卡作为衍生物使用。")
    elsif index = card.rindex('[')
      name = card[index+1, card.rindex(']')-index-1].to_sym
      result = Card.find(name)
      if result.diy? and index = card[0, index].index('[')
        card_type = card[index+1, card.index(']')-2].to_sym
        card_type = :超量怪兽 if [:XYZ怪兽, :XYZ怪].include? card_type
        result.card_type = card_type
      end
      result
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
  def self.parse_field(matched)
    #LP, 手卡, 卡组, 墓地, 除外, 6指示物, 6表示形式, 6卡, 7指示物, 7表示形式, 7卡, 8指示物, 8表示形式, 8卡, 9指示物, 9表示形式, 9卡, 10指示物, 10表示形式, 10卡, 1指示物, 1卡, 2指示物, 2卡, 3指示物, 3卡, 4指示物, 4卡, 5指示物, 5卡, 0指示物, 0卡
    {
      :lp  => matched[0].to_i,
      :hand => matched[1].to_i,
      :deck => matched[2].to_i,
      :graveyard => matched[3].to_i,
      :removed => matched[4].to_i,
      6 => matched[7]  && {:counters => parse_counters(matched[5]),  :position => parse_position(matched[6]),  :card => parse_card(matched[7])},
      7 => matched[10] && {:counters => parse_counters(matched[8]),  :position => parse_position(matched[9]),  :card => parse_card(matched[10])},
      8 => matched[13] && {:counters => parse_counters(matched[11]), :position => parse_position(matched[12]), :card => parse_card(matched[13])},
      9 => matched[16] && {:counters => parse_counters(matched[14]), :position => parse_position(matched[15]), :card => parse_card(matched[16])},
      10=> matched[19] && {:counters => parse_counters(matched[17]), :position => parse_position(matched[18]), :card => parse_card(matched[19])},
      1 => matched[21] && {:counters => parse_counters(matched[20]), :position => matched[21] == "??" ? :set : :attack, :card => parse_card(matched[21])},
      2 => matched[23] && {:counters => parse_counters(matched[22]), :position => matched[23] == "??" ? :set : :attack, :card => parse_card(matched[23])},
      3 => matched[25] && {:counters => parse_counters(matched[24]), :position => matched[25] == "??" ? :set : :attack, :card => parse_card(matched[25])},
      4 => matched[27] && {:counters => parse_counters(matched[26]), :position => matched[27] == "??" ? :set : :attack, :card => parse_card(matched[27])},
      5 => matched[29] && {:counters => parse_counters(matched[28]), :position => matched[29] == "??" ? :set : :attack, :card => parse_card(matched[29])},
      0 => matched[31] && {:counters => parse_counters(matched[30]), :position => matched[31] == "??" ? :set : :attack, :card => parse_card(matched[31])}
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
  def self.parse_counters(counters)
    counters.to_i
  end
  def self.parse(str)
    #TODO:效率优化
    from_player = nil
    case str
    when /^\[(\d+)\] (.*)$/m
      id = $1.to_i
      result = case $2
      when /^┊(.*)┊$/m
        Chat.new from_player, $1
      when /^※\[(.*)\]\n(.*)\n注释.*$/m
        card = Card.find($1.to_sym)
        case $2 
        when /(.+怪兽),种族：(.+),属性：(.+),星级：(\d+),攻击：(\d+|？),防御：(\d+|？),效果：(.+)/
          CardInfo.new(card, $1.to_sym, $5 == "？" ? nil : $5.to_i, $6 == "？" ? nil : $6.to_i, $3.to_sym, $2.to_sym, $4.to_sym, $7)
        when /(魔法|陷阱)种类：(.+),效果：(.+)/
          CardInfo.new(card, ($2+$1).to_sym, nil, nil, nil, nil, nil, $3)
        end
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
        when "要连锁吗？"
          ActivateAsk.new from_player
        when "我要连锁！"
          ActivateAnswer.new from_player, true
        when "请继续吧~"
          ActivateAnswer.new from_player, false
        when "将顶牌放回卡组底部"
          ReturnToDeckBottom.new(from_player, :decktop)
        when /抽取\((\d+)\)张卡/
          MultiDraw.new from_player, $1.to_i
        when /己方卡组第(\d+)张加入手卡/
          ReturnToHand.new(from_player, $1.to_i+71, nil)
        when /\[\d+年\d+月\d+日禁卡表\](?:<(.+)> )?先攻/
          FirstToGo.new from_player, $1
        when /\[\d+年\d+月\d+日禁卡表\](?:<(.+)> )?后攻/
          SecondToGo.new from_player, $1
        when /(.*)掷骰子,结果为 (\d+)/
          Dice.new from_player, $2.to_i, $1
        when /(.*)抛硬币,结果为(.+)/
          Coin.new from_player, $2=="正面", $1
        when "查看卡组"
          ViewDeck.new from_player
        when /查看卡组上方(\d+)张卡/
          ViewDeck.new from_player, $1.to_i
        when /刚才抽到的卡是:#{CardFilter}/
          Show.new(from_player, :handtop, parse_card($1))
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
          Discard.new(from_player, :handrandom, parse_card($1))
        when /随机将手卡的#{CardFilter}从游戏中除外/
          Remove.new from_player, :handrandom, parse_card($1)
        when /随机显示一张手卡为：#{CardFilter}/
          Show.new(from_player, :handrandom, parse_card($1))
        when /第(\d+)张手牌为:#{CardFilter}/
          Show.new(from_player, $1.to_i+10, parse_card($2))
        when /\|--\+>手卡:(?:\[#{CardFilter}\])*/
          MultiShow.new from_player, :hand, $&.scan(/#{CardFilter}/).collect{|matched|parse_card(matched.first)}
        when /^(?:(\d+)#{CardFilter}\n?)+$/
          from_pos = 71
          cards = $&.lines.collect do |line|
            line =~ /(\d+)#{CardFilter}/
            from_pos ||= $1.to_i + 71
            parse_card($2)
          end
          MultiShow.new from_player, from_pos, cards
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
        when /(?:己方)?#{PosFilter}.*?#{CardFilter}(?:选择(.*)为对象>)?效果发(?:\~)?动/
          EffectActivate.new(from_player, parse_pos($1), parse_card($2))
        when /#{PosFilter}#{CardFilter}(?:变|改)为#{PositionFilter}/
          ChangePosition.new(from_player, parse_pos($1), parse_card($2), parse_position($3))
        when /#{PosFilter}#{CardFilter}转移控制权/
          Control.new(from_player, parse_pos($1), parse_card($2))
        when /#{PosFilter}#{CardFilter}打开/
          Flip.new(from_player, parse_pos($1), parse_card($2))
        when /#{PosFilter}#{CardFilter}反转/
          FlipSummon.new(from_player, parse_pos($1), parse_card($2))
        when /#{PosFilter}#{CardFilter}向(左|右)移动/
          from_pos = parse_pos($1)
          to_pos = $3 == '左' ? from_pos - 1 : from_pos + 1
          Move.new(from_player, from_pos, to_pos, parse_card($2))
        when /己方(场上所有怪兽卡\||场上所有魔\/陷卡\||所有手卡\||墓地\|,,,,,\|\*:\d+张:\*)(?:~#{CardFilter})*~全部(放回卡组顶端|送往墓地|除外|加入手卡)/
          from_pos = case $1
          when "场上所有怪兽卡|"
            :monsters
          when "场上所有魔\/陷卡|"
            :spellsandtraps
          when "所有手卡|"
            :hand
          else
            if $1["墓地"]
              :graveyard
            end
          end
          to_pos = case $3
          when "放回卡组顶端"
            :deck
          when "送往墓地"
            :graveyard
          when "除外"
            :removed
          when "加入手卡"
            :hand
          end
          cards = $&.scan(/#{CardFilter}/).collect{|matched|parse_card matched.first}
          MultiMove.new(from_player, from_pos, to_pos, cards)
        when /己方#{PosFilter}#{CardFilter}送入对手墓地/
          SendToOpponentGraveyard.new(from_player, parse_pos($1), parse_card($2))
        when /#{PosFilter}#{CardFilter}选择(我方)?-#{PosFilter}- (?:#{PositionFilter}\|)?#{CardFilter}为效果对象/
          Target.new(from_player, parse_pos($1), parse_card($2), $3 ? true : false, parse_pos($4), parse_card($6))
        when /#{PhaseFilter}/
          ChangePhase.new(from_player, parse_phase($1))
        when /LP(损失|回复|变成)<(-?\d+)>/
          LP.new(from_player, case $1 when "损失"; :lose; when "回复"; :increase; when "变成"; :become end, $2.to_i)
        when /#{PosFilter}#{CardFilter}攻击-#{PosFilter}- #{CardFilter}/
          Attack.new(from_player, parse_pos($1), parse_pos($3), parse_card($2))
        when /#{CardFilter}(?:直接)?攻击/
          Attack.new(from_player, nil, nil, parse_card($1))
        when /(?:清空)?#{PosFilter}#{CardFilter}的指示物(?:加一|减一)?,现为#{CountersFilter}/
          Counter.new(from_player, parse_pos($1), parse_card($2), :become, parse_counters($3))
        when /己方#{PosFilter}#{CardFilter}修改备注为：(.*)/
          Note.new(from_player, parse_pos($1), parse_card($2), $3)
        when /~特殊召唤#{CardFilter}#{PosFilter}呈#{PositionFilter}/
          Token.new(from_player, parse_pos($2), parse_card($1), parse_position($3))
        when /~特殊召唤(\d+)个#{CardFilter}呈#{PositionFilter}/
          MultiToken.new(from_player, $1.to_i, parse_card($2), parse_position($3))
        when /添加一张手牌#{CardFilter}/
          Add.new(from_player, parse_card($1))
        when /将#{PosFilter}#{CardFilter}撕掉!/
          Destroy.new(from_player, parse_pos($1), parse_card($2))
        else
          Unknown.new str
        end
      else
        Unknown.new str
      end
      result.id = id
      result
    when /系统消息：.+?\(\d+\)已经退出房间/
      Reset.new from_player
    when /^(#{CardFilter}\n?)*$/
      MultiShow.new from_player, nil, $&.lines.collect{|card|parse_card(card)}
    else
      Unknown.new str
    end
  end
  def escape
    inspect
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
      "[#{@id}] #{from_player ? '◎' : '●'}→=[0:0:0]==回合结束==<#{@turn}>=[0]\n"+ @field.escape + "#{from_player ? '◎' : '●'}→＼＼"    
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
      "\n场地|<#{@field[0] ? @field[0].escape : '无'}>\n"
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
