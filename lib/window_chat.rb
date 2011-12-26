#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Chat < Window
  require_relative 'widget_scrollbar'
  require_relative 'widget_inputbox'
  User_Color = [0,0,0xFF]
  Text_Color = [0,0,0]
	def initialize(x, y, width, height)
    super(x,y,width,height)
    @chat_input = Widget_InputBox.new(416,723,586,24){|text|$game.chat text; add($game.user, text)}
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @contents.fill_rect(0,0,@width, @height, 0xFFFFFFFF)
    @scroll = Widget_ScrollBar.new(@x+@width-20,@y,@height,0)
    @list = []
	end
	def add(user, content)
    @list << [user, content]
    refresh
	end
  def refresh
    @contents.fill_rect(0,0,@width, @height, 0x66FFFFFF)
    @list.last(7).each_with_index do |chat, index|
      user, content = *chat
      @font.draw_blended_utf8(@contents, user.name, 0, index*WLH, *User_Color)
      name_width = @font.text_size(user.name)[0]
      @font.draw_blended_utf8(@contents, ':'+content, name_width, index*WLH, *Text_Color)
    end
  end
end

