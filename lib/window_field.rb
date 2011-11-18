#encoding: UTF-8
#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Field < Window
  require 'card'
  require 'window_action'
  require 'window_cardinfo'
  Field_Pos = [[56,0], #场地魔法
    [140, 84], [234,84], [328,84],[422,84], [516, 84], #后场
    [140, 0], [234, 0], [328, 0],[422, 0], [516, 0]] #前场
  Extra_Pos = [56,84] #额外卡组
  Graveyard_Pos = [598,0] #墓地
  Removed_Pos = [657,0] #除外区
  Deck_Pos = [598, 84]
  Hand_Pos = [0, 201, 62, 8] #手卡： x, y, width, 间距
  #Card_Size = [Card::CardBack.w, Card::CardBack.h]
  Card_Size = [54, 81]
  attr_reader :action_window
	def initialize(x, y, field,player=true)
    @border = Surface.load 'graphics/field/border.png'
    super(x,y,711,282)
    @field = field
    @player = player
    
    @items = {}
    @cards = {}
    refresh
	end
  def refresh
    @items.clear
    @cards.clear
    if !@field.deck.empty?
      @items[:deck] = Deck_Pos + Card_Size 
      @cards[:deck] = @field.deck.first
    end
    if !@field.extra.empty?
      @items[:extra] = Extra_Pos + Card_Size 
      @cards[:extra] = @field.extra.first
    end
    if !@field.removed.empty?
      @items[:removed] = Removed_Pos + Card_Size 
      @cards[:removed] = @field.extra.first
    end
    if !@field.graveyard.empty?
      @items[:graveyard] = Graveyard_Pos + Card_Size
      @cards[:graveyard] = @field.graveyard.first
    end
    
    @field.field.each_with_index do |card, index|
      if card
        @items[index] = [Field_Pos[index][0], Field_Pos[index][1]]+ Card_Size
        @cards[index] = card
      end
    end
    
    hand_width = @field.hand.size * Hand_Pos[2] + (@field.hand.size-1) * Hand_Pos[3]
    hand_x = (@width - hand_width) / 2
    @field.hand.each_with_index do |card, index|
      @items[index+11] = [hand_x+index*Hand_Pos[2], Hand_Pos[1]]+ Card_Size
      @cards[index+11] = card
    end
    
    @contents.fill_rect(0,0,@width, @height, 0x66000000)
    @items.each_key{|index|draw_item(index)}
  end
  def draw_item(index, status=0)
    @contents.put(@cards[index].image_small, @items[index][0], @items[index][1])
    @contents.put(@border, @items[index][0]-1, @items[index][1]-1) if status == 1
  end
  def item_rect(index)
    @items[index]
  end
  def index=(index)
    return if index == @index
    if @index
      clear(@items[@index][0]-1,@items[@index][1]-1,@items[@index][2]+2, @items[@index][3]+2)
      draw_item(@index, 0) 
    end
    if index.nil? or !@items.has_key?(index) or (index == :deck and @field.deck.empty?) or (index == :removed and @field.removed.empty?) or (index == :extra and @field.extra.empty?) or (index == :graveyard and @field.graveyard.empty?)
      @index = nil
      $scene.action_window.list = nil
    else
      @index = index
      draw_item(@index, 1)
      case @index
      when :deck
        @index_card = @field.deck.first
        @action_names = {"抽卡" => true,
          "卡组洗切" => true,
          "抽卡(双方确认)" => true,
          "顶牌回卡组底部" => true,
          "顶牌送入墓地" => true,
          "顶牌从游戏中除外" => true,
          "顶牌背面除外" => true,
          "确认顶牌" => true,
          "双方确认顶牌" => true
        }
      when :extra
        @index_card = @field.extra.first
        @action_names = {"特殊召唤/发动" => true,
          "效果发动" => true,
          "从游戏中除外" => true,
          "送入墓地" => true
        }
      when :removed
        @index_card = @field.removed.first
        @action_names = {"特殊召唤/发动" => true,
          "效果发动" => true,
          "加入手卡" => true,
          "返回卡组" => true,
          "送入墓地" => true
        }
      when :graveyard
        @index_card = @field.graveyard.first
        @action_names = {"特殊召唤/发动" => true,
          "效果发动" => true,
          "加入手卡" => true,
          "返回卡组" => true,
          "从游戏中除外" => true
        }
      when 0..5
        @index_card = @field.field[@index]
        @action_names = {"效果发动" => true,
          "返回卡组" => true,
          "送入墓地" => true,
          "从游戏中除外" => true,
          "加入手卡" => true,
          "打开/盖伏" => true
        }
      when 6..10
        @index_card = @field.field[@index]
        @action_names = {"攻/守形式转换" => true,
          "里侧/表侧转换" => true,
          "转为里侧守备" => true,
          "攻击宣言" => true,
          "效果发动" => true,
          "转移控制权" => true,
          "放回卡组顶端" => true,
          "送入墓地" => true,
          "解放" => true,
          "加入手卡" => true,
          "送入对手墓地" => true
        }
      when Integer #手卡
        @index_card = @field.hand[@index-11]
        @action_names = {"放置到场上" => true,
          "召唤" => @index_card.monster?,
          "发动" => !@index_card.monster?,
          "特殊召唤" => true,
          "放回卡组顶端" => true,
          "送入墓地" => true,
          "从游戏中除外" => true,
          "效果发动" => true
        }
      end
      $scene.action_window.list = @action_names
      $scene.cardinfo_window.card = @index_card
      $scene.action_window.x = @x + @items[@index][0] - ($scene.action_window.width - @items[@index][2])/2
      $scene.action_window.y = @y + @items[@index][1] - $scene.action_window.viewport[3]#height
    end
  end
  def mousemoved(x,y)
    self.index = @items.each do |index, item_rect|
      if x.between?(@x+item_rect[0], @x+item_rect[0]+item_rect[2]) and y.between?(@y+item_rect[1], @y+item_rect[1]+item_rect[3])
        break index
      end
    end
  end
  def cursor_up
    $scene.action_window.cursor_up
  end
  def cursor_down
    $scene.action_window.cursor_down
  end
  def cursor_left
    #self.index = @index ? (@index - 1) % [@list.size, @item_max].min : 0
  end
  def cursor_right
    #self.index = @index ? (@index + 1) % [@list.size, @item_max].min : 0
  end
  def lostfocus
    self.index = nil
  end
  def clicked
    return if !$scene.action_window.visible
    case @index
    when :deck
      case $scene.action_window.index
      when 0
        Action::Draw.new(true).run
      end
    when 0..10
      #场上
    when Integer #手卡
      case $scene.action_window.index
      when 0
        Action::Set.new(true, :hand, 6, @index_card)
      end
    end
    refresh
  end
end