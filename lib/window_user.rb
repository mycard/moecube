class Window_User < Window
  BackGround = Surface.load "graphics/hall/user.png"
  Boarder = Surface.load "graphics/hall/avatar_boader.png"
	def initialize(x, y, user)
    super(x,y,BackGround.w,BackGround.h)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    @user = user
    @contents = Surface.load "graphics/hall/user.png" #TODO:调用已经加载了的背景
    refresh
  end
  def refresh
    @thread.kill if @thread
    @contents.put(BackGround, 0,0)
    @thread = @user.avatar(:middle) do |avatar|
      @contents.put(avatar, 24, 24)
      @contents.put(Boarder, 12, 12)
    end
      
    @font.draw_blended_utf8(@contents, @user.name, 172, 24, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "id: #{@user.id}" , 172, 24+16*2, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, @user.status , 172, 24+16*3, 0x00,0x00,0x00)
      
    @font.draw_blended_utf8(@contents, "发送消息" , 172, 24+16*4+8, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "查看资料" , 172, 24+16*5+8, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "加为好友" , 172, 24+16*6+8, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "加入游戏" , 172, 24+16*7+8, 0x00,0x00,0x00)
  end
  
  def clicked
    
  end
  def dispose
    @thread.exit
    super
  end
end