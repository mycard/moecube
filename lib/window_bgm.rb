require_relative 'window'
class Window_BGM < Window
  WLH=20
  def initialize(bgm_name)
    @bgm_name = bgm_name
    @font = TTF.open(Font, 18)
    width = @font.text_size("♪#{@bgm_name}")[0]
    @count = 0
    @contents = @font.render_blended_utf8("♪#{@bgm_name}" , 255,255,255)
    super($config['screen']['width']-width, -WLH, width, WLH,999)
  end
  def update
    if @count >= 180
      if @y <= -WLH
        self.destroy
      else
        self.y -= 1
      end
    elsif @y < 0
      self.y += 1
    else
      @count += 1
    end
  end
end