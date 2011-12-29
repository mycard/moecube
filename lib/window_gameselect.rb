#encoding: UTF-8
class Window_GameSelect < Window_List
  WLH = 56
  def initialize(x,y,game_name=nil)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 24)
    @color = [255,255,255]
    @game_color = [47,156,192]
    @game_stroke_color = [0xFF,0xFF,0xFF]
    @list = []
    Dir.glob('lib/**/game.yml') do |file|
      game = YAML.load_file(file)
      if game.is_a?(Hash) && game["name"]
        game['file'] ||= 'game.rb'
        game['file'] = File.expand_path(game['file'], File.dirname(file))
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
    self.index = @list.find_index{|game|game["name"] == game_name} || 0
    clicked
    refresh
  end
  def draw_item(index, status=0)
    Surface.blit(@button, @button.w/3*status, 0, @button.w/3, @button.h, @contents, 0, WLH*index)
    draw_stroked_text(@list[index]["name"], 24, WLH*index+14, 2)
  end
  def item_rect(index)
    [0, WLH*index, @button.w, @button.h]
  end
  def draw_stroked_text(text,x,y,size=1)
    [[x-size,y-size], [x-size,y], [x-size,y+size],
      [x,y-size], [x,y+size],
      [x+size,y-size], [x+size,y], [x+size,y+size],
    ].each{|pos|@font.draw_blended_utf8(@contents, text, pos[0], pos[1], *@game_stroke_color)}
    @font.draw_blended_utf8(@contents, text, x, y, *@game_color)
  end
  def mousemoved(x,y)
    self.index = (y-@y) / WLH
  end
  def index=(index)
    return if @index == index or index.nil?
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0)
    end
    @index = index
    clear(*item_rect(@index))
    draw_item(@index, 1)
  end
  def clicked
    load @list[@index]["file"] #TODO: load的这种架构微蛋疼，一时想不到更好的方案
    @login_window.destroy if @login_window
    @login_window = Window_Login.new(316,316,$config["username"],$config["password"])
  end
end
