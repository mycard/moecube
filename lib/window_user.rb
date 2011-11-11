class Window_User < Window
	def initialize(x, y, user)
    @background = Surface.load "graphics/hall/user.png"
    @boarder = Surface.load "graphics/hall/avatar_boader.png"
    super(x,y,@background.w,@background.h)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    @user = user
    refresh
  end
  def refresh(x=@x, y=@y, width=@width, height=@height)
    $scene.refresh_rect(@x, @y, @width, @height, @background, -@x, -@y) do
      Surface.blit(@background, 0,0,0,0,$screen,@x,@y)

      @thread = @user.avatar(:middle) do |avatar|
        $scene.refresh_rect(@x+12, @y+12, @boarder.w, @boarder.h, @background, -@x, -@y) do
          Surface.blit(avatar, 0,0,0,0,$screen,@x+24,@y+24)
          Surface.blit(@boarder, 0,0,0,0,$screen,@x+12,@y+12)
        end
      end
      
      @font.draw_blended_utf8($screen, @user.name, @x+172, @y+24, 0x00,0x00,0x00)
      @font.draw_blended_utf8($screen, "id: #{@user.id}" , @x+172, @y+24+16*2, 0x00,0x00,0x00)
      @font.draw_blended_utf8($screen, @user.status , @x+172, @y+24+16*3, 0x00,0x00,0x00)
      
      
      @font.draw_blended_utf8($screen, "发送消息" , @x+172, @y+24+16*4+8, 0x00,0x00,0x00)
      @font.draw_blended_utf8($screen, "查看资料" , @x+172, @y+24+16*5+8, 0x00,0x00,0x00)
      @font.draw_blended_utf8($screen, "加为好友" , @x+172, @y+24+16*6+8, 0x00,0x00,0x00)
      @font.draw_blended_utf8($screen, "加入游戏" , @x+172, @y+24+16*7+8, 0x00,0x00,0x00)
    end
  end
  def clicked
    
  end
  def dispose
    @thread.exit
    super
  end
end