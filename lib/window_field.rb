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
      case @index
      when :deck
        @action_names = ["抽卡",
          "卡组洗切",
          "抽卡(双方确认)",
          "顶牌回卡组底部",
          "顶牌送入墓地",
          "顶牌从游戏中除外",
          "顶牌背面除外",
          "确认顶牌",
          "双方确认顶牌"
        ]
        @action_avalable = [true, true, false, false, false, false, false, false]
      when :extra
        @action_names = ["特殊召唤/发动",
          "效果发动",
          "从游戏中除外",
          "送入墓地"
        ]
        @action_avalable = [true, true, false, false]
      when :removed
        @action_names = ["特殊召唤/发动",
          "效果发动",
          "加入手卡",
          "返回卡组",
          "送入墓地"
        ]
        @action_avalable = [true, true, false, false, false]
      when :graveyard
        @action_names = ["特殊召唤/发动",
          "效果发动",
          "加入手卡",
          "返回卡组",
          "从游戏中除外"
        ]
        @action_avalable = [true, true, false, false, false]
      end

      @action_window = Window_Action.new(@x+@items[index][0],@y+@items[index][1]-@action_names.size*Window_Action::WLH,@action_names, @action_avalable)
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