class Window_Config < Window
  def initialize(x,y)
    super(x,y,$screen.w, $screen.h)
    
    @checkbox = Surface.load('graphics/system/checkbox.png')
    @button = Surface.load('graphics/system/button.png')
    @background = Surface.load('graphics/config/background.png').display_format
    @contents = Surface.load('graphics/config/background.png').display_format
    @font = TTF.open(Font, 20)
    @index = nil
    
    @items = {
      :fullscreen => [200,160,120,WLH],
      :bgm => [200,160+WLH,120,WLH],
      :avatar_cache => [200+220, 160+WLH*2,@button.w/3, @button.h],
      :return => [200,160+WLH*3+10,100,WLH]
    }
    refresh
  end
  def draw_item(index, status=0)
    case index
    when :fullscreen
      Surface.blit(@checkbox, 20*status, $config['screen']['fullscreen'] ? 20 : 0, 20, 20, @contents, @items[:fullscreen][0],@items[:fullscreen][1])
      case status
      when 0
        @font.draw_blended_utf8(@contents, "全屏模式", @items[:fullscreen][0]+24, @items[:fullscreen][1], 0xFF,0xFF,0xFF)
      when 1
        @font.draw_shaded_utf8(@contents, "全屏模式", @items[:fullscreen][0]+24, @items[:fullscreen][1], 0xFF,0xFF,0xFF, 0x11, 0x11, 0x11)
      when 2
        @font.draw_shaded_utf8(@contents, "全屏模式", @items[:fullscreen][0]+24, @items[:fullscreen][1], 0x11,0x11,0x11, 0xFF, 0xFF, 0xFF)
      end
    when :bgm
      Surface.blit(@checkbox, 20*status, $config['bgm'] ? 20 : 0, 20, 20, @contents, @items[:bgm][0], @items[:bgm][1])
      case status
      when 0
        @font.draw_blended_utf8(@contents, "背景音乐", @items[:bgm][0]+24, @items[:bgm][1], 0xFF,0xFF,0xFF)
      when 1
        @font.draw_shaded_utf8(@contents, "背景音乐", @items[:bgm][0]+24, @items[:bgm][1], 0xFF,0xFF,0xFF, 0x11, 0x11, 0x11)
      when 2
        @font.draw_shaded_utf8(@contents, "背景音乐", @items[:bgm][0]+24, @items[:bgm][1], 0x11,0x11,0x11, 0xFF, 0xFF, 0xFF)
      end
    when :avatar_cache
      size = 0
      count = 0
      Dir.glob("graphics/avatars/*").reject{|file|File.basename(file) =~ /(?:error|loading)_(?:small|middle|large)\.png/}.each do |file|
        count += 1
        size += File.size(file)
      end
      @font.draw_blended_utf8(@contents, "头像缓存: #{count}个文件, #{filesize_inspect(size)}", 200, @items[:avatar_cache][1], 0xFF,0xFF,0xFF)
      Surface.blit(@button, @button.w/3*status, 0, @button.w/3, @button.h, @contents, @items[:avatar_cache][0],@items[:avatar_cache][1])
      @font.draw_blended_utf8(@contents, "清空", @items[:avatar_cache][0]+10, @items[:avatar_cache][1]+5, 0xFF,0xFF,0xFF)
    when :return
      @font.draw_blended_utf8(@contents, "回到标题画面", @items[:return][0],@items[:return][1], 0xFF,0xFF,0xFF)
    end
    
  end
  def item_rect(index)
    @items[index]
  end
  def index=(index)
    return if index == @index
    
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0) 
    end
    if index.nil? or !@items.include? index
      @index = nil
    else
      @index = index
      clear(*item_rect(@index))
      draw_item(@index, 1)
    end
  end
  def mousemoved(x,y)
    self.index = @items.each do |index, item_rect|
      if x.between?(@x+item_rect[0], @x+item_rect[0]+item_rect[2]) and y.between?(@y+item_rect[1], @y+item_rect[1]+item_rect[3])
        break index
      end
    end
  end
  def refresh
    clear
    @items.each_key{|index|draw_item(index)}
  end
  def clicked
    case @index
    when :fullscreen
      clear(*item_rect(@index))
      $config['screen']['fullscreen'] = !$config['screen']['fullscreen']
      $screen.destroy
      style = HWSURFACE
      style |= FULLSCREEN if $config['screen']["fullscreen"]
      $screen = Screen.open($config['screen']["width"], $config['screen']["height"], 0, style)
      draw_item(@index, 1)
    when :bgm
      clear(*item_rect(@index))
      $config['bgm'] = !$config['bgm']
      if $config['bgm']
        $scene = Scene_Config.new
      else
        $scene.last_bgm = nil
        Mixer.fade_out_music(800) if SDL.inited_system(INIT_AUDIO) != 0
      end
      draw_item(@index, 1)
    when :avatar_cache
      #clear(*item_rect(@index))
      Dir.glob("graphics/avatars/*").reject{|file|File.basename(file) =~ /(?:error|loading)_(?:small|middle|large)\.png/}.each do |file|
        File.delete file
      end
      refresh
      #draw_item(:avatar_cache,1)
    when :return
      $scene = Scene_Title.new
    end
    Config.save
  end
  def filesize_inspect(size)
    case size
    when 0...1024
      size.to_s + "B"
    when 1024...1024*1024
      (size/1024).to_s + "KB"
    else
      (size/1024/1024).to_s + "MB"
    end
  end
end