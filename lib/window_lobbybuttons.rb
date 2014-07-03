require_relative 'window_host'
class Window_LobbyButtons < Window_List
  def initialize(x, y)
    @items = [I18n.t('lobby.forum'), I18n.t('lobby.filter'), I18n.t('lobby.editdeck'), I18n.t('lobby.newroom'), I18n.t('lobby.match')]
    @button = Surface.load("graphics/lobby/button.png")
    super(x, y, @items.size*@button.w/3+@items.size*4, 30)
    @font = TTF.open(Font, 15)
    refresh
  end

  def draw_item(index, status=0)
    x, y, width=item_rect(index)
    Surface.blit(@button, status*@button.w/3, 0, @button.w/3, @button.h, @contents, x, y)
    draw_stroked_text(@items[index], x+center_margin(@items[index], width, @font), y+3, 2, @font, [0xdf, 0xf1, 0xff], [0x27, 0x43, 0x59])
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
        Dialog.web "https://forum.my-card.in/"
      when 1 #房间筛选
        if @filter_window and !@filter_window.destroyed?
          @filter_window.destroy
        else
          @filter_window = Window_Filter.new(678, 44)
        end
      when 2 #卡组编辑
        require_relative 'deck'
        $game.class.deck_edit
      when 3 #建立房间
        @host_window = Window_Host.new(300, 200)
      when 4 #自动匹配
        return if @waiting
        @waiting = true
        waiting_window = Widget_Msgbox.new("自动匹配", "正在等待对手")
        require 'uri'
        require 'net/http'
        require 'net/https'
        Thread.new {
          begin
            uri = URI.parse("https://my-card.in/match")
            http = Net::HTTP.new(uri.host,uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            req = Net::HTTP::Post.new(uri.path)
            req.basic_auth $game.username, $game.password
            res = http.request(req)
            @waiting = false
            if res.body =~ /^mycard:\/\/([\d\.]+):(\d+)\/(.*?)(\?server_auth=true)?$/
              room = Room.new(nil, $3.to_s)
              room.server = Server.new(nil, nil, $1, $2.to_i, !!$4)
              $game.join(room)
            else
              $log.error('自动匹配非法回复'){res.body}
              Widget_Msgbox.new("自动匹配", "错误: #{res.body}", ok: "确定")
            end
          rescue Exception => exception
            @waiting = false
            $log.error('自动匹配出错'){exception.to_s.encode('UTF-8')}
            Widget_Msgbox.new("自动匹配", "匹配失败: #{exception.to_s.encode('UTF-8')}", ok: "确定")
          end
        }
    end
  end

  def update
    @host_window.update if @host_window and !@host_window.destroyed?
  end

end
