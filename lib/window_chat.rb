#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================
require_relative 'widget_scrollbar'
require_relative 'widget_inputbox'
require_relative 'chatmessage'
require_relative 'window_scrollable'
class Window_Chat < Window_Scrollable
  WLH=16
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
    @chat_input = Widget_InputBox.new(@x+8, @y+@height-24-10, @width-14, 24) do |key|
      case key
      when :ENTER
        if !@chat_input.value.empty?
          chatmessage = ChatMessage.new($game.user, @chat_input.value, @channel)
          $game.chat chatmessage
          Game_Event.push Game_Event::Chat.new(chatmessage) if @channel != :lobby
          true
        end
      end
    end
    @chat_input.refresh
    @font = TTF.open(Font, 14)
    @scrollbar = Widget_ScrollBar.new(self,@x+@width-20-8,@y+31+3,@height-68)
    @page_size = (@height-68)/WLH
    @@list ||= {}
    @list_splited = {}
    @@list.each_pair do |channel, chatmessages|
      chatmessages.each do |chatmessage|
        add_split(chatmessage)
      end
    end
    @channels = []
    self.channel = :lobby
	end
	def add(chatmessage)
    @@list[chatmessage.channel] ||= []
    unless @channels.include? chatmessage.channel
      @channels << chatmessage.channel
      refresh
    end
    @@list[chatmessage.channel] << chatmessage
    scroll_bottom = @items.size - self.scroll <= @page_size
    add_split(chatmessage)
    if chatmessage.channel == @channel
      @scroll = [@items.size - @page_size, 0].max if scroll_bottom
      refresh
    end
  end
  def add_split(chatmessage)
    @list_splited[chatmessage.channel] ||= []
    @list_splited[chatmessage.channel] << [chatmessage, ""]
    width = name_width(chatmessage)
    line = 0
    chatmessage.message.each_char do |char|
      if char == "\n"
        line += 1
        width = 0
        @list_splited[chatmessage.channel] << [chatmessage.message_color, ""]
      else
        char_width = @font.text_size(char)[0]
        if char_width + width > @width-14-20
          line += 1
          width = char_width
          @list_splited[chatmessage.channel] << [chatmessage.message_color, char]
        else
          @list_splited[chatmessage.channel].last[1] << char
          width +=  char_width
        end
      end
    end
  end
  def mousemoved(x,y)
    if y-@y < 31 and (x-@x) < @channels.size * 100
      self.index = @channels[(x-@x) / 100]
    else
      self.index = nil
    end
  end
  def clicked
    case @index
    when nil
    when Integer
    else
      self.channel = @index
    end
  end
  def channel=(channel)
    return if @channel == channel
    @channel = channel
    @channels << channel unless @channels.include? channel
    @list_splited[channel] ||= []
    @items = @list_splited[channel]
    @scroll = [@items.size - @page_size, 0].max
    refresh
  end
  
  def draw_item(index, status=0)
    case index
    when nil
    when Integer #描绘聊天消息
      draw_item_chatmessage(index, status)
    else #描绘频道标签
      draw_item_channel(index, status)
    end
  end
  def draw_item_channel(channel, status)
    index = @channels.index(channel)
    Surface.blit(@tab,0,@channel == channel ? 0 : 31,100,31,@contents,index*100+3,0)
    channel_name = ChatMessage.channel_name channel
    x = index*100+(100 - @font.text_size(channel_name)[0])/2
    draw_stroked_text(channel_name,x,8,1,@font, [255,255,255], ChatMessage.channel_color(channel))
  end
  def draw_item_chatmessage(index, status)
    x,y = item_rect_chatmessage(index)
    chatmessage, message = @items[index]
    if chatmessage.is_a? ChatMessage
      @font.draw_blended_utf8(@contents, chatmessage.user.name+':', x, y, *chatmessage.name_color) if chatmessage.name_visible?
      @font.draw_blended_utf8(@contents, message, x+name_width(chatmessage), y, *chatmessage.message_color) unless chatmessage.message.lines.first.chomp.empty?
    else
      @font.draw_blended_utf8(@contents, message, x, y, *chatmessage) unless message.empty?
    end
  end
  def item_rect(index)
    case index
    when nil
    when Integer #描绘聊天消息
      item_rect_chatmessage(index)
    else #描绘频道标签
      item_rect_channel(index)
    end
  end
  def item_rect_channel(channel)
    [@channels.index(channel)*100+3, 0, 100, 31]
  end
  def item_rect_chatmessage(index)
    [8, (index-@scroll)*WLH+31+3, @width, self.class::WLH]
  end
  def refresh
    super
    @channels.each {|channel|draw_item_channel(channel, @index==channel)}
  end
  def name_width(chatmessage)
    chatmessage.name_visible? ? @font.text_size(chatmessage.user.name+':')[0] : 0
  end
  def index_legal?(index)
    case index
    when nil,Integer
      super
    else
      @channels.include? index
    end
  end
  def scroll_up
    self.scroll -= 1
  end
  def scroll_down
    self.scroll += 1
  end
  def update
    @chat_input.update
  end
end