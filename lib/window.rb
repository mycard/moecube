class Window
  attr_reader :x, :y, :width, :height
  def initialize(x, y, width, height)
    @x = x
    @y = y
    @width = width
    @height = height
  end
  def refresh

  end
  def include?(x,y)
    x > @x && x < @x + @width && y > @y && y < @y + @height
  end
  def dispose
    $scene.refresh_rect(@x, @y, @width, @height)
  end
end