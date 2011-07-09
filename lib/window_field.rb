#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Field
  Field_Pos = [[56,0], #场地魔法
    [140, 84], [234,84], [328,84],[422,84], [516, 84], #后场
    [140, 0], [234, 0], [328, 0],[422, 0], [516, 0]] #前场
  Extra_Pos = [56,84] #额外卡组
  Graveyard_Pos = [598,0] #墓地
  Removed_Pos = [657,0] #除外区
  Hand_Pos = [0, 201, 62, 8] #手卡： x, y, width, 间距
	def initialize(x, y, field)
    @x = x
    @y = y
    @width = 711
    @height = 281
    @field = field
    refresh
	end
  def refresh
    $scene.refresh_rect(@x,@y,@width,@height) do
      @field.field.each_with_index {|card, index|Surface.blit(card.image_small, 0,0,0,0, $screen, @x+Field_Pos[index][0], @y+Field_Pos[index][1]) if card}
      hand_width = @field.hand.size * Hand_Pos[2] + (@field.hand.size-1) * Hand_Pos[3]
      hand_x = (@width - hand_width) / 2
      @field.hand.each_with_index {|card, index|Surface.blit(card.image_small, 0,0,0,0, $screen, @x+hand_x+index*Hand_Pos[2], @y+Hand_Pos[1]) if card}
    end
  end
end