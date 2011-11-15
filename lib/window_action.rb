# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_Action < Window_List
  def initialize(x,y,list,list_available=Array.new(list.size, true))
    super(x,y,100,list.size*WLH,300)
    @list = list
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
      @font.draw_blended_utf8(@contents, @list[index] , 0, index*WLH, 0x00,0x00,0x00)
    when 1
      @font.draw_blended_utf8(@contents, @list[index] , 0, index*WLH, 0x00,0x00,0xFF)
    end
  end
  def next
    if index = @list[@index.next...@list.size].find_index(true)
      self.index = index
    elsif index = @list[0..@index].find_index(true)
      self.index = index
    else
      self.index = (@index + 1) % @list.size
    end
  end
  def mousemoved(x,y)
    self.index = (y - @y) / WLH
  end
end
