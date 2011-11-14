#encoding: UTF-8
#==============================================================================
# Window_UserInfo
#------------------------------------------------------------------------------
# 游戏大厅显示用户信息的类
#==============================================================================

class Window_UserInfo < Window
	def initialize(x, y, user)
    @avatar_boarder = Surface.load "graphics/hall/avatar_boader.png"
    super(x,y,240,144)
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    @user = user
    @background = Surface.load "graphics/hall/userinfo.png"
    refresh
  end
  
  def refresh
    @contents.put(@background, 0, 0)
    @thread = @user.avatar(:middle) do |avatar|
      @contents.put(avatar, 12, 12)
      @contents.put(@avatar_boarder, 0, 0)
    end

    
    @font.draw_blended_utf8(@contents, @user.name, 160, 12, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "id: #{@user.id}" , 160, 12+16*2, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "Lv: #{@user.level}" , 160, 12+16*3, 0x00,0x00,0x00)
    @font.draw_blended_utf8(@contents, "经验: #{@user.exp}", 160, 12+16*4, 0x00,0x00,0x00)
  end
  def dispose
    @thread.exit
    super
  end
end
