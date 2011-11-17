class Window
  WLH = 24
  attr_accessor :x, :y, :width, :height, :z, :contents, :angle, :visible, :viewport
  def initialize(x, y, width, height, z=200)
    @x = x
    @y = y
    @z = z
    @width = width
    @height = height
    @visible = true
    @viewport = [0, 0, @width, @height]
    big_endian = ([1].pack("N") == [1].pack("L"))
=begin
    if big_endian
      rmask = 0xff000000
      gmask = 0x00ff0000
      bmask = 0x0000ff00
      amask = 0x000000ff
    else
      rmask = 0x000000ff
      gmask = 0x0000ff00
      bmask = 0x00ff0000
      amask = 0xff000000
    end
    #p rmask, gmask, bmask, amask
=end
      amask = 0xff000000
      rmask = 0x00ff0000
      gmask = 0x0000ff00
      bmask = 0x000000ff
    unless @background
      @background = Surface.new(SWSURFACE, @width, @height, 32, rmask, gmask, bmask, amask)
      @background.fill_rect(0,0,@width,@height,0x66000000)
    end
    unless @contents
      @contents = Surface.new(SWSURFACE, @width, @height, 32, rmask, gmask, bmask, amask)
      @contents.fill_rect(0,0,@width,@height,0x66000000)
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
    $scene.windows.delete self
  end
  def destroted?
    @destroted
  end
  def clear(x, y, width, height)
    Surface.blit(@background, x,y,width,height,@contents,x,y)
  end
  def update
    #子类定义
  end
  def refresh
    #子类定义
  end
  def mousemoved(x,y)
    #子类定义
  end
  def clicked
    #子类定义
  end
  def lostfocus
    #子类定义
  end
end