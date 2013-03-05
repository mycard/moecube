class Window_GameSelect < Window_List
  WLH = 56
  def initialize(x,y)
    @font = TTF.open(Font, 24)
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
	#======================================================
	# We'll pay fpr that soon or later.
	#======================================================
	if $config['screen']['height'] == 768
		@announcements_window = Window_Announcements.new(313,265,600,24)
	elsif $config['screen']['height'] == 640
		@announcements_window = Window_Announcements.new(313,130,600,24)
	else
		raise "无法分辨的分辨率"
	end	
	#======================================================
	# ENDS HERE
	#======================================================
    refresh
  end
  def draw_item(index, status=0)
    Surface.blit(@button, @button.w/3*status, @game == index ? @button.h/2 : 0, @button.w/3, @button.h/2, @contents, 0, WLH*index)
    draw_stroked_text(@items[index]["name"], 24, WLH*index+14, 2)
  end
  def item_rect(index)
    return [0,0,0,0] unless index
    [0, WLH*index, @button.w/3, @button.h/2]
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
    return if @index == index# or index.nil?
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0)
    end
    @index = index
    clear(*item_rect(@index))
    draw_item(@index, 1) if @index
  end
  def clicked
    return unless @index
    load @items[@index]["file"].encode("GBK") #TODO: load的这种架构微蛋疼，一时想不到更好的方案
    $config['game'] = @items[@index]['name']
    @login_window.destroy if @login_window
	#======================================================
	# We'll pay fpr that soon or later.
	#======================================================
	if $config['screen']['height'] == 768
		@login_window = Window_Login.new(316,316,$config[$config['game']]["username"],$config[$config['game']]["password"])
	elsif $config['screen']['height'] == 640
		@login_window = Window_Login.new(316,183,$config[$config['game']]["username"],$config[$config['game']]["password"])
	else
		raise "无法分辨的分辨率"
	end	
	#======================================================
	# ENDS HERE
	#======================================================
    @announcements_window.refresh if @announcements_window
    @game = @index
    refresh
  end
  def update
    @login_window.update if @login_window
    @announcements_window.update if @announcements_window
  end
  #def lostfocus
 #   self.index = nil
  #end
  #def destroy
  #  @login_window.destroy if @login_window
  #  super
  #end
end
