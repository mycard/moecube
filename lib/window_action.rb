# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_Action < Window_List
  Color = [0x00,0x00,0x00]
  Color_Disabled = [0x66,0x66,0x66]
  Color_Selected = [0x00,0x00,0xFF]
  def initialize(x,y,list,list_available=Array.new(list.size, true))
    super(x,y,100,list.size*WLH,300)
    @list = list
    @list_available = list_available
    @item_max = @list.size
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    refresh
    self.index = @list.find_index(true) || 0
  end
  def index=(index)
    super(index) if index
  end
  def draw_item(index, status=0)
    case status
    when 0
      color = @list_available[index] ? Color : Color_Disabled
      @font.draw_blended_utf8(@contents, @list[index] , 0, index*WLH, *color)
    when 1
      @font.draw_blended_utf8(@contents, @list[index] , 0, index*WLH, *Color_Selected)
    end
  end
  def next
    if index = @list_available[@index.next...@list.size].find_index(true)
      self.index = index + @index.next
    elsif index = @list_available[0..@index].find_index(true)
      self.index = index
    else
      self.index = (@index + 1) % @list.size
    end
  end
  def mousemoved(x,y)
    self.index = (y - @y) / WLH
  end
end
