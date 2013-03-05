require_relative 'widget_inputbox'
require_relative 'widget_msgbox'
require_relative 'widget_checkbox'
class Window_Login < Window
  def initialize(x,y,username=nil, password=nil)
    @username = username
    @password = password
    @button = Surface.load("graphics/login/button.png")
    super(x,y,597,338)
    @username_inputbox = Widget_InputBox.new(@x+192, @y+80, 165, WLH) do |key|
      case key
      when :TAB
        @password_inputbox.clicked
        false
      when :ESC
        true
      end
    end
    @username && !@username.empty? ? @username_inputbox.value = @username : @username_inputbox.refresh
    @password_inputbox = Widget_InputBox.new(@x+192, @y+125, 165, WLH) do |key|
      case key
      when :TAB
        self.index=:login
        false
      when :ENTER
        self.index=:login
        self.clicked
        false
      when :ESC
        true
      end
    end
    @password_inputbox.type = :password
    @password && !@password.empty? ? @password_inputbox.value = @password : @password_inputbox.refresh
    @color = [255,255,255]
    @color_stroke = [0,0,0]
    @font = TTF.open(Font, 16)
    @font_button = TTF.open(Font, 18)
    #@font.draw_blended_utf8(@contents, text, 105,80, *@game_color)
    @items = {
      #:username => [192,80,165,WLH],
      #:password => [192,125,165,WLH],
      :login => [192,200,@button.w/3,@button.h],
      :register => [285,200,@button.w/3,@button.h],
      :replay => [378,200,@button.w/3,@button.h]
    }
    @items_text = {
      :login => I18n.t("login.login"),
      :register => I18n.t("login.register"),
      :replay => I18n.t("login.replay"),
    }
    #self.index = nil
    @remember_password = Widget_Checkbox.new(self, 357+@x,80+@y,self.width-357,24,password,I18n.t('login.remember'))
    refresh
  end
  def refresh
    clear
    @items.each_pair{|index, rect|draw_item(index, rect)}
    draw_stroked_text(I18n.t('login.name'), 105,80+2,1)
    draw_stroked_text(I18n.t('login.password'), 105,125+2,1)
  end
  def draw_item(index, rect, status=0)
    Surface.blit(@button,rect[2]*status,0,rect[2],rect[3],@contents,rect[0],rect[1])
    draw_stroked_text(@items_text[index], rect[0] + center_margin(@items_text[index], rect[2], @font_button), rect[1]+9,1,@font_button)
  end
  def mousemoved(x,y)
    self.index = @items.each_pair{|index, rect|break index if (x-@x >= rect[0] and x-@x < rect[0]+rect[2] and y-@y >= rect[1] and y-@y < rect[1]+rect[3])}
  end
  def lostfocus(active_window=nil)
    self.index = nil
  end
  def item_rect(index)
    @items[index]
  end
  def index=(index)
    index = nil if !@items.has_key?(index)
    return if @index == index
    if @index
      clear(*item_rect(@index))
      draw_item(@index, item_rect(@index), 0)
    end
    @index = index
    if @index
      clear(*item_rect(@index))
      draw_item(@index, item_rect(@index), 1)
    end
  end
  def update
    @username_inputbox.update
    @password_inputbox.update
  end
  #def destroy
  #  @username_inputbox.destroy
  #  @password_inputbox.destroy
  #  super
  #end
end
