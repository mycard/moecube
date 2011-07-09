class Window_Phases < Window_List
  WLH = 80 #其实是列宽
  def initialize(x,y)
    @background_player = Surface.load 'graphics/system/phases_player.png'
    @background_opponent = Surface.load 'graphics/system/phases_opponent.png'
    super(x,y,5*WLH+@background_player.w/3, @background_player.h/6)
    @column_max = @item_max = 6
    self.player = true
  end
  def player=(player)
    return if player == (@background == @background_player)
    @background = player ? @background_player : @background_opponent
    @phase = 0
    refresh
  end
  def phase=(phase)
    return if phase == @phase
    @index = @phase
    @phase = phase
    self.index = @phase
  end
  def draw_item(index, status=0)
    status = 2 if index == @phase
    Surface.blit(@background, status*@background.w/3, index*@height, @background.w/3, @height, $screen, @x+index*WLH, @y)
  end
  def item_rect(index)
    [@x+WLH*index, @y, @background.w/3, @height]
  end
  def mousemoved(x,y)
    self.index = include?(x,y) ? (x - @x) / WLH : nil
  end
end