require_relative 'window_list'
class Window_Title < Window_List
  Button_Count = 5
  WLH = 50
  attr_reader :x, :y, :width, :height, :single_height, :index
  def initialize(x,y,img="graphics/system/titlebuttons.png")
    @button = Surface.load(img)
    @button.set_alpha(RLEACCEL,255)
    @single_height = @button.h / Button_Count
    super(x,y,@button.w / 3,WLH * Button_Count - (WLH - @button.h / Button_Count))
    @cursor_se = (Mixer::Wave.load 'audio/se/cursor.ogg' if SDL.inited_system(INIT_AUDIO) != 0) rescue nil
    self.items = [:决斗开始, :单人模式, :卡组编成, :选项设置, :退出游戏]
  end
  def index=(index)
    if index and @index != index
      Mixer.play_channel(-1,@cursor_se,0) if @cursor_se
    end
    super
  end
  def mousemoved(x,y)
    self.index = (y - @y) / WLH
  end
  def draw_item(index, status=0)
    Surface.blit(@button, @width*status, @single_height*index, @width, @single_height, @contents, 0, WLH*index)
  end
  def clicked
    $scene.determine if $scene.is_a? Scene_Title
  end
  def clear(x=0,y=0,width=@width,height=@height)
    @contents.fill_rect(x,y,width, height, 0x00000000)
  end
end