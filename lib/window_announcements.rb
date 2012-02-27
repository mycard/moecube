class Window_Announcements < Window
  def initialize(x,y,width,height)
    super(x,y,width,height)
    @items = $config[$config['game']]['announcements']
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 18)
    @color = [44,64,78]
    @last_announcement = @items.first
    refresh
  end
  def refresh
    clear
    @font.draw_blended_utf8(@contents, @items.first[0], 0, 0, *@color)
  end
  def update
    if @items.first != @last_announcement
      refresh
      @last_announcement = @items.first
    end
    super
  end
  def clicked
    require 'launchy'
    Launchy.open(@items.first[1]) if @items.first[1]
  end
end
