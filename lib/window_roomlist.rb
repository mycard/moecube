#encoding: UTF-8
#==============================================================================
# ■ Window_Roomitems
#------------------------------------------------------------------------------
# 　大厅内房间列表
#==============================================================================
require_relative 'window_scrollable'
class Window_RoomList < Window_Scrollable
	attr_reader :items
  WLH = 48
	def initialize(x, y, items)
    @button = Surface.load('graphics/lobby/room.png')
    @button.set_alpha(RLEACCEL, 255)
    #@background = Surface.load 'graphics/lobby/roomitems.png'
    #@contents = Surface.load 'graphics/lobby/roomitems.png'
    super(x,y,@button.w / 3, 48 * 10)
    @item_max = 0
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @color = [0x03, 0x11, 0x22]
    @scrolling = Widget_ScrollBar.new(self,@x+@width,@y,@height)
    self.items = items
	end

  def draw_item(index, status=0)
    y = item_rect(index)[1]
    room = @items[index]
    Surface.blit(@button, @width*status, room.full? ? WLH : 0, @width, WLH, @contents, 0, y)
    @font.draw_blended_utf8(@contents, "R-#{room.id}", 24, y+8, *@color)
    @font.draw_blended_utf8(@contents, room.full? ? "【决斗中】" : room.private? ? "【私密房】" : "【等待中】", 8, y+24, *@color)
    @font.draw_blended_utf8(@contents, room.name, 128, y+8, *room.color)
    @font.draw_blended_utf8(@contents, room.player1.name, 128, y+24, *@color) 
    @font.draw_blended_utf8(@contents, room.player2.name, 256, y+24, *@color) if room.full?
  end
  
  def mousemoved(x,y)
    return unless self.include?(x,y)
    self.index = (y - @y) / WLH + @scroll
  end
end