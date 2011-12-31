class Window_LP < Window
  Avatar_Size = 48
  def initialize(x,y,player,position=true) #true:左 false:右
    super(x,y,360,72)
    @position = position
    @font = TTF.open("fonts/WenQuanYi Micro Hei.ttf", 20)
    @color = [255,255,255]
    self.player = player
    self.lp = 8000
  end
  def player=(player)
    return if @player == player
    @player = player
    if @player
      @player.avatar do |avatar|
        clear(@position ? 0 : @width-Avatar_Size, 24, Avatar_Size, Avatar_Size)
        @contents.put avatar, @position ? 0 : @width-Avatar_Size, 24
      end
      if @position
        @font.draw_solid_utf8(@contents, @player.name, Avatar_Size, 24, *@color)
      else
        @font.draw_solid_utf8(@contents, @player.name, @width-Avatar_Size-96, 24, *@color)
      end
    end
  end
  def lp=(lp)
    return if lp == @lp
    @lp = lp
    if @position
      @contents.fill_rect(64,0,[0, [(200*lp/8000), 200].min].max, 24, 0xFFFF0000)
      @font.draw_blended_utf8(@contents, @lp.to_s, 64, 0, *@color)
    else
      width = [0, [(200*lp/8000), 200].min].max
      @contents.fill_rect(@width-width-64,0,width , 24, 0xFFFF0000)
      @font.draw_blended_utf8(@contents, @lp.to_s, 128, 0, *@color)
    end
  end
end