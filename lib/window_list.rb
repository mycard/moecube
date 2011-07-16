#encoding: UTF-8
#==============================================================================
# ■ Window_RoomList
#------------------------------------------------------------------------------
# 　大厅内房间列表
#==============================================================================

class Window_List
  attr_reader :x, :y, :width, :height
	attr_reader :list
  attr_reader :index
	def initialize(x, y, width, height)
    @x = x
    @y = y
    @width = width
    @height = height
    @o_index = 0
    @item_max = 0
    @column_max = 1
	end
  def index=(index)
    return if index == @index || @item_max.zero?
    $scene.refresh_rect(*item_rect(@index)){draw_item(@index, 0)} if @index
    @index = index
    $scene.refresh_rect(*item_rect(@index)){draw_item(@index, 1)} if @index
  end
  
  
  def draw_item(index, status=0)
    #子类定义
  end
  def item_rect(index)
    #子类定义
  end
	def refresh
    $scene.refresh_rect(@x, @y, @width, @height) do
      @item_max.times do |index|
        draw_item(index)
      end
    end
  end
  def cursor_up
    self.index = @index ? (@index - @column_max) % [@list.size, @item_max].min : 0
  end
  def cursor_down
    self.index = @index ? (@index + @column_max) % [@list.size, @item_max].min : 0
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
  def clicked
    $scene.refresh_rect(*item_rect(@index)){draw_item(@index, 2)} if @index
  end
  def include?(x,y)
    x > @x && x < @x + @width && y > @y && y < @y + @height
  end
end

