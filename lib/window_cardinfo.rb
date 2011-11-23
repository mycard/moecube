# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_CardInfo < Window
  WLH = 20
  def initialize(x,y)
    super(x,y,1024-x,530,300)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    self.card = nil
  end
  def card=(card)
    @card = card || Card.find(nil)
    refresh
  end
  def update
    if @lore_start
      if @lore_start >= @card.lore.size
        @lore_start = nil #停止描绘
        return
      end
      char = @card.lore[@lore_start]
      width = @font.text_size(char)[0]
      if @lore_pos[0] + width > @width
        @lore_pos[0] = 0
        @lore_pos[1] += WLH
      end
      @font.draw_blended_utf8(@contents, char, @lore_pos[0], @lore_pos[1], 0xFF, 0xFF, 0xFF)
      @lore_pos[0] += width
      @lore_start += 1

      
    end
  end
  def refresh
    @contents.fill_rect(0,0, @width, @height,0xCC005555)
    
    @contents.put @card.image,0,0
    @font.draw_blended_utf8(@contents, "[#{@card.name}]", 160, 0, 0xFF, 0xFF, 0x55)
    @font.draw_blended_utf8(@contents, "卡类: #{@card.card_type}", 160, WLH, 0xFF, 0xFF, 0x55)
    if @card.monster?
      @font.draw_blended_utf8(@contents, "种族: #{@card.type}", 160, WLH*2, 0xFF, 0xFF, 0xFF)
      @font.draw_blended_utf8(@contents, "星级: #{@card.level}", 160, WLH*3, 0xFF, 0xFF, 0xFF)
      @font.draw_blended_utf8(@contents, "攻击力: #{@card.atk}", 160, WLH*4, 0xFF, 0xFF, 0xFF)
      @font.draw_blended_utf8(@contents, "防御力: #{@card.def}", 160, WLH*5, 0xFF, 0xFF, 0xFF)
    end
    @lore_start = 0
    @lore_pos = [0, 234]
  end
end
