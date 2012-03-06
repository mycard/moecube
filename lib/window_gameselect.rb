#encoding: UTF-8
class Window_GameSelect < Window_List
  WLH = 56
  def initialize(x,y)
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 24)
    @color = [255,255,255]
    @game_color = [47,156,192]
    @game_stroke_color = [0xFF,0xFF,0xFF]
    @items = []
    Dir.glob('lib/**/game.yml') do |file|
      game = YAML.load_file(file)
      if game.is_a?(Hash) && game["name"]
        game['file'] ||= 'game.rb'
        game['file'] = File.expand_path(game['file'], File.dirname(file))
        $config[game['name']] ||= {}
        @items << game 
      else
        $log.error "#{game.inspect}读取失败(#{file})"
      end
    end
    super(x,y,160,@items.size*WLH)
    clear
    @button = Surface.load("graphics/login/game_background.png")
    #@button.set_alpha(RLEACCEL,255)
    self.items = @items
    self.index = @items.find_index{|game|game["name"] == $config['game']} || 0
    clicked
    @announcements_window = Window_Announcements.new(313,265,600,24)
    refresh
  end
  def draw_item(index, status=0)
    Surface.blit(@button, @button.w/3*status, 0, @button.w/3, @button.h, @contents, 0, WLH*index)
    draw_stroked_text(@items[index]["name"], 24, WLH*index+14, 2)
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
    load @items[@index]["file"] #TODO: load的这种架构微蛋疼，一时想不到更好的方案
    $config['game'] = @items[@index]['name']
    @login_window.destroy if @login_window
    @login_window = Window_Login.new(316,316,$config[$config['game']]["username"],$config[$config['game']]["password"])
    @announcements_window.refresh if @announcements_window
    
  end
  def update
    @announcements_window.update if @announcements_window
  end
  #def destroy
  #  @login_window.destroy if @login_window
  #  super
  #end
end
