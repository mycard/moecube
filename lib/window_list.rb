#encoding: UTF-8
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
    index = nil if index < 0 or index >= @items.size if index
    return if index == @index
    
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0) if @items[@index]
    end
    if index.nil? or index < 0 or index >= @items.size
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
    self.index = @index ? (@index - @column_max) % [@items.size, @items.size].min : 0
  end
  def cursor_down(wrap=false)
     #if @index
    self.index = @index ? ((@index + @column_max) % [@items.size, @items.size].min) : 0
    #p @index, @index + @column_max, [@items.size, @items.size].min, (@index + @column_max) % [@items.size, @items.size].min, @index ? ((@index + @column_max) % [@items.size, @items.size].min) : 0
  end
  def cursor_left
    self.index = @index ? (@index - 1) % [@items.size, @items.size].min : 0
  end
  def cursor_right
    self.index = @index ? (@index + 1) % [@items.size, @items.size].min : 0
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

end

