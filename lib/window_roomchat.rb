#encoding: UTF-8
require_relative 'scene_watch'
class Window_RoomChat < Window
  WLH=16
  require_relative 'widget_scrollbar'
  Player_Color = [0,0,0xFF]
  Opponent_Color = [0,0x66,0]
	def initialize(x, y, width, height)
    super(x,y,width,height-24)
    @chat_input = Widget_InputBox.new(@x,@y+@height,@width,24) do |text|
      action = Action::Chat.new(true, text)
      if $scene.is_a?(Scene_Watch)
        action.id = :观战
        $game.action action
      else
        $scene.action action
      end
    end
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 14)
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
      @font.draw_blended_utf8(@contents, content.empty? ? " " : content, 0, index*WLH, *(player ? Player_Color : Opponent_Color))
    end
  end
end
