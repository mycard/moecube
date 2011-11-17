# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_Action < Window_List
  Color = [0x00,0x00,0x00]
  Color_Disabled = [0x66,0x66,0x66]
  Color_Selected = [0x00,0x00,0xFF]
  def initialize#,list,list_available=Array.new(list.size, true))
    super(0,0,100,20*WLH,300)
    @background.fill_rect(0,0,@width, @height, 0xCC555500)
    @contents.fill_rect(0,0,@width, @height, 0xCC555500)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    @visible = false
  end
  def list=(list)
    if list
      @list = list.keys
      @list_available = list.values
      @height = @viewport[3] = @list.size*WLH
      @contents.fill_rect(0,0,@width, @viewport[3], 0xCC555500)
      @item_max = @list.size
      @index = @list_available.find_index(true) || 0
      refresh
      
     #p @index
      @visible = true
    else
      @visible = false
    end
  end

  def index=(index)
    super(index) if index
    #p @index
  end
  def draw_item(index, status=0)
    #p index, status, @index
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
  def lostfocus
  end
end
