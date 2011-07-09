#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_PlayerList < Window_List
  attr_reader :x, :y, :width, :height
  WLH = 16
	def initialize(x, y)
    super(x,y,272,16*34)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", WLH)
    @color = [0x03, 0x11, 0x22]
	end
  def draw_item(index, status=0)
    @font.draw_blended_utf8($screen, @list[index].name, @x, @y+index*WLH, *@color)
  end
  def item_rect(index)
    [@x, @y+WLH*index, @width, WLH]
  end
  def list=(list)
		@list = list
    @item_max = [@list.size, 34].min
    @height = @item_max * WLH
		refresh
	end
  def mousemoved(x,y)
    return unless include?(x,y)
    self.index = (y - @y) / WLH
  end
end