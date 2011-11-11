#encoding: UTF-8
#==============================================================================
# Window_UserInfo
#------------------------------------------------------------------------------
# 游戏大厅显示用户信息的类
#==============================================================================

class Window_UserInfo < Window
	def initialize(x, y, user)
    @boarder = Surface.load "graphics/hall/avatar_boader.png"
    super(x,y,240,@boarder.h)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    @user = user
    refresh
  end
  
  def refresh(x=@x, y=@y, width=@width, height=@height)
    @thread = @user.avatar(:middle) do |avatar|
      $scene.refresh_rect(@x, @y, @boarder.w, @boarder.h) do
        Surface.blit(avatar, 0,0,0,0,$screen,@x+12,@y+12)
        Surface.blit(@boarder, 0,0,0,0,$screen,@x,@y)
      end
    end

    
    @font.draw_blended_utf8($screen, @user.name, @x+160, @y+12, 0x00,0x00,0x00)
    @font.draw_blended_utf8($screen, "id: #{@user.id}" , @x+160, @y+12+16*2, 0x00,0x00,0x00)
    @font.draw_blended_utf8($screen, "Level: #{@user.level}" , @x+160, @y+12+16*3, 0x00,0x00,0x00)
    @font.draw_blended_utf8($screen, "总经验: #{@user.exp}", @x+160, @y+12+16*4, 0x00,0x00,0x00)
  end
  def dispose
    @thread.exit
    super
  end
end
