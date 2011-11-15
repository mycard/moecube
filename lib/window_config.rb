class Window_Config < Window
  def initialize(x,y)
    super(x,y,$screen.w, $screen.h)
    
    @checkbox = Surface.load 'graphics/system/checkbox.png'
    @button = Surface.load 'graphics/system/button.png'
    @background = Surface.load 'graphics/config/background.png'
    @contents = Surface.load 'graphics/config/background.png'
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 20)
    @index = nil
    
    @items = {
      :fullscreen => [0,0,120,WLH],
      :avatar_cache => [220, WLH,@button.w/3, @button.h],
      :return => [0,WLH*2,100,WLH]
    }
    refresh
  end
  def draw_item(index, status=0)
    case index
    when :fullscreen
      clear(0,0,100,WLH)
      Surface.blit(@checkbox, 20*status, $config["fullscreen"] ? 20 : 0, 20, 20, @contents, 0, 0)
      case status
      when 0
        @font.draw_blended_utf8(@contents, "全屏模式", WLH, 0, 0x00,0x00,0x00)
      when 1
        @font.draw_shaded_utf8(@contents, "全屏模式", WLH, 0, 0x00,0x00,0x00, 0xEE, 0xEE, 0xEE)
      when 2
        @font.draw_shaded_utf8(@contents, "全屏模式", WLH, 0, 0xEE,0xEE,0xEE, 0x00, 0x00, 0x00)
      end
    when :avatar_cache
      clear(0,WLH,220+@button.w/3,@button.h)
      size = 0
      count = 0
      Dir.glob("graphics/avatars/*_*.png") do |file|
        count += 1
        size += File.size(file)
      end
      @font.draw_blended_utf8(@contents, "头像缓存: #{count}个文件, #{filesize_inspect(size)}", 0, WLH, 0x00,0x00,0x00)
      Surface.blit(@button, @button.w/3*status, 0, @button.w/3, @button.h, @contents, 220, WLH)
    when :return
      @font.draw_blended_utf8(@contents, "回到标题画面", 0, WLH*2, 0x00,0x00,0x00)
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
    if index.nil? or index.is_a?(Emulator)
      @index = nil
    else
      @index = index
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
    @items.each_key{|index|draw_item(index)}
  end
  def clicked
    case @index
    when :fullscreen
      clear(*item_rect(@index))
      $config["fullscreen"] = !$config["fullscreen"]
      $screen.destroy
      style = HWSURFACE
      style |= FULLSCREEN if $config["fullscreen"]
      $screen = Screen.open($config["width"], $config["height"], 0, style)
      draw_item(@index, 2)
    when :avatar_cache
      Dir.glob("graphics/avatars/*_*.png") do |file|
        File.delete file
      end
      draw_item(:avatar_cache)
    when :return
      File.open("config.yml","w") do |config| 
        YAML.dump($config, config) 
      end 
      $scene = Scene_Title.new
    end
  end
end