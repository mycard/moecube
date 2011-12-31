# To change this template, choose Tools | Templates
# and open the template in the editor.

class Window_FieldBack < Window
  def initialize(x,y)
    super(x,y,457,389,100)
  end
  def card=(card)
    return if @card == card
    @card = card
    if card and File.file? file = "graphics/fields/#{card.name}.gif"
      @contents = Surface.load(file).display_format
      self.visible=true
    else
      self.visible=false
    end
  end
end