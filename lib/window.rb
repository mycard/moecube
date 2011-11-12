class Window
  attr_reader :x, :y, :width, :height, :z, :contents
  def initialize(x, y, width, height, z=200)
    @x = x
    @y = y
    @z = z
    @width = width
    @height = height
    unless @background
      @background = Surface.new(SWSURFACE|SRCALPHA, @width, @height, 32, 0xFF0000, 0x00FF00, 0x0000FF, 0xFF000000)
      @background.fill_rect(0,0,@width,@height,0xFF00FF00)
    end
    unless @contents
      @contents = Surface.new(SWSURFACE|SRCALPHA, @width, @height, 32, 0xFF0000, 0x00FF00, 0x0000FF, 0xFF000000)
      @contents.fill_rect(0,0,@width,@height,0xFF00FF00)
    end
    #按Z坐标插入
    unless $scene.windows.each_with_index do |window, index|
        if window.z > @z
          $scene.windows.insert(index, self)
          break true
        end
      end == true
      $scene.windows << self
    end
    
  end

  def include?(x,y)
    x > @x && x < @x + @width && y > @y && y < @y + @height
  end
  def destroy
    @destroted = true
    @contents.destroy if @contents
  end
  def destroted?
    @destroted
  end
  def update
    #子类定义
  end
  def refresh
    #子类定义
  end
  def clear(x, y, width, height)
    Surface.blit()
      @contents.put(background.put
  end
end