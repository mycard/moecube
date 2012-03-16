#==============================================================================
# ■ Window_Roomitems
#------------------------------------------------------------------------------
# 　大厅内房间列表
#==============================================================================
require_relative 'window'
class Window_List < Window
	attr_reader :items
  attr_reader :index
	def initialize(x, y, width, height, z=200)
    @items ||= []
    @index ||= nil
    super(x,y,width, height,z)
	end
  def index=(index)
    index = nil unless index_legal?(index)
    return if index == @index
    
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0) if index_legal?(@index)
    end
    if index.nil?
      @index = nil
    else
      @index = index
      draw_item(@index, 1)
    end
  end
  
  
  def draw_item(index, status=0)
    #子类定义
  end
  def item_rect(index)
    [0, index*self.class::WLH, @width, self.class::WLH]
  end
  def items=(items)
    @items = items
    refresh
  end
  def refresh
    clear
    @items.each_index {|index|draw_item(index, index==@index ? 1 : 0)}
  end
  def cursor_up(wrap=false)
    return unless wrap or @index.nil? or @index > 0
    self.index = @index ? (@index - 1) % @items.size : 0
  end
  def cursor_down(wrap=false)
    return unless wrap or @index.nil? or @index < @items.size-1
    self.index = @index ? (@index +  1) % @items.size : 0
  end
  def cursor_left(wrap=false)
    cursor_up(wrap)
  end
  def cursor_right(wrap=false)
    cursor_down(wrap)
  end
  def mousemoved(x,y)
    #子类定义
    #return unless include?(x,y)
    #self.index = (y - @y) / @single_height
  end
  def lostfocus(active_window=nil)
    self.index = nil
  end
  def clicked
    #子类定义
  end
  def index_legal?(index)
    index.nil? or (index >= 0 and index < @items.size)
  end
end

