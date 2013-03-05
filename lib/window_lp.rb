class Window_LP < Window
  Avatar_Size = 48
  def initialize(x,y,player,position=true) #true:左 false:右
    super(x,y,355,48)
    @position = position
    @font = TTF.open(Font, 20)
    @color = [255,255,255]
    self.player = player
  end
  def player=(player)
    return if @player == player
    clear
    @player = player
    if @player
      @player.avatar do |avatar|
        clear(@position ? 0 : @width-Avatar_Size, 0, Avatar_Size, Avatar_Size)
        @contents.put avatar, @position ? 0 : @width-Avatar_Size, 0
      end
      if @position
        @font.draw_blended_utf8(@contents, @player.name, Avatar_Size, 24, *@color)
      else
        @font.draw_blended_utf8(@contents, @player.name, @width-Avatar_Size-96, 24, *@color)
      end
    end
    self.lp = 8000
  end
  def lp=(lp)
    return if lp == @lp
    
    @lp = lp
    width = [0, [(200*lp/8000), 200].min].max
    if @position
      clear(64,0,200, WLH)
      @contents.fill_rect(48,0,width, WLH, 0xFFFF0000)
      @font.draw_blended_utf8(@contents, @lp.to_s, 56, 0, *@color)
    else
      clear(@width-200-64,0,200 , WLH)
      @contents.fill_rect(@width-width-48,0,width , WLH, 0xFFFF0000)
      @font.draw_blended_utf8(@contents, @lp.to_s, 240, 0, *@color)
    end
  end
end