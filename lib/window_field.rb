#==============================================================================
# ■ Scene_Title
#------------------------------------------------------------------------------
# 　title
#==============================================================================

class Window_Field < Window
  require_relative 'card'
  require_relative 'window_action'
  require_relative 'window_cardinfo'
  Field_Pos = [[59,0], #场地魔法
    [143, 84], [237,84], [331,84],[425,84], [519, 84], #后场
    [143, 0],  [237, 0], [331, 0],[425, 0], [519, 0]] #前场
  Extra_Pos = [59,84] #额外卡组
  Graveyard_Pos = [601,0] #墓地
  Removed_Pos = [660,0] #除外区
  Deck_Pos = [601, 84]
  Hand_Pos = [0, 201, 62, 8] #手卡： x, y, width, 间距
  #Card_Size = [Card::CardBack.w, Card::CardBack.h]
  Card_Size = [54, 81]
  attr_accessor :action_window
  WLH = 16
	def initialize(x, y, field,player=true)
    @border = Surface.load('graphics/field/border.png')
    @border_horizontal = Surface.load('graphics/field/border_horizontal.png') #@border.transform_surface(0x66000000,90,1,1,Surface::TRANSFORM_SAFE|Surface::TRANSFORM_AA)#FUCK!
    super(x,y,714,282)
    @field = field
    @player = player
    @font = TTF.open(Font, 12)
    @items = {}
    @cards = {}
    refresh
	end
  def refresh
    @items.clear
    @cards.clear
    if !@field.deck.empty?
      @items[:deck] = Deck_Pos + Card_Size 
      @cards[:deck] = @field.deck.last
    end
    if !@field.extra.empty?
      @items[:extra] = Extra_Pos + Card_Size 
      @cards[:extra] = @field.extra.first
    end
    if !@field.removed.empty?
      @items[:removed] = Removed_Pos + Card_Size 
      @cards[:removed] = @field.removed.last
    end
    if !@field.graveyard.empty?
      @items[:graveyard] = Graveyard_Pos + Card_Size
      @cards[:graveyard] = @field.graveyard.last
    end
    
    @field.field.each_with_index do |card, index|
      if card
        if (6..10).include?(index) and card.position != :attack
          @items[index] = [Field_Pos[index][0] + (Card_Size[0] - Card_Size[1])/2, Field_Pos[index][1] + (Card_Size[1] - Card_Size[0])/2, Card_Size[1], Card_Size[0]]
        else
          @items[index] = [Field_Pos[index][0], Field_Pos[index][1]] + Card_Size
        end
        @cards[index] = card
      end
    end
    
    hand_width = @field.hand.size * Hand_Pos[2] + (@field.hand.size-1) * Hand_Pos[3]
    hand_x = (@width - hand_width) / 2
    @field.hand.each_with_index do |card, index|
      @items[index+11] = [hand_x+index*Hand_Pos[2], Hand_Pos[1]]+ Card_Size
      @cards[index+11] = card
    end
    if !@player #对手的情况，把卡片位置翻转
      @items.each_pair do |key, value|
        if (6..10).include?(key) and @cards[key].position != :attack
          value[0] = @width - value[0] - Card_Size[1]
          value[1] = @height - value[1] - Card_Size[0]
        else
          value[0] = @width - value[0] - Card_Size[0]
          value[1] = @height - value[1] - Card_Size[1]
        end
        @items[key] = value
      end
    end
    clear
    @items.each_key{|index|draw_item(index, @index == index ? 1 : 0)}
    refresh_action_window
  end
  def draw_item(index, status=0)
    x,y = item_rect(index)
    if (6..10).include?(index) and @cards[index].position != :attack
      @contents.put(@cards[index].image_horizontal, x, y)
      @contents.put(@border_horizontal, x-1, y-1) if status == 1 
      x += (Card_Size[1]-Card_Size[0])/2
      y -= (Card_Size[1]-Card_Size[0])/2
    else
      @contents.put(@cards[index].image_small, x, y)
      @contents.put(@border, x-1, y-1) if status == 1
    end
    if (6..10).include?(index) and @cards[index].position != :set
      spacing = @font.text_size('/')[0]
      atkdef_x = x + (Card_Size[0] - spacing) / 2
      atkdef_y = y + Card_Size[1] - WLH
      draw_shaded_text('/' , atkdef_x, atkdef_y)
      draw_shaded_text(@cards[index].atk.to_s , atkdef_x - @font.text_size(@cards[index].atk.to_s)[0], atkdef_y)
      draw_shaded_text(@cards[index].def.to_s , atkdef_x + spacing, atkdef_y)
      #@font.draw_blended_utf8(@contents, '/' , atkdef_x, atkdef_y, 0xFF, 0xFF, 0xFF)
      #@font.draw_blended_utf8(@contents, @cards[index].atk.to_s , atkdef_x - @font.text_size(@cards[index].atk.to_s)[0], atkdef_y, 0xFF, 0xFF, 0xFF)
      #@font.draw_blended_utf8(@contents, @cards[index].def.to_s , atkdef_x + spacing, atkdef_y, 0xFF, 0xFF, 0xFF)
    end
    if @cards[index].note && !@cards[index].note.empty?
      note_x = x
      note_y = y + Card_Size[1] - WLH*3
      draw_shaded_text(@cards[index].note, note_x, note_y)
    end
    if @cards[index].counters != 0
      height ||= @font.text_size('/')[1] #不太规范，凑合能用
      counters_x = x
      counters_y = y + Card_Size[1] - height*2
      @@counter ||= Surface.load("graphics/field/counter.png")
      @contents.put @@counter, counters_x, counters_y
      draw_shaded_text(" × #{@cards[index].counters}", counters_x+16, counters_y)
    end
  end
  def draw_shaded_text(text,x,y,size=1,font=@font)
    @font.draw_blended_utf8(@contents, text, x+size, y+size, 0x00, 0x00, 0x00)
    @font.draw_blended_utf8(@contents, text, x, y, 0xFF, 0xFF, 0xFF)
  end
  def item_rect(index)
    @items[index]
  end
  def index=(index)
    index = nil if !@items.has_key?(index) or (index == :deck and @field.deck.empty?) or (index == :removed and @field.removed.empty?) or (index == :extra and @field.extra.empty?) or (index == :graveyard and @field.graveyard.empty?)
    return if index == @index
    if @index and @items.has_key?(@index) || (@index == :deck and !@field.deck.empty?) || (@index == :removed and !@field.removed.empty?) || (@index == :extra and !@field.extra.empty?) || (@index == :graveyard and !@field.graveyard.empty?)
      clear(@items[@index][0]-1,@items[@index][1]-1,@items[@index][2]+2, @items[@index][3]+2)
      draw_item(@index, 0) 
    end
    @index = index
    if @index
      draw_item(@index, 1)
      refresh_cardinfo_window
    end
    refresh_action_window
  end
  def refresh_cardinfo_window
    @card = case @index
    when :deck
      @field.deck.last
    when :extra
      @field.extra.first
    when :graveyard
      @field.graveyard.last
    when :removed
      @field.removed.last
    when 0..10
      @field.field[@index]
    when Integer #手卡
      @field.hand[@index-11]
    end
    $scene.cardinfo_window.card = @card unless @index == :deck
  end
  def refresh_action_window
    return unless @action_window
    return @action_window.visible = false unless @index and @items[@index]
    @action_window.items = case @index
    when :deck
      {"抽卡" => true,
        "查看卡组" => true,
        "卡组洗切" => true,
        "抽卡并确认" => false,
        "顶牌回卡组底" => false,
        "顶牌送入墓地" => true,
        "顶牌除外" => true,
        "顶牌背面除外" => false,
        "确认顶牌" => false,
        "双方确认顶牌" => false,
        "对方确认顶牌" => false
      }
    when :extra
      {"查看" => true,
        "特殊召唤" => !@field.empty_field(@card).nil?,
        "效果发动" => true,
        "从游戏中除外" => true,
        "送入墓地" => true
      }
    when :removed
      {"查看" => true,
        "特殊召唤" => @card.monster? && !@field.empty_field(@card).nil?,
        "效果发动" => true,
        "加入手卡" => true,
        "返回卡组" => true,
        "送入墓地" => true
      }
    when :graveyard
      {"查看" => true,
        "特殊召唤" => @card.monster? && !@field.empty_field(@card).nil?,
        "效果发动" => true,
        "加入手卡" => true,
        "返回卡组" => true,
        "从游戏中除外" => true
      }
    when 0..5
      {"效果发动" => true,
        "返回卡组" => true,
        "送入墓地" => true,
        "从游戏中除外" => true,
        "加入手卡" => true,
        "盖伏" => true
      }
    when 6..10
      {"攻击表示" => @card.position==:defense,
        "守备表示" => @card.position==:attack,
        "里侧表示" => @card.position!=:set,
        "反转召唤" => @card.position==:set,
        "打开" => @card.position==:set,
        "效果发动" => true,
        "攻击宣言" => @card.position==:attack,
        "转移控制权" => false,
        "放回卡组顶端" => true,
        "送入墓地" => true,
        "解放" => true,
        "加入手卡" => true,
        #"送入对手墓地" => false
      }
    when Integer #手卡
      {"召唤" => @card.monster? && !@field.empty_field(@card).nil?,
        "特殊召唤" => false,
        "发动" => @card.spell? && !@field.empty_field(@card).nil?,
        "放置到场上" => true && !@field.empty_field(@card).nil?,
        "放回卡组顶端" => true,
        "送入墓地" => true,
        "从游戏中除外" => true,
        "效果发动" => true
      }
    end
    @action_window.x = @x + @items[@index][0] - (@action_window.width - @items[@index][2])/2
    @action_window.y = @y + @items[@index][1] - @action_window.height
  end
  def mousemoved(x,y)
    self.index = @items.each do |index, item_rect|
      if x.between?(@x+item_rect[0], @x+item_rect[0]+item_rect[2]) and y.between?(@y+item_rect[1], @y+item_rect[1]+item_rect[3])
        break index
      end
    end
  end
  def cursor_up
    @action_window.cursor_up if @action_window
  end
  def cursor_down
    @action_window.cursor_down if @action_window
  end
  def cursor_left
    #self.index = @index ? (@index - 1) % [@items.size, @item_max].min : 0
  end
  def cursor_right
    #self.index = @index ? (@index + 1) % [@items.size, @item_max].min : 0
  end
  def lostfocus(active_window=nil)
    if active_window != @action_window
      self.index = nil
    end
  end
  def clicked
    return unless @action_window && @index
    action = case @index
    when :deck
      case @action_window.index
      when 0
        Action::Draw.new(true)
      when 1
        Widget_Msgbox.new("查看卡组", "功能未实现", :ok => "确定")
      when 2
        Action::Shuffle.new(true)
      when 3
        Widget_Msgbox.new("抽卡并确认", "功能未实现", :ok => "确定")
      when 4
        Widget_Msgbox.new("顶牌回卡组底", "功能未实现", :ok => "确定")
      when 5
        Action::SendToGraveyard.new(true, :deck, @card)
      when 6
        Action::Remove.new(true, :deck, @card)
      when 7
        Widget_Msgbox.new("顶牌背面除外", "功能未实现", :ok => "确定")
      when 8
        Widget_Msgbox.new("确认顶牌", "功能未实现", :ok => "确定")
      when 9
        Widget_Msgbox.new("双方确认顶牌", "功能未实现", :ok => "确定")
      when 10
        Widget_Msgbox.new("对方确认顶牌", "功能未实现", :ok => "确定")
      end
    when :extra
      case @action_window.index
      when 0
        Widget_Msgbox.new("查看", "功能未实现", :ok => "确定")
      when 1
        if pos = @field.empty_field(@card)
          Action::SpecialSummon.new(true, :extra, pos, @card, nil, :attack)
        else
          Widget_Msgbox.new("特殊召唤", "场位已满", :ok => "确定")
        end
      when 2
        Action::EffectActivate.new(true, :extra, @card)
      when 3
        Action::Remove.new(true, :extra, @card)
      when 4
        Action::SendToGraveyard.new(true, :extra, @card)
      end
    when :removed
      case @action_window.index
      when 0
        Widget_Msgbox.new("查看", "功能未实现", :ok => "确定")
      when 1 #特殊召唤
        if pos = @field.empty_field(@card)
          Action::SpecialSummon.new(true, :removed, pos, @card)
        else
          Widget_Msgbox.new("特殊召唤", "场位已满", :ok => "确定")
        end
      when 2 #效果发动
        Action::EffectActivate.new(true, :removed, @card)
      when 3 #加入手卡
        Action::ReturnToHand.new(true, :removed, @card)
      when 4
        Action::ReturnToDeck.new(true, :removed, @card)
      when 5
        Action::SendToGraveyard.new(true, :removed, @card)
      end
    when :graveyard
      case @action_window.index
      when 0
        Widget_Msgbox.new("查看", "功能未实现", :ok => "确定")
      when 1 #特殊召唤
        if pos = @field.empty_field(@card)
          Action::SpecialSummon.new(true, :graveyard, pos, @card)
        else
          Widget_Msgbox.new("特殊召唤", "场位已满", :ok => "确定")
        end
      when 2 #效果发动
        Action::EffectActivate.new(true, :graveyard, @card)
      when 3 #加入手卡
        Action::ReturnToHand.new(true, :graveyard, @card)
      when 4
        Action::ReturnToDeck.new(true, :graveyard, @card)
      when 5
        Action::Remove.new(true, :graveyard, @card)
      end
    when 0..5 #后场
      case @action_window.index
      when 0 #效果发动
        Action::EffectActivate.new(true, @index, @card)
      when 1 #返回卡组
        Action::ReturnToDeck.new(true, @index, @card)
      when 2 #送入墓地
        Action::SendToGraveyard.new(true, @index, @card)
      when 3 #从游戏中除外
        Action::Remove.new(true, @index, @card)
      when 4 #加入手卡
        Action::ReturnToHand.new(true, @index, @card)
      when 5 #盖伏
        Action::ChangePosition.new(true, @index, @card, :set)
      end
    when 6..10 #前场
      case @action_window.index
      when 0
        Action::ChangePosition.new(true, @index, @card, :attack)
      when 1
        Action::ChangePosition.new(true, @index, @card, :defense)
      when 2
        Action::ChangePosition.new(true, @index, @card, :set)
      when 3
        Action::FlipSummon.new(true, @index, @card)
      when 4
        Action::Flip.new(true, @index, @card)
      when 5
        Action::EffectActivate.new(true, @index, @card)
      when 6
        Widget_Msgbox.new("攻击宣言", "功能未实现", :ok => "确定")
      when 7
        Widget_Msgbox.new("转移控制权", "功能未实现", :ok => "确定")
      when 8
        Action::ReturnToDeck.new(true, @index, @card)
      when 9
        Action::SendToGraveyard.new(true, @index, @card)
      when 10
        Action::Tribute.new(true, @index, @card)
      when 11
        Action::ReturnToHand.new(true, @index, @card)
      end
    when Integer #手卡
      case @action_window.index
      when 0 #召唤
        if pos = @field.empty_field(@card)
          Action::Summon.new(true, :hand, pos, @card)
        else
          Widget_Msgbox.new("召唤", "场位已满", :ok => "确定")
        end
      when 1 #特殊召唤
        if pos = @field.empty_field(@card)
          Action::SpecialSummon.new(true, :hand, pos, @card, nil, :attack)
        else
          Widget_Msgbox.new("特殊召唤", "场位已满", :ok => "确定")
        end
      when 2 #发动
        if pos = @field.empty_field(@card)
          Action::Activate.new(true, :hand, pos, @card)
        else
          Widget_Msgbox.new("发动", "场位已满", :ok => "确定")
        end
      when 3 #放置
        if pos = @field.empty_field(@card)
          Action::Set.new(true, :hand, pos, @card)
        else
          Widget_Msgbox.new("放置", "场位已满", :ok => "确定")
        end
      when 4 #返回卡组
        Action::ReturnToDeck.new(true, :hand, @card)
      when 5 #送入墓地
        Action::SendToGraveyard.new(true, :hand, @card)
      when 6 #从游戏中除外
        Action::Remove.new(true, :hand, @card)
      when 7 #效果发动
        Action::EffectActivate.new(true, :hand, @card)
      end
    end
    $scene.action action if action.is_a? Action
    @index = nil
    refresh
    mousemoved(Mouse.state[0], Mouse.state[1])
  end
  def clear(x=0,y=0,width=@width,height=@height)
    super
    if $scene.fieldback_window and $scene.fieldback_window.visible?
      Surface.blit($scene.fieldback_window.contents, @x+x-$scene.fieldback_window.x, @y+y-$scene.fieldback_window.y, width, height, @contents, x, y)
    end
  end
end