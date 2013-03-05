#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================
require_relative 'window_user'
require_relative 'window_scrollable'
class Window_UserList < Window_Scrollable
  attr_reader :x, :y, :width, :height
  WLH = 20
	def initialize(x, y, items)
    #@contents = Surface.load "graphics/lobby/useritems.png"
    #@background = Surface.load "graphics/lobby/useritems.png"
    super(x,y,272,$config['screen']['height'] - 220)
    @font = TTF.open(Font, 16)
    @color = [0x03, 0x11, 0x22]
    @color_friend = [0, 128, 0]
    @color_over = [200,200,255]
    @color_click = [0x03, 0x11, 0x22]
    #@contents.set_alpha(RLEACCEL, 80)
    @contents.fill_rect(0,0,@width,@height,0xFFFFFFFF)
    self.items = items
	end
  def draw_item(index, status=0)
    case status
    when 0
      @font.draw_blended_utf8(@contents, @items[index].name, 0, item_rect(index)[1], *@items[index].color)
    when 1
      @font.draw_shaded_utf8(@contents, @items[index].name, 0, item_rect(index)[1], *(@items[index].color+@color_over))
    when 2
      @font.draw_shaded_utf8(@contents, @items[index].name, 0, item_rect(index)[1], *(@items[index].color+@color_click))
    end
  end
  def clicked
    return unless @index
    @userwindow = Window_User.new(100,100,@items[@index]) 
  end
  def mousemoved(x,y)
    return unless include?(x,y)
    self.index = (y - @y) / WLH + @scroll
  end
end