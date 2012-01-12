class Window
  WLH = 24
  attr_accessor :x, :y, :width, :height, :z, :contents, :angle, :visible, :viewport
  alias visible? visible
  def initialize(x, y, width, height, z=200)
    @x = x
    @y = y
    @z = z
    @width = width
    @height = height
    @visible = true
    @angle = 0
    @viewport = [0, 0, @width, @height]
    @destroyed = false
    amask = 0xff000000
    rmask = 0x00ff0000
    gmask = 0x0000ff00
    bmask = 0x000000ff
    #@background ||= Surface.new(SWSURFACE, @width, @height, 32, rmask, gmask, bmask, amask)
    @contents ||= Surface.new(SWSURFACE, @width, @height, 32, rmask, gmask, bmask, amask)
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
    x >= @x && x < @x + @width && y >= @y && y < @y + @height
  end
  def destroy
    @destroyed = true
    @contents.destroy if @contents
    $scene.windows.delete self if $scene
  end
  def destroyed?
    @destroyed
  end
  def draw(screen)
    if self.contents && self.visible && !self.destroyed?
      if self.angle.zero?
        Surface.blit(self.contents, self.viewport[0], self.viewport[1], self.viewport[2] ,self.viewport[3], screen, self.x, self.y) #直接用*self.viewport，netbeans老给我报错....
      else
        contents = self.contents.transform_surface(0x66000000,180,1,1,0)
        Surface.blit(contents, self.viewport[0], self.viewport[1], self.viewport[2] ,self.viewport[3], screen, self.x, self.y)
        #Surface.transform_blit(window.contents,$screen,0,1,1,100,100,100,100,Surface::TRANSFORM_AA)#,0,0)
      end
    end
  end
  def clear(x=0, y=0, width=@width, height=@height)
    if $scene and $scene.background
      Surface.blit($scene.background,@x+x,@y+y,width,height,@contents,x,y)
    else
      @contents.fill_rect(x,y,width,height,0xFF000000)
    end
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
  def lostfocus(active_window=nil)
    #子类定义
  end
  def cursor_up(wrap=false)
    #子类定义
  end
  def cursor_down(wrap=false)
    #子类定义
  end
  def scroll_up
    cursor_up
  end
  def scroll_down
    cursor_down
  end
end