#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_UserList < Window_List
  attr_reader :x, :y, :width, :height
  WLH = 20
	def initialize(x, y, list)
    #@contents = Surface.load "graphics/hall/userlist.png"
    #@background = Surface.load "graphics/hall/userlist.png"
    super(x,y,272,540)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @color = [0x03, 0x11, 0x22]
    @color_over = [0x03, 0x11, 0x22, 200,200,255]
    @color_click = [200,200,255, 0x03, 0x11, 0x22]
    #@contents.set_alpha(RLEACCEL, 80)
    @contents.fill_rect(0,0,@width,@height,0xFFFFFFFF)
    self.list = list
    #@contents.f
	end
  def draw_item(index, status=0)
    case status
    when 0
      @font.draw_blended_utf8(@contents, @list[index].name, 0, index*WLH, *@color)
    when 1
      @font.draw_shaded_utf8(@contents, @list[index].name, 0, index*WLH, *@color_over)
    when 2
      @font.draw_shaded_utf8(@contents, @list[index].name, 0, index*WLH, *@color_click)
    end
  end
  #def clear(x=0, y=0, width=@width, height=@height)
  #  Surface.blit(x, )
  #end
  def item_rect(index)
    [0, WLH*index, @width, WLH]
  end
  def clear(x=0,y=0,width=@width,height=@height)
    @contents.fill_rect(x,y,width,height,0x66FFFFFF)
  end
  def clicked
    #$scene.refresh_rect(*item_rect(@index)){draw_item(@index, 2)} if @index
    @userwindow = Window_User.new(100,100,@list[@index])
  end
  def mousemoved(x,y)
    return unless include?(x,y)
    if (y-@y) / 24 < @item_max
      self.index = (y - @y) / WLH
    end
  end
end