class Window_Join < Window
  attr_reader :index
  def initialize(x,y,room)
    @room = room
    @button = Surface.load("graphics/system/button.png")
    @items = {:ok => [46,110,@button.w/3,@button.h], :cancel => [156,110,@button.w/3, @button.h]}
    @buttons = {:ok => "确定", :cancel => "取消"}
    @background = Surface.load('graphics/system/msgbox.png').display_format
    super((1024-@background.w)/2, 230, @background.w, @background.h)
    @font = TTF.open(Font, 16)
    @title_color = [0xFF, 0xFF, 0xFF]
    @color = [0x04, 0x47, 0x7c]
    @password_inputbox = Widget_InputBox.new(@x+96, @y+41, 165, WLH) do |key|
      case key
      when :ENTER
        clicked
        false
      when :ESC
        true
      end
    end
    @password_inputbox.refresh
    refresh
  end
  def refresh
    clear
    @font.draw_blended_utf8(@contents, "加入私密房间", (@width-@font.text_size("加入私密房间")[0])/2, 2, *@title_color)
    @font.draw_blended_utf8(@contents, "房间密码", 33,43, *@color)
    @items.each_key do |index|
      draw_item(index, self.index==index ? 1 : 0)
    end
    @font.draw_blended_utf8(@contents, "如果确定后创建了新房间，是密码错误", 20,43+WLH, *@color)
  end
  def draw_item(index, status=0)
    Surface.blit(@button,@button.w/3*status,0,@button.w/3,@button.h,@contents,@items[index][0],@items[index][1])
    text_size = @font.text_size(@buttons[index])
    @font.draw_blended_utf8(@contents, @buttons[index], @items[index][0]+(@button.w/3-text_size[0])/2, @items[index][1]+(@button.h-text_size[1])/2, 0xFF, 0xFF, 0xFF)
  end
  def mousemoved(x,y)
    new_index = nil
    @items.each_key do |index|
      if (x - @x).between?(@items[index][0], @items[index][0]+@items[index][2]) and (y-@y).between?(@items[index][1], @items[index][1]+@items[index][3])
        new_index = index
        break
      end
    end
    self.index = new_index
  end
  def item_rect(index)
    @items[index]
  end
  def index=(index)
    return if index == @index
    
    if @index
      clear(*item_rect(@index))
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
      return if @password_inputbox.value.empty?
      @joinroom_msgbox = Widget_Msgbox.new("加入", "正在加入房间")
      destroy
      @room.password = @password_inputbox.value
      $game.join(@room)
    when :cancel
      destroy
    end
  end
  def destroy
    @password_inputbox.destroy
    super
  end
  def update
    @password_inputbox.update
  end
end