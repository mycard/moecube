class <<Action
  CardFilter = /(<\[.*?\]\[(?:.*?)\][\s\d]*>|一张怪兽卡|一张魔\/陷卡)/.to_s
  PosFilter = /((?:手卡|场上|魔陷区|怪兽区|墓地|额外牌堆|除外区|卡组顶端|\(\d+\)){1,2})/.to_s
  PositionFilter = /(|攻击表示|防守表示|里侧表示|背面守备表示)/.to_s
  def parse_pos(pos)
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
  def parse_card(card)
    if index = card.rindex("[")
      index += 1
      Card.find(card[index, card.rindex("]")-index].to_sym)
    else
      Card.find(nil)
    end
  end
  def parse_position(position)
    case position
    when "攻击表示"
      :attack
    when "防守表示"
      :defense
    when "里侧表示", "背面守备表示"
      :set
    end
  end
  def escape_pos(pos)
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
  def escape_position(position)
    case position
    when :attack
      "攻击表示"
    when :defense
      "防守表示"
    when :set
      "里侧表示"
    end
  end
  def escape_card(card)
    if [:通常魔法, :永续魔法, :装备魔法, :场地魔法, :通常陷阱, :永续陷阱, :反击陷阱].include? card.card_type
      if card.position == :set
        "一张魔/陷卡"
      else
        "<[#{card.card_type}][#{card.name}] >"
      end
    else
      if card.position == :set
        "一张怪兽卡"
      else
        "<[#{card.card_type}][#{card.name}] #{card.atk} #{card.def}>"
      end
    end
  end
  def parse(str)
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
  def escape
    
  end
end