#决斗场景中下达动作指令的窗口
class Window_Action < Window_List
  Color = [0xFF,0xFF,0xFF]
  Color_Disabled = [0x66,0x66,0x66]
  Color_Selected = [0xFF,0xFF,0x00]
  def initialize#,items,items_available=Array.new(items.size, true))
    super(0,0,123,20*WLH,300)
    #@skin = Surface.load 'graphics/field/action.png'
    @up = Surface.load('graphics/field/action_up.png')
    @down = Surface.load('graphics/field/action_down.png')
    @middle = Surface.load('graphics/field/action.png')
    @up.set_alpha(RLEACCEL,255)
    @middle.set_alpha(RLEACCEL,255)
    @down.set_alpha(RLEACCEL,255)
    @font = TTF.open(Font, 16)
    @visible = false
  end
  def items=(items)
    if items
      @items = items.keys
      @items_available = items.values
      @height = @viewport[3] = @items.size*WLH+15*2
      @index = @items_available.find_index(true) || 0
      refresh
      @visible = true
    else
      @visible = false
    end
  end
  def clear(x=0,y=0,width=@width,height=@height)
    @contents.put(@up, 0, 0)
    Surface.transform_draw(@middle,@contents,0,1,(@items.size*WLH+20).to_f/@middle.h,0,0,0,15,Surface::TRANSFORM_SAFE) #+那里，我不知道为什么需要这么做，但是如果不+ 内容和底边会有一点空白
    @contents.put(@down, 0, @height-15)
  end
  def index=(index)
    if index and index >= 0 and index < @items.size
      super(index)
      refresh
    end
  end
  def draw_item(index, status=0)
    case status
    when 0
      color = @items_available[index] ? Color : Color_Disabled
      @font.draw_blended_utf8(@contents, @items[index] , (@width-16*6)/2, index*WLH+15, *color)
    when 1
      @font.draw_blended_utf8(@contents, @items[index] , (@width-16*6)/2, index*WLH+15, *Color_Selected)
    end
  end
  def next
    if index = @items_available[@index.next...@items.size].find_index(true)
      self.index = index + @index.next
    elsif index = @items_available[0..@index].find_index(true)
      self.index = index
    else
      self.index = (@index + 1) % @items.size
    end
  end
  def mousemoved(x,y)
    self.index = (y - @y-15) / WLH
  end
  def clicked
    $scene.player_field_window.clicked
  end
  def lostfocus(active_window=nil)
    if active_window != $scene.player_field_window
      $scene.player_field_window.index = nil
    end
  end
end