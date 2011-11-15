#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Field < Window
  require 'card'
  require 'window_action'
  Field_Pos = [[56,0], #场地魔法
    [140, 84], [234,84], [328,84],[422,84], [516, 84], #后场
    [140, 0], [234, 0], [328, 0],[422, 0], [516, 0]] #前场
  Extra_Pos = [56,84] #额外卡组
  Graveyard_Pos = [598,0] #墓地
  Removed_Pos = [657,0] #除外区
  Deck_Pos = [598, 84]
  Hand_Pos = [0, 201, 62, 8] #手卡： x, y, width, 间距
  Card_Size = [Card::CardBack.w, Card::CardBack.h]
  attr_reader :action_window
	def initialize(x, y, field,player=true)
    super(x,y,711,282)
    @field = field
    @player = player
    
    @items = {
      :deck => Deck_Pos + Card_Size,
      :extra => Extra_Pos + Card_Size,
      :removed => Removed_Pos + Card_Size,
      :graveyard => Graveyard_Pos + Card_Size,
    }
   
    refresh
	end
  def refresh
    @items.each_key{|index|draw_item(index)}
    hand_width = @field.hand.size * Hand_Pos[2] + (@field.hand.size-1) * Hand_Pos[3]
    hand_x = (@width - hand_width) / 2
    #if @player
    #
    @field.field.each_with_index {|card, index|@contents.put(card.image_small, Field_Pos[index][0], Field_Pos[index][1]) if card}
    @field.hand.each_with_index {|card, index|@contents.put(card.image_small, hand_x+index*Hand_Pos[2], Hand_Pos[1]) if card}
    #else
    #Surface.transform_blit(@field.deck.first.image_small, @contents, 180, 1, 1, 0, 0, @width-Deck_Pos[0], @height-Deck_Pos[1],0) if !@field.deck.empty?
    #  @field.field.each_with_index {|card, index|Surface.transform_blit(card.image_small, @contents, 180, 1, 1, 0, 0, @width-Field_Pos[index][0], @height-Field_Pos[index][1],0) if card}
    #  @field.hand.each_with_index {|card, index|Surface.blit(card.image_small, 0,0,0,0, @contents, @width-hand_x-index*Hand_Pos[2]-card.image_small.w, @height-Hand_Pos[1]-card.image_small.h) if card}
    #end
  end
  def draw_item(index, status=0)
    case index
    when :deck
      @contents.put(@field.deck.first.image_small, Deck_Pos[0], Deck_Pos[1]) if !@field.deck.empty?
    when :extra
      @contents.put(@field.extra.first.image_small, Extra_Pos[0], Extra_Pos[1]) if !@field.extra.empty?
    when :removed
      @contents.put(@field.removed.first.image_small, Removed_Pos[0], Removed_Pos[1]) if !@field.removed.empty?
    when :graveyard
      @contents.put(@field.graveyard.first.image_small, Graveyard_Pos[0], Graveyard_Pos[1]) if !@field.graveyard.empty?
    end
  end
  def item_rect(index)
    @items[index]
  end
  def index=(index)
    return if index == @index
    if @index
      clear(*item_rect(@index))
      draw_item(@index, 0) 
    end
    if index.nil? or !@items.has_key?(index)
      @index = nil
      @action_window.destroy if @action_window
      @action_window = nil
    else
      @index = index     
      draw_item(@index, 1)
      @action_window = Window_Action.new(@x+@items[index][0],@y+@items[index][1],["测试动作1", "测试动作2", "测试动作3"])
    end
  end
  def mousemoved(x,y)
    self.index = @items.each do |index, item_rect|
      if x.between?(@x+item_rect[0], @x+item_rect[0]+item_rect[2]) and y.between?(@y+item_rect[1], @y+item_rect[1]+item_rect[3])
        break index
      end
    end
  end
  
  #def clicked
end