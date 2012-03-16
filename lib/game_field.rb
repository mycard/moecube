#==============================================================================
# ■ Field
#------------------------------------------------------------------------------
# 　Field
#==============================================================================

#英汉对照表
# field 场地
# fieldcard 场地魔法卡
# spelltrap 魔法陷阱
# spell 魔法
# trap 陷阱
# graveyard 墓地
# deck 卡组
# extra 额外卡组
# removed 除外区
class Game_Field
  attr_accessor :lp
  attr_accessor :deck
  attr_accessor :extra
  attr_accessor :field
  attr_accessor :hand
  attr_accessor :graveyard
  attr_accessor :removed
  
	def initialize(deck = nil)
    @deck_original = deck || Deck.new(Array.new(60,Card.find(nil)), [], Array.new(15, Card.find(nil)))
    reset
  end
  def reset
		@lp = 8000
    @deck = @deck_original.main.collect{|card|Game_Card.new(card)}.shuffle
    @extra = @deck_original.extra.collect{|card|Game_Card.new(card)}
    @field = Array.new(11)
    @hand = []
    @graveyard = []
    @removed = []
	end
  
  
  def empty_monster_field
    [8,7,9,6,10].each do |pos|
      return pos if @field[pos].nil?
    end
    return
  end
  def empty_spelltrap_field
    [3,2,4,1,5].each do |pos|
      return pos if @field[pos].nil?
    end
    return
  end
  def empty_field(card)
    if card.monster?
      empty_monster_field
    elsif card.card_type == :场地魔法
      @field[0].nil? ? 0 : nil
    else
      empty_spelltrap_field
    end
  end
  #def shuffle_hand
  #  @hand.shuffle!
  #  @hand.each{|card|card.card = Card::Unknown if card.position == :set}
  #end
  #def shuffle_deck
  #  @deck.shuffle!
  #  @deck.each{|card|card.card = Card::Unknown if card.position == set}
  #end
end