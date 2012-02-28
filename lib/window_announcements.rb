class Window_Announcements < Window
  def initialize(x,y,width,height)
    super(x,y,width,height)
    @index = 0
    @count = 0
    @items = $config[$config['game']]['announcements']
    @last_item = @item = @items.first
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 18)
    @color = [44,64,78]
    @transforming = nil
    refresh
  end
  def refresh
    clear
    @index = 0 if !@items[@index]
    if @transforming
      @font.draw_blended_utf8(@contents, @last_item.title, 0, -@transforming, *@color)
      @font.draw_blended_utf8(@contents, @item.title, 0, -@transforming+24, *@color)
    else
      @font.draw_blended_utf8(@contents, @item.title, 0, 0, *@color)
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
    if @item != @items[@index]
      @index = 0
      @count = 0
      @item = @items[@index]
    end
    if @focus
      @count = 0
    else
      @count += 1
    end
    if @count>= 120
      @index = (@index + 1) % @items.size
      @count = 0
      @item = @items[@index]
    end
    super
  end
  def clicked
    require 'launchy'
    Launchy.open(@item.url) if @item.url
  end
  def mousemoved(x,y)
    @focus = true
  end
  def lostfocus(active_window=nil)
    @focus = false
  end
end
