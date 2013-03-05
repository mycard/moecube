class Window_Announcements < Window
  def initialize(x,y,width,height)
    super(x,y,width,height)
    @index = 0
    @count = 0
    @items = $config[$config['game']]['announcements']
    @last_item = @item = @items.first
    @font = TTF.open(Font, 18)
    @color = [44,64,78]
    @time_color = [0x66, 0x66, 0x66]
    @time_font = TTF.open(Font, 14)
    @transforming = nil
    refresh
  end
  def refresh
    clear
    return unless @item      
    if @transforming and @last_item
      @font.style = TTF::STYLE_NORMAL
      @font.draw_blended_utf8(@contents, @last_item.title, 0, -@transforming, *@color)
      @time_font.draw_blended_utf8(@contents, @last_item.time.strftime('%Y-%m-%d'), 500, -@transforming+4, *@time_color) if @last_item.time
      @font.style = TTF::STYLE_UNDERLINE if @focus
      @font.draw_blended_utf8(@contents, @item.title, 0, -@transforming+24, *@color)
      @time_font.draw_blended_utf8(@contents, @item.time.strftime('%Y-%m-%d'), 500, -@transforming+24+4, *@time_color) if @item.time
    else
      @font.style = @focus ? TTF::STYLE_UNDERLINE : TTF::STYLE_NORMAL
      @font.draw_blended_utf8(@contents, @item.title, 0, 0, *@color)
      @time_font.draw_blended_utf8(@contents, @item.time.strftime('%Y-%m-%d'), 500, 4, *@time_color) if @item.time
    end
  end
  def update
    if @transforming
      refresh
      if @transforming >= 24
        @transforming = nil
        @last_item = @item
      else
        @transforming += 1
      end
    else
      if @last_item != @item
        @transforming = 0
      end
    end
    if @item != $config[$config['game']]['announcements'][@index]
      @items = $config[$config['game']]['announcements']
      @index = 0
      @count = 0
      @item = @items[@index]
    end
    if @focus
      @count = 0
    else
      @count += 1
    end
    if @count>= 180 and !@items.empty?
      @index = (@index + 1) % @items.size
      @count = 0
      @item = @items[@index]
    end
    super
  end
  def clicked
    return unless @item
    Dialog.web @item.url if @item.url
  end
  def mousemoved(x,y)
    if !@focus
      @focus = true
      refresh 
    else
      @focus = true
    end
  end
  def lostfocus(active_window=nil)
    @focus = false
    refresh
  end
end
