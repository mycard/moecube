# To change this template, choose Tools | Templates
# and open the template in the editor.

class Widget_Checkbox < Window
  attr_reader :checked
  alias checked? checked
  def initialize(window,x,y,width=window.width-x,height=24,checked=false,text="",&proc)
    super(x+2,y+2,width,height,500) #+2是素材尺寸问题
    @window = window
    @text = text
    @checked = checked
    @checkbox = Surface.load('graphics/system/checkbox.png').display_format
    @font = TTF.open(Font, 20)
    @proc = proc
    refresh
  end
  def checked=(checked)
    @checked = checked
    refresh
  end
  def mousemoved(x,y)
    if x-@x < 24
      @index = 0
    else
      @index = nil
    end
  end
  def clicked
    if @index
      @checked = !@checked
      @proc.call(@checked) if @proc
    end
    refresh
  end
  def refresh
    clear
    Surface.blit(@checkbox, 0, @checked ? @checkbox.h/2 : 0, @checkbox.w/3, @checkbox.h/2, self.contents, 0, 0)
    @font.draw_blended_utf8(self.contents, @text, 24, 0, 0xFF, 0xFF, 0xFF)
  end
  #def clear(x=0,y=0,width=@width,height=@height)
  #  Surface.blit(@window.contents, @x-@window.x+x, @y-@window.y+y, width,height, self.contents, x, y)
  #end
end
