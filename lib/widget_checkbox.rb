# To change this template, choose Tools | Templates
# and open the template in the editor.

class Widget_checkbox
  def initialize(window, text, x,y,width=window.width-x,height=20,checked=false)
    @x = x
    @y = y
    @text = text
    @window = window
    @checked = checked
    @checkbox = Surface.load 'graphics/system/checkbox.png'
  end
  def mouseover(x,y)
    
  end
  def refresh
    
  end
end
