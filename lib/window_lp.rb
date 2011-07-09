class Window_LP
  Avatar_Size = 48
  def initialize(x,y,player,position=true) #true:左�false:右�    
    @x = x
    @y = y
    @width = 360
    @height = 72
    @player = player
    @position = position
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 24)
    @color = [255,255,255]
    #p @x+@width-Avatar_Size
    Surface.blit(@player.avatar do |avatar|
        $scene.refresh_rect(position ? @x : @x+@width-Avatar_Size, @y+24, Avatar_Size,Avatar_Size) do
          Surface.blit(avatar, 0,0,0,0,$screen, position ? @x : @x+@width-Avatar_Size, @y+24)
        end
      end,0,0,0,0,$screen, position ? @x : @x+@width-Avatar_Size, @y+24)

    self.lp = 8000
  end
  def lp=(lp)
    $scene.refresh_rect(@x, @y, @width, 24) do
      if @position
        @font.draw_blended_utf8($screen, lp.to_s, @x, @y, *@color)
        $screen.fill_rect(@x+64,@y,[0, [(200*lp/8000), 200].min].max, 24, 0xFFFF0000)
      else
        @font.draw_blended_utf8($screen, lp.to_s, @x+@width-64, @y, *@color)
        width = [0, [(200*lp/8000), 200].min].max
        $screen.fill_rect(@x+@width-width-64,@y,width , 24, 0xFFFF0000)
      end
    end
  end
  #def draw_item(player)
  #    if player == @player
  #      
  #    end
  #    
  #  end
  
end