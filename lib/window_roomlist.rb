#encoding: UTF-8
#==============================================================================
# ■ Window_RoomList
#------------------------------------------------------------------------------
# 　大厅内房间列表
#==============================================================================

class Window_RoomList < Window_List
	attr_reader :list
  WLH = 48
	def initialize(x, y, list)
    @button = Surface.load 'graphics/hall/room.png'
    @button.set_alpha(RLEACCEL, 255)
    #@background = Surface.load 'graphics/hall/roomlist.png'
    #@contents = Surface.load 'graphics/hall/roomlist.png'
    super(x,y,@button.w / 3, 48 * 10)
    @item_max = 0
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @color = [0x03, 0x11, 0x22]
    @scroll = Widget_ScrollBar.new(@x+@width,@y,@height,0)
    self.list = list
	end

  def draw_item(index, status=0)
    room = @list[index]
    Surface.blit(@button, @width*status, room.full? ? WLH : 0, @width, WLH, @contents, 0, WLH*index)
    @font.draw_blended_utf8(@contents, "R-#{room.id}", 24, WLH*index+8, *@color)
    @font.draw_blended_utf8(@contents, room.full? ? "【决斗中】" : room.private? ? "【私密房】" : "【等待中】", 8, WLH*index+24, *@color)
    @font.draw_blended_utf8(@contents, room.name, 128, WLH*index+8, *room.color)
    @font.draw_blended_utf8(@contents, room.player1.name, 128, WLH*index+24, *@color) 
    @font.draw_blended_utf8(@contents, room.player2.name, 256, WLH*index+24, *@color) if room.full?
  end
  
  def item_rect(index)
    [@x, WLH*index, @width, WLH]
  end
  def mousemoved(x,y)
    return unless include?(x,y)
    self.index = (y - @y) / WLH
  end
end

