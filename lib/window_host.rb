class Window_Host < Window
  attr_reader :index
  def initialize(x,y)
    @button = Surface.load("graphics/system/button.png")
    @items = {:ok => [116,114,@button.w/3,@button.h]}
    @buttons = {:ok => "确定"}
    @background = Surface.load('graphics/system/msgbox.png').display_format
    super((1024-@background.w)/2, 230, @background.w, @background.h)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 16)
    @title_color = [0xFF, 0xFF, 0xFF]
    @color = [0x04, 0x47, 0x7c]
    @roomname_inputbox = Widget_InputBox.new(@x+96, @y+41, 165, WLH){clicked;false}
    default_name = $game.user.name
    1.upto(1000) do |i|
      if $game.rooms.all?{|room|room.name != i.to_s}
        break default_name = i.to_s
      end
    end
    @roomname_inputbox.value = default_name
    @pvp = Widget_Checkbox.new(self, 33+@x,70+@y,120,24,false,"竞技场")
    @pvp.background = @background.copy_rect(33,70,120,24)
    @match = Widget_Checkbox.new(self, 120+@x,70+@y,120,24,true,"三回决斗")
    @match.background = @background.copy_rect(120,70,120,24)
    @pvp.refresh
    @match.refresh
    refresh
  end
  def refresh
    clear
    @font.draw_blended_utf8(@contents, "新房间", (@width-@font.text_size("新房间")[0])/2, 2, *@title_color)
    @font.draw_blended_utf8(@contents, "房间名", 33,43, *@color)
    draw_item(:ok, self.index==:ok ? 1 : 0)
  end
  def draw_item(index, status=0)
    Surface.blit(@button,@button.w/3*status,0,@button.w/3,@button.h,@contents,@items[index][0],@items[index][1])
    text_size = @font.text_size(@buttons[index])
    @font.draw_blended_utf8(@contents, @buttons[index], @items[index][0]+(@button.w/3-text_size[0])/2, @items[index][1]+(@button.h-text_size[1])/2, 0xFF, 0xFF, 0xFF)
  end
  def mousemoved(x,y)
    if (x - @x).between?(@items[:ok][0], @items[:ok][0]+@items[:ok][2]) and (y-@y).between?(@items[:ok][1], @items[:ok][1]+@items[:ok][3])
      self.index = :ok
    else
      self.index = nil
    end
  end
  def index=(index)
    return if index == @index
    
    if @index
      #clear(*item_rect(@index))
      draw_item(@index, 0) 
    end
    if index.nil? or !@items.include? index
      @index = nil
    else
      @index = index
      draw_item(@index, 1)
    end
  end
  def clicked
    case self.index
    when :ok
      return if @roomname_inputbox.value.empty?
      @joinroom_msgbox = Widget_Msgbox.new("建立房间", "正在建立房间")
      destroy
      $game.host(@roomname_inputbox.value, :pvp => @pvp.checked?, :match => @match.checked?)
    end
  end
  def destroy
    @roomname_inputbox.destroy
    @pvp.destroy
    @match.destroy
    super
  end
end