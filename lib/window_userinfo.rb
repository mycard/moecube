#encoding: UTF-8
#==============================================================================
# Window_UserInfo
#------------------------------------------------------------------------------
# 游戏大厅显示用户信息的类
#==============================================================================

class Window_UserInfo
	def initialize(x, y, user)
    @boarder = Surface.load "graphics/hall/avatar_boader.png"
    @x = x
    @y = y
    @width = 240
    @height= @boarder.h
    
    @font = TTF.open('fonts/WenQuanYi Micro Hei.ttf', 16)
    
    Surface.blit(user.avatar(:middle) do |newest_avatar|
        $scene.refresh_rect(@x, @y, @boarder.w, @boarder.h) do
          if $scene.is_a? Scene_Hall
            Surface.blit(newest_avatar, 0,0,0,0,$screen,@x+12,@y+12)
            Surface.blit(@boarder, 0,0,0,0,$screen,@x,@y)
          end
        end
      end, 0,0,0,0,$screen,@x+12,@y+12) 
    Surface.blit(@boarder, 0,0,0,0,$screen,@x,@y)
    
    @font.draw_blended_utf8($screen, user.name, @x+160, @y+12, 0x00,0x00,0x00)
    @font.draw_blended_utf8($screen, "Level: #{user.level}" , @x+160, @y+12+16*2, 0x00,0x00,0x00)
    @font.draw_blended_utf8($screen, "总经验: #{user.exp}", @x+160, @y+12+16*3, 0x00,0x00,0x00)
    
  end
  
  def refresh
    #p "-------------Read start-----------"
    #@user.avatar{|avatar| self.contents[1] = avatar; p "-------------read end-----------" }
    #self.
    #se
    #self.contents[1] = @user.avatar(:middle)
		
    #p @user
    #contents[0].clear
    #@list.each_with_index do |player, index|
    #contents[0].draw_text(player.name, 0, 16*index)
    #end
  end
end

#<Iduel::User:0x46b6438 @id="201629", @name="zh99997", @credit="Level-1 (\u603B\u7ECF\u9A8C:183)">