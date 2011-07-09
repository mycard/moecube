#encoding: UTF-8
#==============================================================================
# ■ Window_RoomList
#------------------------------------------------------------------------------
# 　大厅内房间列表
#==============================================================================

class Window_RoomList < Window_List
	attr_reader :list
  WLH = 48
	def initialize(x, y)
    @background = Surface.load 'graphics/hall/room.png'
    super(x,y,@background.w / 3, 48 * 10)
    @item_max = 0
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @color = [0x03, 0x11, 0x22]
	end

  def draw_item(index, status=0)
    room = @list[index]
    Surface.blit(@background, @width*status, room.full? ? WLH : 0, @width, WLH, $screen, @x, @y+WLH*index)
    @font.draw_blended_utf8($screen, "R-#{room.id}", @x+24, @y+WLH*index+8, *@color)
    @font.draw_blended_utf8($screen, room.full? ? "【决斗中】" : room.private? ? "【私密房】" : "【等待中】", @x+8, @y+WLH*index+24, *@color)
    @font.draw_blended_utf8($screen, room.name, @x+128, @y+WLH*index+8, *room.color)
    @font.draw_blended_utf8($screen, room.player1.name, @x+128, @y+WLH*index+24, *@color)
    @font.draw_blended_utf8($screen, room.player2.name, @x+256, @y+WLH*index+24, *@color) if room.full?
  end
  def item_rect(index)
    [@x, @y+WLH*index, @width, WLH]
  end
  def list=(list)
		@list = list
    @item_max = [@list.size, 10].min
    @height = @item_max * WLH
		refresh
	end
  def mousemoved(x,y)
    return unless include?(x,y)
    self.index = (y - @y) / WLH
  end
end

