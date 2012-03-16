require_relative 'window_list'
class Window_Scrollable < Window_List
  attr_reader :scroll
  attr_accessor :scrollbar
  def initialize(x, y, width, height, z=200)
    super(x, y, width, height, z)
    @page_size ||= @height / self.class::WLH
    @scroll ||= 0
  end
  def cursor_up(wrap=false)
    return unless wrap or @index.nil? or @index > 0
    self.index = @index ? (@index - @scroll - 1) % @items.size + @scroll : @scroll
  end
  def cursor_down(wrap=false)
    return unless wrap or @index.nil? or @index < @items.size-1
    self.index = @index ? (@index - @scroll + 1) % @items.size + @scroll : @scroll
  end
  def scroll_up
    cursor_up(false)
    self.scroll -= 1
  end
  def scroll_down
    cursor_down(false)
    self.scroll += 1
  end
  def scroll=(scroll)
    return unless scroll != @scroll and scroll and scroll >= 0 and scroll <= @items.size - @page_size
    #有背景的不能这么用....
    #if scroll > @scroll
    #  Surface.blit(@contents, 0, self.class::WLH * (scroll - @scroll), @width, (@page_size - (scroll - @scroll)) * self.class::WLH, @contents, 0, 0)
    #  clear(0, @page_size - (scroll - @scroll) * self.class::WLH, @width, self.class::WLH * (scroll - @scroll))
    #else
    #  Surface.blit(@contents, 0, 0, @width, (@page_size - (scroll - @scroll)) * self.class::WLH, @contents, 0, self.class::WLH * (scroll - @scroll))
    #  clear(0, 0, @width, self.class::WLH * (scroll - @scroll))
    #end
    @scroll = scroll
    refresh
  end
  def refresh
    clear
    (@scroll...[(@scroll+@page_size), @items.size].min).each{|index|draw_item(index, @index == index ? 1 : 0)}
    if @scrollbar
      @scrollbar.scroll_max = [@items.size - @page_size, 0].max 
      @scrollbar.scroll = @scroll
    end
  end
  def item_rect(index)
    [0, (index-@scroll)*self.class::WLH, @width, self.class::WLH]
  end
end
