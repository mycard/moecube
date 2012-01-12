class Window_Phases < Window_List
  WLH = 81 #其实是列宽
  def initialize(x,y)
    @phases_player = Surface.load('graphics/system/phases_player.png')
    @phases_player.set_alpha(RLEACCEL,255)
    @phases_opponent = Surface.load('graphics/system/phases_opponent.png')
    @phases_opponent.set_alpha(RLEACCEL,255)
    super(x,y,5*WLH+@phases_player.w/3, @phases_player.h/6)
    @items = [:DP, :SP, :M1, :BP, :M2, :EP]
    self.player = true
  end
  def player=(player)
    return if player == (@phases == @phases_player)
    @phases = player ? @phases_player : @phases_opponent
    @phase = 0
    refresh
  end
  def phase=(phase)
    phase = @items.index(phase) unless (0..5).include? phase 
    return if phase == @phase
    @index = @phase
    @phase = phase
    self.index = @phase
  end
  def draw_item(index, status=0)
    status = 2 if index == @phase
    Surface.blit(@phases, status*@phases.w/3, index*@height, @phases.w/3, @height, @contents, index*WLH, 0)
  end
  def item_rect(index)
    [WLH*index, 0, @phases.w/3, @height]
  end
  def mousemoved(x,y)
    self.index = include?(x,y) ? (x - @x) / WLH : nil
  end
  def clear(x=0,y=0,width=@width,height=@height)
    @contents.fill_rect(x,y,width, height, 0x00000000)
  end
  def clicked
    $scene.change_phase(@items[@index])
  end
end