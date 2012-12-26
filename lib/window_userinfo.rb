#encoding: UTF-8
#==============================================================================
# Window_UserInfo
#------------------------------------------------------------------------------
# 游戏大厅显示用户信息的类
#==============================================================================

class Window_UserInfo < Window
  def initialize(x, y, user)
    @avatar_boarder = Surface.load("graphics/lobby/avatar_boader.png")
    super(x,y,280,144)
    @font = TTF.open('fonts/wqy-microhei.ttc', 16)
    @user = user
    @background = Surface.load("graphics/lobby/userinfo.png").display_format
    refresh
  end
  
  def refresh
    @contents.put(@background, 0, 0)
    @thread = @user.avatar(:middle) do |avatar|
      clear(0,0,@avatar_boarder.w, @avatar_boarder.h)
      @contents.put(avatar, 12, 12)
      @contents.put(@avatar_boarder, 0, 0)
    end

    @font.draw_blended_utf8(@contents, @user.name, 160, 12, 0x00,0x00,0x00) unless @user.name.empty?
    @font.draw_blended_utf8(@contents, @user.id.to_s , 160, 12+16*2, 0x00,0x00,0x00) unless @user.id.to_s.empty?
    @font.draw_blended_utf8(@contents, "Lv: #{@user.level}" , 160, 12+16*3, 0x00,0x00,0x00) if @user.respond_to? :level and @user.level #TODO:规范化，level是iduel专属的，但是又不太想让iduel来重定义这个window
    @font.draw_blended_utf8(@contents, "经验: #{@user.exp}", 160, 12+16*4, 0x00,0x00,0x00) if @user.respond_to? :exp and @user.exp
  end
  def dispose
    @thread.exit
    super
  end
end
