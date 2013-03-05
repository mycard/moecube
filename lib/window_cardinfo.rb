class Window_CardInfo < Window
  WLH = 20
  def initialize(x,y)
    super(x,y,1024-x,524,300)
    @font = TTF.open(Font, 16)
    tip = Card.new('name' => :mycard, 'number' => :"000000", 'lore' => "iDuel部分仅实现了观战，无法进行决斗\n\n提示：\n快捷键：\nF10 退出房间\nF12 返回主界面", 'card_type' => :"通常魔法", 'stats' => "", 'archettypes' => "", "mediums" => "", "tokens" => 0)
    tip.instance_eval { @image = Card::CardBack; @image_small = Card::CardBack_Small }
    self.card = Game_Card.new tip
  end
  def card=(card)
    return if card.nil? or card == @card or !card.known?
    @card = card
    refresh
  end
  def update
    if @lore_start
      if @lore_start >= @card.lore.size
        @lore_start = nil #停止描绘
        return
      end
      char = @card.lore[@lore_start]
      @lore_start += 1
      if char == "\n"
        @lore_pos[0] = 0
        @lore_pos[1] += WLH
        return
      end
      width = @font.text_size(char)[0]
      if @lore_pos[0] + width > @width
        @lore_pos[0] = 0
        @lore_pos[1] += WLH
      end
      @font.draw_blended_utf8(@contents, char, @lore_pos[0], @lore_pos[1], 0xFF, 0xFF, 0xFF)
      @lore_pos[0] += width
    end
  end
  def refresh
    @contents.fill_rect(0,0, @width, @height,0xCC005555)
    
    @contents.put @card.image,0,0
    @font.draw_blended_utf8(@contents, "[#{@card.name}]", 160, 0, 0xFF, 0xFF, 0x55)
    @font.draw_blended_utf8(@contents, "#{@card.card_type}", 160, WLH, 0xFF, 0xFF, 0x55)
    if @card.monster?
      @font.draw_blended_utf8(@contents, "种族: #{@card.type}", 160, WLH*2, 0xFF, 0xFF, 0xFF)
      @font.draw_blended_utf8(@contents, "星级: #{@card.level}", 160, WLH*3, 0xFF, 0xFF, 0xFF)
      @font.draw_blended_utf8(@contents, "攻击力: #{@card.atk}", 160, WLH*4, 0xFF, 0xFF, 0xFF)
      @font.draw_blended_utf8(@contents, "防御力: #{@card.def}", 160, WLH*5, 0xFF, 0xFF, 0xFF)
    end
    @lore_start = 0
    @lore_pos = [0, 234]
    
    # @font.draw_blended_utf8(@contents, @card.inspect, 0, 300, 0xFF, 0xFF, 0x66)
  end
end
