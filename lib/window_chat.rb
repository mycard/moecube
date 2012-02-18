#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Chat < Window
  WLH=16
  require_relative 'widget_scrollbar'
  require_relative 'widget_inputbox'
  User_Color = [0,0,0xFF]
  Text_Color = [0,0,0]
  Player_Color = [0,0,0xFF]
  Opponent_Color = [0xFF,0,0]
	def initialize(x, y, width, height, &block)
    super(x,y,width,height-24)
    @chat_input = Widget_InputBox.new(@x, @y+@height, @width, 24, &block)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 14)
    @scroll = Widget_ScrollBar.new(self,@x+@width-20,@y,@height)
    @list = []
	end
	def add(user, content)
    @list << [user, content]
    refresh
	end
  def refresh
    clear
    @list.last(@height/WLH).each_with_index do |chat, index|
      user, content = chat
      if user.is_a? User
        @font.draw_blended_utf8(@contents, user.name+':', 0, index*WLH, *User_Color)
        name_width = @font.text_size(user.name+':')[0]
        color = Text_Color
      else
        name_width = 0
        color = user ? Player_Color : Opponent_Color
      end
      @font.draw_blended_utf8(@contents, content, name_width, index*WLH, *color) unless content.empty?
    end
  end
end