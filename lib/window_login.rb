#encoding: UTF-8
require_relative 'widget_inputbox'
require_relative 'widget_msgbox'
class Window_Login < Window
  def initialize(x,y,username=nil, password=nil)
    @username = username
    @password = password
    @button = Surface.load("graphics/login/button.png")
    super(x,y,597,338)
    @username_inputbox = Widget_InputBox.new(@x+192, @y+80, 165, WLH)
    @username_inputbox.value = @username if @username
    @password_inputbox = Widget_InputBox.new(@x+192, @y+125, 165, WLH)
    @password_inputbox.type = :password
    @password_inputbox.value = @password if @password
    @color = [255,255,255]
    @color_stroke = [0,0,0]
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @font_button = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 18)
    #@font.draw_blended_utf8(@contents, text, 105,80, *@game_color)
    @items = {
      #:username => [192,80,165,WLH],
      #:password => [192,125,165,WLH],
      :login => [192,200,80,36],
      :register => [285,200,80,36]
    }
    @items_text = {
      :login => "登陆",
      :register => "注册"
    }
    #self.index = nil
    refresh
  end
  def draw_stroked_text(text,x,y,size=1,font=@font)
    [[x-size,y-size], [x-size,y], [x-size,y+size],
      [x,y-size], [x,y+size],
      [x+size,y-size], [x+size,y], [x+size,y+size],
    ].each{|pos|font.draw_blended_utf8(@contents, text, pos[0], pos[1], *@color)}
    font.draw_blended_utf8(@contents, text, x, y, *@color_stroke)
  end
  def refresh
    clear
    @items.each_pair{|index, rect|draw_item(index, rect)}
    draw_stroked_text("用户名", 105,80+2,1)
    draw_stroked_text("密码", 105,125+2,1)
  end
  def draw_item(index, rect, status=0)
    Surface.blit(@button,0,0,rect[2],rect[3],@contents,rect[0],rect[1])
    draw_stroked_text(@items_text[index], rect[0]+20, rect[1]+9,1,@font_button)
  end
  def mousemoved(x,y)
    @items.each_pair{|index, rect|return self.index = index if (x-@x >= rect[0] and x-@x < rect[0]+rect[2] and y-@y >= rect[1] and y-@y < rect[1]+rect[3])}
  end
  def index=(index)
    return if @index == index
    @index = index
  end
end
