# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_Action < Window_List
  Color = [0x00,0x00,0x00]
  Color_Disabled = [0x66,0x66,0x66]
  Color_Selected = [0x00,0x00,0xFF]
  def initialize#,list,list_available=Array.new(list.size, true))
    super(0,0,123,20*WLH,300)
    #@skin = Surface.load 'graphics/field/action.png'
    @up = Surface.load 'graphics/field/action_up.png'
    @down = Surface.load 'graphics/field/action_down.png'
    @middle = Surface.load 'graphics/field/action.png'
    @up.set_alpha(RLEACCEL,255)
    @middle.set_alpha(RLEACCEL,255)
    @down.set_alpha(RLEACCEL,255)

    @contents.fill_rect(0,0,@width, @height, 0x22555500)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    @visible = false
  end
  def list=(list)
    if list
      @list = list.keys
      @list_available = list.values
      @height = @viewport[3] = @list.size*WLH+15*2
      @item_max = @list.size
      @index = @list_available.find_index(true) || 0
      
      @contents.put(@up, 0, 0)
      Surface.transform_draw(@middle,@contents,0,1,(@list.size*WLH).to_f/@middle.h,0,0,0,20,Surface::TRANSFORM_SAFE)
      @contents.put(@down, 0, @height-15)
      
      refresh
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
  def clicked
    $scene.player_field_window.clicked
  end
  def lostfocus
  end
end