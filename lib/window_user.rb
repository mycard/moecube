class Window_User < Window_List
  WLH = 20
	def initialize(x, y, user)
    @background = Surface.load("graphics/lobby/user.png").display_format
    super(x,y,@background.w,@background.h, 300)
    @font = TTF.open(Font, 16)
    @user = user
    @contents = Surface.load("graphics/lobby/user.png").display_format #TODO:调用已经加载了的背景
    @close = Surface.load("graphics/lobby/userclose.png")
    @avatar_boarder = Surface.load("graphics/lobby/avatar_boader.png")
    @items = ["发送消息", "查看资料"]
    @items << "加入游戏" if user.status == :waiting
    @items << "观战" if user.status == :dueling
    @item_max = @items.size
    refresh
  end
  def refresh
    @thread.kill if @thread
    super
    @thread = @user.avatar(:middle) do |avatar|
      clear(12,12,@avatar_boarder.w, @avatar_boarder.h)
      @contents.put(avatar, 24, 24)
      @contents.put(@avatar_boarder, 12, 12)
    end
      
    @font.draw_blended_utf8(@contents, @user.name, 172, 24, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "id: #{@user.id}" , 172, 32+WLH, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "#{'房间' + @user.room.id.to_s + '' if @user.room}#{case @user.status;when :lobby;'大厅';when :dueling;'决斗中';when :waiting;'等待中';end}", 172, 32+WLH*2, 0x00,0x00,0x00)
    Surface.blit(@close, 0, 0, @close.w/3, @close.h, @contents, @width-24,10)
    
  end
  def clear(x=0,y=0,width=@width,height=@height)
    Surface.blit(@background, x,y,width,height,@contents,x,y)
  end

  def draw_item(index, status=0)
    @font.draw_blended_utf8(@contents, @items[index] , 172, 96+index*WLH, 0x00,0x00,0x00)
  end
  def item_rect(index)
    [172, 96+index*WLH, 128, WLH]
  end
  def clicked
    case index
    when 0
      $scene.chat_window.channel = @user
    when 1
      @user.space
    when 2
      if @user.status == :waiting
        $game.join(@user.room)
      elsif @user.status == :dueling
        $game.watch(@user.room)
      end
    end
    destroy
  end
  def mousemoved(x,y)
    if x.between?(@x+172, @x+@width) and y.between?(@y+96, @y+96+@item_max*WLH)
      self.index = (y - @y - 96) / WLH
    else
      self.index = nil
    end
  end
  def dispose
    @thread.exit
    super
  end
end