class Window_User < Window_List
  WLH = 20
	def initialize(x, y, user)
    @background = Surface.load "graphics/hall/user.png"
    super(x,y,@background.w,@background.h, 300)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    @user = user
    @contents = Surface.load "graphics/hall/user.png" #TODO:调用已经加载了的背景
    
    @avatar_boarder = Surface.load "graphics/hall/avatar_boader.png"
    @list = ["发送消息", "查看资料"]
    @list << "加入游戏" if user.status == :waiting
    @list << "观战" if user.status == :dueling
    @item_max = @list.size
    refresh
  end
  def refresh
    @thread.kill if @thread
    @contents.put(@background, 0,0)
    @thread = @user.avatar(:middle) do |avatar|
      clear(12,12,144,144)
      @contents.put(avatar, 24, 24)
      @contents.put(@avatar_boarder, 12, 12)
    end
      
    @font.draw_blended_utf8(@contents, @user.name, 172, 24, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "id: #{@user.id}" , 172, 32+WLH, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "#{'房间' + @user.room.id.to_s + ' ' if @user.room}#{case @user.status;when :hall;'大厅';when :dueling;'决斗中';when :waiting;'等待中';end}", 172, 32+WLH*2, 0x00,0x00,0x00)
    super
  end
  

  def draw_item(index, status=0)
    @font.draw_blended_utf8(@contents, @list[index] , 172, 96+index*WLH, 0x00,0x00,0x00)
  end
  def item_rect(index)
    [172, 96+index*WLH, 128, WLH]
  end
  def clicked
    case index
    when 0
      #发送消息
    when 1
      require 'launchy'
      Launchy.open("http://google.com")
    when 2
      if @user.status == :waiting
        $iduel.join(@user.room)
      elsif @user.status == :dueling
        $iduel.watch(@user.room)
      end
    end
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