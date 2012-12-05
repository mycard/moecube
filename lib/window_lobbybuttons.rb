require_relative 'window_host'
class Window_LobbyButtons < Window_List
  def initialize(x, y)
    @items = [I18n.t('lobby.faq'), I18n.t('lobby.editdeck'), I18n.t('lobby.newroom')]
    @button = Surface.load("graphics/lobby/button.png")
    super(x, y, @items.size*@button.w/3+@items.size*4, 30)
    @font = TTF.open("fonts/wqy-microhei.ttc", 15)
    refresh
  end

  def draw_item(index, status=0)
    x, y, width=item_rect(index)
    Surface.blit(@button, status*@button.w/3, 0, @button.w/3, @button.h, @contents, x, y)
    draw_stroked_text(@items[index], x+center_margin(@items[index],width,@font), y+3, 2, @font, [0xdf, 0xf1, 0xff], [0x27, 0x43, 0x59])
  end

  def item_rect(index)
    [index*@button.w/3+(index)*4, 0, @button.w/3, @height]
  end

  def mousemoved(x, y)
    if (x-@x) % (@button.w/3+4) >= @button.w/3
      self.index = nil
    else
      self.index = (x-@x)/(@button.w/3+4)
    end
  end

  def lostfocus(active_window = nil)
    self.index = nil
  end

  def clicked
    case @index
      when 0 #常见问题
        require_relative 'dialog'
        Dialog.web "http://my-card.in/login?user[name]=#{CGI.escape $game.user.name}&user[password]=#{CGI.escape $game.password}&continue=/topics/1453"
      when 1 #卡组编辑
        require_relative 'deck'
        $game.class.deck_edit
      when 2 #建立房间
        @host_window = Window_Host.new(300, 200)
    end
  end

  def update
    @host_window.update if @host_window and !@host_window.destroyed?
  end
end
