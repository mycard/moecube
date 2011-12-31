#encoding: UTF-8
#==============================================================================
# ■ Window_RoomList
#------------------------------------------------------------------------------
# 　大厅内房间列表
#==============================================================================
require_relative 'window'
class Window_List < Window
	attr_reader :list
  attr_reader :index
	def initialize(x, y, width, height, z=200)
    @list ||= []
    @index ||= nil
    super(x,y,width, height,z)
    @o_index = 0
    @item_max = 0
    @column_max = 1
	end
  def index=(index)
    index = nil if index < 0 or index >= @item_max if index
    return if index == @index
    
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0) 
    end
    if index.nil? or index < 0 or index >= @item_max
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
    [0, @index*self.class::WLH, @width, self.class::WLH]
  end
  def list=(list)
    @list = list
    @item_max = @list.size
    refresh
  end
  def refresh
    clear
    @item_max.times {|index|draw_item(index, index==@index ? 1 : 0)}
  end
  def cursor_up
    self.index = @index ? (@index - @column_max) % [@list.size, @item_max].min : 0
  end
  def cursor_down
     #if @index
    self.index = @index ? ((@index + @column_max) % [@list.size, @item_max].min) : 0
    #p @index, @index + @column_max, [@list.size, @item_max].min, (@index + @column_max) % [@list.size, @item_max].min, @index ? ((@index + @column_max) % [@list.size, @item_max].min) : 0
  end
  def cursor_left
    self.index = @index ? (@index - 1) % [@list.size, @item_max].min : 0
  end
  def cursor_right
    self.index = @index ? (@index + 1) % [@list.size, @item_max].min : 0
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

