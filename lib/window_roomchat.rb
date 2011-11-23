# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_RoomChat < Window
  require_relative 'widget_scrollbar'
  Player_Color = [0,0,0xFF]
  Opponent_Color = [0x66,0x66,0]
	def initialize(x, y, width, height)
    super(x,y,width,height-WLH)
    @chat_input = Widget_InputBox.new(@x,@y+@height,@width,WLH){|text|Action::Chat.new(true, text).run}
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @contents.fill_rect(0,0,@width, @height, 0x99FFFFFF)
    @scroll = Widget_ScrollBar.new(@x+@width-20,@y,@height,0)
    @list = []
    $chat_window = self
	end
  def add(player, content)
    @list << [player, content]
    refresh
	end
  def refresh
    @contents.fill_rect(0,0,@width, @height, 0x99FFFFFF)
    @list.last(7).each_with_index do |chat, index|
      player, content = chat
      @font.draw_blended_utf8(@contents, content, 0, index*WLH, *(player ? Player_Color : Opponent_Color))
    end
  end
end
