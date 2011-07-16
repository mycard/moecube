class Window_Title
  Button_Count = 5
  Button_Height = 50
  attr_reader :x, :y, :width, :height, :single_height, :index
  def initialize(x,y)
    @x = x
    @y = y
    @button = Surface.load "graphics/system/titlebuttons.png"
    @single_height = @button.h / Button_Count
    @width = @button.w / 3
    @height = Button_Height * Button_Count - (Button_Height - @button.h / Button_Count)
    Button_Count.times do |index|
      Surface.blit(@button, 0, @single_height*index, @width, @single_height, $screen, @x, @y+Button_Height*index)
    end
    @cursor_se = Mixer::Wave.load 'audio/se/cursor.ogg'
  end
  def index=(index)
    return if @index == index
    if @index
      $scene.clear(@x, @y+Button_Height*@index, @width, @single_height)
      Surface.blit(@button, 0,@single_height*@index,@width,@single_height,$screen, @x, @y + Button_Height*@index)
      $screen.update_rect(@x, @y+Button_Height*@index, @width, @single_height)
    end
    if index
      Mixer.play_channel(-1,@cursor_se,0)
      $scene.clear(@x, @y+Button_Height*index, @width, @single_height)
      Surface.blit(@button, @width,@single_height*index,@width,@single_height,$screen, @x, @y + Button_Height*index)
      $screen.update_rect(@x, @y+Button_Height*index, @width, @single_height)
    end
    @index = index
  end
  def click(index=@index)
    @index = index
    if @index
      $scene.clear(@x, @y+Button_Height*@index, @width, @single_height)
      Surface.blit(@button, @width*2,@single_height*@index,@width,@single_height,$screen, @x, @y + Button_Height*@index)
      $screen.update_rect(@x, @y + Button_Height*@index, @width, @single_height)
    end
  end
  def include?(x,y)
    x > @x && x < @x + @width && y > @y && y < @y + @height
  end
  def destroy
    @button.destroy 
  end
end