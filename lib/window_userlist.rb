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
    #@contents = Surface.load "graphics/hall/useritems.png"
    #@background = Surface.load "graphics/hall/useritems.png"
    super(x,y,272,540)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @color = [0x03, 0x11, 0x22]
    @color_over = [0x03, 0x11, 0x22, 200,200,255]
    @color_click = [200,200,255, 0x03, 0x11, 0x22]
    #@contents.set_alpha(RLEACCEL, 80)
    @contents.fill_rect(0,0,@width,@height,0xFFFFFFFF)
    self.items = items
    #@contents.f
	end
  def draw_item(index, status=0)
    case status
    when 0
      @font.draw_blended_utf8(@contents, @items[index].name, 0, item_rect(index)[1], *@color)
    when 1
      @font.draw_shaded_utf8(@contents, @items[index].name, 0, item_rect(index)[1], *@color_over)
    when 2
      @font.draw_shaded_utf8(@contents, @items[index].name, 0, item_rect(index)[1], *@color_click)
    end
  end
  #def clear(x=0, y=0, width=@width, height=@height)
  #  Surface.blit(x, )
  #end

 #def clear(x=0,y=0,width=@width,height=@height)
  #  @contents.fill_rect(x,y,width,height,0x66FFFFFF)
  #end
  def clicked
    #$scene.refresh_rect(*item_rect(@index)){draw_item(@index, 2)} if @index
    return unless @index
    @userwindow = Window_User.new(100,100,@items[@index]) 
  end
  def mousemoved(x,y)
    return unless include?(x,y)
    self.index = (y - @y) / WLH + @scroll
  end
end