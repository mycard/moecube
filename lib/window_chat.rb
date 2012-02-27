#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================
require_relative 'widget_scrollbar'
require_relative 'widget_inputbox'
require_relative 'chatmessage'
class Window_Chat < Window_List
  WLH=16
  User_Color = [0,0,0xFF]
  Text_Color = [0,0,0]
  Player_Color = [0,0,0xFF]
  Opponent_Color = [0xFF,0,0]
	def initialize(x, y, width, height)
    super(x,y,width,height)
    if @width > 600 #判断大厅还是房间，这个判据比较囧，待优化
      @chat_background = Surface.load("graphics/system/chat.png").display_format
    else
      @chat_background = Surface.load("graphics/system/chat_room.png").display_format
    end
    
    @background = @contents.copy_rect(0,0,@contents.w,@contents.h) #new而已。。
    @background.fill_rect(0,0,@background.w, @background.h, 0xFFb2cefe)
    @background.put(@chat_background,0,31-4)
    @tab = Surface.load "graphics/system/tab.png"
    @chat_input = Widget_InputBox.new(@x+8, @y+@height-24-10, @width-14, 24) do |message|
      chatmessage = ChatMessage.new($game.user, message, @channel)
      $game.chat chatmessage
      Game_Event.push Game_Event::Chat.new(chatmessage)
    end
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 14)
    @scroll = Widget_ScrollBar.new(self,@x+@width-20-8,@y+31+3,@height-68)
    @@list ||= {}
    self.channel = :lobby
    #self.items = [:lobby]#, User.new(1,"zh99997"), Room.new(1,"测试房间")]
	end
	def add(chatmessage)
    @@list[chatmessage.channel] ||= []
    self.items << chatmessage.channel unless self.items.include? chatmessage.channel
    @@list[chatmessage.channel] << chatmessage
    refresh
	end
  def mousemoved(x,y)
    if y-@y < 31 and (x-@x) < @items.size * 100
      self.index = (x-@x) / 100
    else
      self.index = nil
    end
  end
  def clicked
    self.channel = @items[@index] if @index
  end
  def channel=(channel)
    self.items << channel unless self.items.include? channel
    @channel = channel
    refresh
  end
  
  def draw_item(index, status=0)
    Surface.blit(@tab,0,@channel == @items[index] ? 0 : 31,100,31,@contents,index*100+3,0)
    channel_name = ChatMessage.channel_name @items[index]
    x = index*100+(100 - @font.text_size(channel_name)[0])/2
    draw_stroked_text(channel_name,x,8,1,@font, [255,255,255], ChatMessage.channel_color(@items[index]))
  end
  def item_rect(index)
    [index*100+3, 0, 100, 31]
  end
  def refresh
    super
    return unless @@list[@channel]
    @@list[@channel].last((@height-68)/WLH).each_with_index do |chatmessage, index|
      if chatmessage.name_visible?
        @font.draw_blended_utf8(@contents, chatmessage.user.name+':', 8, index*WLH+31+3, *User_Color)
        name_width = @font.text_size(chatmessage.user.name+':')[0]
      else
        name_width = 0
      end
      @font.draw_blended_utf8(@contents, chatmessage.message, 8+name_width, index*WLH+31+3, *chatmessage.message_color) unless chatmessage.message.empty?
    end
  end
end