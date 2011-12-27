#encoding: UTF-8
class Window_GameSelect < Window_List
  WLH = 56
  def initialize(x,y)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 24)
    @color = [255,255,255]
    @game_color = [47,156,192]
    @game_stroke_color = [0xFF,0xFF,0xFF]
    @list = []
    Dir.glob('lib/**/game.yml') do |file|
      game = YAML.load_file(file)
      if game.is_a?(Hash) && game["name"]
        @list << game 
      else
        $log.warn "#{game.inspect}读取失败(#{file})"
      end
    end
    super(x,y,160,@list.size*WLH)
    clear
    @button = Surface.load("graphics/login/game_background.png")
    #@button.set_alpha(RLEACCEL,255)
    self.list = @list
  end
  def draw_item(index, status=0)
    Surface.blit(@button, 0, 0, @button.w, @button.h, @contents, 0, WLH*index)
    draw_stroked_text(@list[index]["name"], 24, WLH*index+14, 2)
  end
  def draw_stroked_text(text,x,y,size=1)
    [[x-size,y-size], [x-size,y], [x-size,y+size],
      [x,y-size], [x,y+size],
      [x+size,y-size], [x+size,y], [x+size,y+size],
    ].each{|pos|@font.draw_blended_utf8(@contents, text, pos[0], pos[1], *@game_stroke_color)}
    @font.draw_blended_utf8(@contents, text, x, y, *@game_color)
  end
end
