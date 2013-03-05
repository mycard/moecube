class Widget_ScrollBar < Window
  attr_reader :scroll, :scroll_max
  def initialize(parent_window,x,y,height)
    super(x,y,20,height,400)
    @parent_window = parent_window
    @up_button = Surface.load('graphics/lobby/scroll_up.png')
    @down_button = Surface.load('graphics/lobby/scroll_down.png')
    @back = Surface.load('graphics/lobby/scroll_background.png')
    @bar = Surface.load('graphics/lobby/scroll.png')
    @contents.fill_rect(0,0,@width, @height, 0xFFFFFFFF)
    @scroll ||= 0
    @scroll_max ||= 0
    @scrolling = nil
    Surface.transform_draw(@back,@contents,0,1,@contents.h.to_f/@back.h,0,0,0,0,0) rescue nil
    refresh
  end
  def index=(index)
    return if index == @index
    
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0) 
    end
    if index.nil? #or !@items.include? index
      @index = nil
    else
      @index = index
      draw_item(@index, 1)
    end
  end
  def item_rect(index)
    case index
    when :up
      [0,0,20,20]
    when :scroll
      [0,20,20,@height-40]
    when :down
      [0,@height-20,20,20]
    end
  end
  def draw_item(index, status=0)
    case index
    when :up
      Surface.blit(@up_button,status*20,0,20,20,@contents,0,0)
    when :scroll
      return if @scroll_max.zero?
      Surface.blit(@bar,status*20,0,20,24,@contents,0,20+(@height-40-24)*@scroll/(@scroll_max))
    when :down
      Surface.blit(@down_button,status*20,0,20,20,@contents,0,@height-20)
    end
  end
  def refresh
    clear
    [:up, :scroll, :down].each do |index|
      draw_item(index, @index==index ? 1 : 0)
    end
  end
  def mousemoved(x,y)
    if Mouse.state[2] and @scrolling and @scroll_max > 0
      @parent_window.scroll = [[0, (y - @y - @scrolling) * @scroll_max / (@height-40-24)].max, @scroll_max].min
    end
    case y-@y
    when 0...20 #上按钮
      self.index = :up
    when 20...(@height-20)
      self.index = :scroll
    else
      self.index = :down
    end
  end
  def clicked
    case @index
    when :up
      scroll_up
    when :down
      scroll_down
    when :scroll
      return if @scroll_max.zero?
      y = (@height-40-24)*@scroll/(@scroll_max)
      case Mouse.state[1] - @y - 20
      when 0...y
        scroll_up
      when y..(y+24)
        @scrolling = Mouse.state[1] - @y - y
      else
        scroll_down
      end
    end
  end
  def mouseleftbuttonup
    @scrolling = nil
  end
  def scroll_up
    @parent_window.scroll_up
  end
  def scroll_down
    @parent_window.scroll_down
  end
  def scroll=(scroll)
    return unless scroll and scroll.between?(0,@scroll_max)
    @scroll = scroll
    refresh
  end
  def scroll_max=(scroll_max)
    return unless scroll_max and scroll_max != @scroll_max and scroll_max >=0
    @scroll_max = scroll_max
    if @scroll > @scroll_max
      @scroll = @scroll_max
    end
    refresh
  end
end
