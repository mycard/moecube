# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_CardInfo < Window
  WLH = 20
  def initialize(x,y)
    super(x,y,160,768,300)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    self.card = nil
  end
  def card=(card)
    @card = card || Card.find(nil)
    refresh
  end
  def refresh
    @contents.put @card.image,0,0
    @contents.fill_rect(0,230, @width, @height-230,0xCC005555)
    @font.draw_blended_utf8(@contents, "[#{@card.name}]", 0, 230, 0xFF, 0xFF, 0x55)  
    
    start = 0
    line = 0
    @card.lore.size.times do |char|
      if @font.text_size(@card.lore[start..char])[0] > @width
        @font.draw_blended_utf8(@contents, @card.lore[start...char], 0, 254+line*WLH, 0xFF, 0xFF, 0xFF)
        start = char
        line = line.next
      end
    end
    if start <= @card.lore.size - 1
      @font.draw_blended_utf8(@contents, @card.lore[start...@card.lore.size], 0, 254+line*WLH, 0xFF, 0xFF, 0xFF)
    end
  end
end
