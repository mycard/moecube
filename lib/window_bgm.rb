require_relative 'window'
class Window_BGM < Window
  def initialize(bgm_name)
    @bgm_name = bgm_name
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 18)
    width = @font.text_size("♪#{@bgm_name}")[0]
    @count = 0
    @contents = @font.render_blended_utf8("♪#{@bgm_name}" , 255,255,255)
    super($config['screen']['width'], 0, width, 24,999)
  end
  def update
    if @count >= 180
      if @x >= $config['screen']['width']
        self.destroy
      else
        self.x += 1.5
      end
    elsif $config['screen']['width'] - @x < @width
      self.x -= 1.5
    else
      @count += 1
    end
  end
end