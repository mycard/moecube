#encoding: UTF-8
require_relative 'window_host'
class Window_LobbyButtons < Window_List
  def initialize(x,y)
    super(x,y,86,30)
    @items = ["新房间"]
    @button = Surface.load("graphics/lobby/button.png")
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    refresh
  end
  def draw_item(index, status=0)
    Surface.blit(@button, status*@button.w/3,0,@button.w/3,@button.h, @contents, 0, 0)
    @font.draw_blended_utf8(@contents,"新房间",16,5,20,10,180)
  end
  def mousemoved(x,y)
    self.index = 0
  end
  def lostfocus(active_window = nil)
    self.index = nil
  end
  def clicked
    Window_Host.new(300,200)
  end
end
